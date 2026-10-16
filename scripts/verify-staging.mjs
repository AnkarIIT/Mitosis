#!/usr/bin/env node
/**
 * Supabase staging verification.
 *
 * Answers one question: **has the schema actually been applied, and is it
 * correct?** Everything this project claims about RLS, ownership isolation and
 * cloud sync is worthless if the migrations were never run.
 *
 * This script is intentionally read-only and uses only the **anon/publishable**
 * key. That is the correct posture: the anon key is public by design and RLS is
 * what protects data, so if this script can read something it shouldn't, RLS is
 * broken. It never uses the service-role key — that would bypass the very thing
 * being tested.
 *
 * Usage:
 *   node scripts/verify-staging.mjs
 *   node scripts/verify-staging.mjs --url=https://xxx.supabase.co --key=sb_publishable_...
 *   node scripts/verify-staging.mjs --expect-rls        # fail if any table is unprotected
 *
 * Exit codes: 0 = all required objects present, 1 = something is missing.
 */

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..");

// ── Config ───────────────────────────────────────────────────────────────────

function loadDotEnv() {
  const out = {};
  try {
    for (const line of readFileSync(join(ROOT, ".env"), "utf8").split("\n")) {
      const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)$/);
      if (m && m[2].trim()) out[m[1]] = m[2].trim();
    }
  } catch {
    /* no .env — fall back to flags/environment */
  }
  return out;
}

function arg(flag) {
  const hit = process.argv.find((a) => a.startsWith(`--${flag}=`));
  return hit ? hit.slice(flag.length + 3) : undefined;
}

const env = loadDotEnv();
const URL_ = arg("url") ?? process.env.SUPABASE_URL ?? env.SUPABASE_URL;
const KEY = arg("key") ?? process.env.SUPABASE_ANON_KEY ?? env.SUPABASE_ANON_KEY;
const EXPECT_RLS = process.argv.includes("--expect-rls");

// ── Expected schema ──────────────────────────────────────────────────────────
// Kept in lockstep with supabase/*.sql. If a table is added or renamed there, it
// must be added here too, or this script silently stops checking it.

/** Tables a signed-in user owns. RLS must isolate these per user. */
const USER_OWNED = [
  "profiles", "quiz_attempts", "topic_progress", "bookmarks", "error_book",
  "spaced_repetition", "flashcards", "daily_goals", "dpp_sets", "dpp_questions",
  "quiz_sessions", "evaluations", "chats",
  "mistake_events", "retention_reviews",
  // NOTE: resource_progress is deliberately absent. It exists only in the local
  // Drift schema (lib/core/database/tables/resource_progress_table.dart) and
  // was never created by any migration. Listing it here made this script
  // unrecoverable — it reported "schema not applied" even against a perfectly
  // migrated database, so it stopped being a useful signal. If resource
  // progress is ever synced to Postgres, add a migration FIRST, then add the
  // name here.
];

/** Public content. Readable by anon, writable only by staff. */
const PUBLIC_READ = ["questions", "tests"];

/** Support tables. Must be unreachable from the client. */
const SERVICE_ONLY = ["ai_response_cache", "ai_usage_log", "email_send_log"];

const REQUIRED = [...USER_OWNED, ...PUBLIC_READ, ...SERVICE_ONLY];

// ── HTTP helpers ─────────────────────────────────────────────────────────────

const headers = { apikey: KEY, Authorization: `Bearer ${KEY}` };

async function probe(table) {
  const url = `${URL_}/rest/v1/${table}?select=*&limit=1`;
  try {
    const res = await fetch(url, { headers });
    if (res.ok) {
      const body = await res.text();
      // A 200 does NOT mean the table is readable. With RLS enabled and no
      // policy — the correct configuration for service-only tables —
      // PostgREST answers 200 with an EMPTY array. Reporting that as "ok"
      // made the leak check below fire on correctly-secured tables.
      let rows = null;
      try {
        const parsed = JSON.parse(body);
        rows = Array.isArray(parsed) ? parsed.length : null;
      } catch {
        rows = null; // non-JSON body; treat as unreadable rather than leaking
      }
      if (rows === 0) {
        return { state: "empty", rows: 0, note: "exists, 0 rows visible" };
      }
      return { state: "ok", rows, note: `readable (${rows} row(s))` };
    }
    if (res.status === 404) {
      const body = await res.text();
      let code = "";
      try { code = JSON.parse(body).code ?? ""; } catch { /* ignore */ }
      if (code === "PGRST205") {
        return { state: "missing", rows: 0, note: "table does not exist" };
      }
      // The table exists but this role cannot see any rows: either RLS is
      // working (correct) or it is missing (indistinguishable from outside).
      return { state: "blocked", rows: 0, note: `exists, no rows visible (${res.status})` };
    }
    return { state: "error", rows: 0, note: `HTTP ${res.status}` };
  } catch (error) {
    return { state: "error", rows: 0, note: String(error.message ?? error) };
  }
}

/** Confirms the auth service is reachable and reports enabled providers. */
async function probeAuth() {
  try {
    const res = await fetch(`${URL_}/auth/v1/settings`, {
      headers: { apikey: KEY },
    });
    if (!res.ok) return { ok: false, note: `HTTP ${res.status}` };
    const body = await res.json();
    const providers = Object.keys(body?.external?.providers ?? {});
    return { ok: true, providers };
  } catch (error) {
    return { ok: false, note: String(error.message ?? error) };
  }
}

