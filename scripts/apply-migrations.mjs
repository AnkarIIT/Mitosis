#!/usr/bin/env node
/**
 * Applies supabase/*.sql to a project, in filename order, via the Supabase
 * Management API.
 *
 * ## Why a script
 * The migrations must run in order against a *clean* database. Getting that
 * wrong is not theoretical: `00_core_tables.sql` is documented "run this FIRST"
 * and creates triggers calling `public.set_updated_at()`, but that function
 * used to be defined only in `01_content_catalog.sql` — so every fresh database
 * failed outright. Running these by hand, in the wrong order, reproduces that.
 *
 * ## What you need
 * A Supabase **access token** (a personal access token), not the service-role
 * key:
 *
 *   Dashboard → Account Preferences → Personal Access Tokens → Generate
 *
 * Then:
 *
 *   node scripts/apply-migrations.mjs --project-ref <ref> --token <token>
 *
 * The project ref is the subdomain in your project URL, e.g.
 * `yobbzpzzjcewknyvexpg` from `https://yobbzpzzjcewknyvexpg.supabase.co`.
 *
 * ## Safety
 * * Refuses to run without `--yes` unless `--dry-run` is passed.
 * * Prints every statement it will run before applying.
 * * Applies each file as one transaction, so a failure rolls that file back.
 * * The SQL is written to be idempotent, but this DOES CREATE SCHEMA. Point it
 *   at staging first, never at production.
 */

import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..");
const SQL_DIR = join(ROOT, "supabase");

const API = "https://api.supabase.com";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const OFF = "\x1b[0m";

function arg(flag) {
  const hit = process.argv.find((a) => a.startsWith(`--${flag}=`));
  return hit ? hit.slice(flag.length + 3) : undefined;
}
const has = (flag) => process.argv.includes(`--${flag}`);

const projectRef = arg("project-ref");
const token = arg("token") ?? process.env.SUPABASE_ACCESS_TOKEN;
const dryRun = has("dry-run");
const confirmed = has("yes");

if (!projectRef || !token) {
  console.error(
    `${RED}Missing arguments.${OFF}\n\n` +
      `  node scripts/apply-migrations.mjs --project-ref <ref> --token <token>\n\n` +
      `Get a personal access token from:\n` +
      `  Dashboard → Account Preferences → Personal Access Tokens → Generate\n\n` +
      `${DIM}The service-role key will NOT work here — the Management API needs an\n` +
      `account-scoped token, and passing the service-role key to a script is the\n` +
      `exact mistake the app's own CI check forbids.${OFF}`,
  );
  process.exit(1);
}

const files = readdirSync(SQL_DIR)
  .filter((f) => f.endsWith(".sql"))
  .sort();

console.log(`${BOLD}Supabase migration runner${OFF}`);
console.log(`${DIM}project ${projectRef}${OFF}`);
console.log(`${DIM}${files.length} files, applied in filename order${OFF}\n`);

if (!dryRun && !confirmed) {
  console.error(
    `${RED}${BOLD}Refusing to modify a live database without confirmation.${OFF}\n\n` +
      `This will CREATE SCHEMA on project "${projectRef}".\n` +
      `  • Point it at staging, not production.\n` +
      `  • Re-run with --dry-run to print the SQL without applying it.\n` +
      `  • Re-run with --yes to actually apply.\n`,
  );
  process.exit(1);
}

/** Runs SQL through the Management API's query endpoint. */
async function runSql(sql) {
  const res = await fetch(`${API}/v1/projects/${projectRef}/database/query`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ query: sql }),
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}: ${text.slice(0, 600)}`);
  }
  return text;
}

let applied = 0;
let failed = 0;

for (const file of files) {
  const sql = readFileSync(join(SQL_DIR, file), "utf8");
  const statements = sql.split(";").filter((s) => s.trim().length > 0).length;

  process.stdout.write(`  ${file.padEnd(28)} ${DIM}${statements} statements${OFF} `);

  if (dryRun) {
    console.log(`${YELLOW}[dry-run]${OFF}`);
    continue;
  }

  try {
    await runSql(sql);
    console.log(`${GREEN}ok${OFF}`);
    applied++;
  } catch (error) {
    console.log(`${RED}FAILED${OFF}`);
    console.error(`\n${RED}${file}${OFF}\n${error.message}\n`);
    failed++;

    // A failure usually means the previous file is missing. Report where to
    // start rather than leaving them to bisect by hand.
    if (failed === 1) {
      console.error(
        `${YELLOW}If this is the first file, the project may already have a\n` +
          `partial schema. Inspect it before re-running:\n\n` +
          `  node scripts/verify-staging.mjs --url=https://${projectRef}.supabase.co --key=<anon key>\n`,
      );
    }
    break;
  }
}

console.log();
if (dryRun) {
  console.log(`${YELLOW}Dry run — nothing was applied.${OFF}`);
  console.log(
    `${DIM}Re-run with --yes against staging to apply, then verify with\n` +
      `scripts/verify-staging.mjs.${OFF}`,
  );
  process.exit(0);
}

if (failed) {
  console.error(
    `${RED}${BOLD}Migration run stopped.${OFF} ${applied} file(s) applied, ` +
      `${failed} failed. Files already applied are idempotent, so re-running\n` +
      `after fixing the cause is safe.`,
  );
  process.exit(1);
}

console.log(`${GREEN}${BOLD}All ${applied} migration files applied.${OFF}`);
console.log(
  `\nNext:\n` +
    `  1. node scripts/verify-staging.mjs --url=https://${projectRef}.supabase.co --key=<anon key>\n` +
    `  2. Run two authenticated users and confirm User A cannot read User B's rows.\n` +
    `${DIM}     RLS correctness cannot be proven from an anon key — "no rows visible"\n` +
    `     looks identical whether the policy is working or missing.${OFF}`,
);