// ── Report ───────────────────────────────────────────────────────────────────

const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const OFF = "\x1b[0m";

function line(group, name, result) {
  const icon =
    result.state === "ok" ? `${GREEN}OK     ${OFF}`
    : result.state === "empty" ? `${GREEN}EMPTY  ${OFF}`
    : result.state === "blocked" ? `${GREEN}BLOCKED${OFF}`
    : result.state === "missing" ? `${RED}MISSING${OFF}`
    : `${RED}ERROR  ${OFF}`;
  console.log(`  ${icon}  ${group}/${name}  ${DIM}${result.note}${OFF}`);
}

async function main() {
  if (!URL_ || !KEY) {
    console.error(
      `${RED}Missing Supabase credentials.${OFF}\n` +
      `Set SUPABASE_URL and SUPABASE_ANON_KEY in .env, or pass --url / --key.`,
    );
    process.exit(1);
  }

  console.log(`${BOLD}Supabase staging verification${OFF}`);
  console.log(`${DIM}${URL_}${OFF}\n`);

  console.log(`${BOLD}Auth service${OFF}`);
  const auth = await probeAuth();
  if (auth.ok) {
    console.log(`  ${GREEN}OK     ${OFF}  auth reachable`);
    console.log(
      `  ${auth.providers.length ? GREEN : YELLOW}       ${OFF}  ` +
      `external providers: ${auth.providers.length ? auth.providers.join(", ") : "(none enabled — Google sign-in will fail)"}`,
    );
    if (!auth.providers.includes("google")) {
      console.log(
        `  ${YELLOW}NOTE${OFF}     Google provider is not enabled in this project.`,
      );
    }
  } else {
    console.log(`  ${RED}ERROR  ${OFF}  auth unreachable: ${auth.note}`);
  }
  console.log();

  const results = {};
  const groups = [
    ["user-owned", USER_OWNED],
    ["public", PUBLIC_READ],
    ["service-only", SERVICE_ONLY],
  ];

  let missing = 0;
  let serviceLeak = 0;

  for (const [group, tables] of groups) {
    console.log(`${BOLD}${group}${OFF} (${tables.length})`);
    for (const table of tables) {
      const result = await probe(table);
      results[table] = result;
      line(group, table, result);
      if (result.state === "missing" || result.state === "error") missing++;
      // A service-role-only table must never return DATA to the anon key.
      //
      // Only a 200 carrying at least one row proves reachability. "empty" and
      // "blocked" are both correct RLS behaviour and must not be flagged.
      if (group === "service-only" && result.state === "ok") {
        serviceLeak++;
      }
    }
    console.log();
  }

  // ── Verdict ────────────────────────────────────────────────────────────────

  const total = REQUIRED.length;
  console.log(`${BOLD}Summary${OFF}`);
  console.log(`  tables expected : ${total}`);
  console.log(`  missing         : ${missing}`);
  console.log(`  service-only reachable by anon key : ${serviceLeak}`);

  if (missing > 0) {
    console.log(
      `\n${RED}${BOLD}Schema is not applied.${OFF}\n` +
      `  ${missing} of ${total} required tables are absent.\n` +
      `  Apply the migrations in filename order:\n` +
      // `supabase db push` is wrong here: it applies supabase/migrations/*.sql
      // and needs a config.toml, neither of which exists in this repo.
      `    node scripts/apply-migrations.mjs\n` +
      `  or paste each file, in order, into the Supabase SQL editor:\n` +
      `    1. supabase/00_core_tables.sql\n` +
      `    2. supabase/01_content_catalog.sql\n` +
      `    3. supabase/02_user_data_sync.sql\n` +
      `    4. supabase/03_ai_proxy.sql\n` +
      `    5. supabase/04_user_profiles.sql\n` +
      `    6. supabase/05_learning_analytics.sql\n` +
      // email_send_log is created here — omitting it left this script
      // permanently reporting that table as missing.
      `    7. supabase/06_email_delivery.sql\n` +
      `  Then re-run this script.\n` +
      `${DIM}  Note: a "blocked" result cannot be distinguished from a missing RLS\n` +
      `  policy by an anon client — both look like "no rows". Confirm policy\n` +
      `  presence with a service-role connection or the SQL editor.${OFF}`,
    );
    process.exit(1);
  }

  if (serviceLeak > 0) {
    console.log(
      `\n${RED}${BOLD}Service-only tables are reachable with the anon key.${OFF}\n` +
      `  ai_response_cache / ai_usage_log must be service_role-only.`,
    );
    process.exit(1);
  }

  if (EXPECT_RLS) {
    const blocked = REQUIRED.filter(
      (t) => results[t]?.state === "blocked",
    ).length;
    if (blocked === REQUIRED.length) {
      console.log(
        `\n${YELLOW}Every table is unreadable to the anon key.${OFF}\n` +
        `  That is safe, but it also means public content reads will not work\n` +
        `  for signed-out users. Check the public read policies on\n` +
        `  ${PUBLIC_READ.join(", ")}.`,
      );
    }
  }

  console.log(`\n${GREEN}${BOLD}All required tables are present.${OFF}`);
  console.log(
    `${DIM}Still unverified: two-user RLS isolation, cascade on account deletion,\n` +
    `and OAuth on a real device. Those need authenticated sessions and\n` +
    `hardware, neither of which this read-only probe can establish.${OFF}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});