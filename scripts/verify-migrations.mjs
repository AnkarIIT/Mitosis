#!/usr/bin/env node
/**
 * Migration ordering validator.
 *
 * Catches the defect class where a migration references an object that a
 * *later* file creates. SQL files are applied in filename order, so this
 * compiles fine in review and on any database that already has the schema, then
 * fails on a genuinely fresh project.
 *
 * That is not hypothetical: `00_core_tables.sql` is documented as "run this
 * FIRST" and creates 11 triggers calling `public.set_updated_at()`, but that
 * function was only defined in `01_content_catalog.sql`. Every fresh database
 * failed outright.
 *
 * This is a static approximation, not a SQL engine: it resolves the common
 * cases (CREATE FUNCTION/POLICY/TRIGGER/INDEX/TABLE, and cross-file references)
 * by scanning in application order.
 *
 * Usage:
 *   node scripts/verify-migrations.mjs
 *
 * Exit codes: 0 = no forward references, 1 = at least one.
 */

import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..");
const SQL_DIR = join(ROOT, "supabase");

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const OFF = "\x1b[0m";

/** Strips comments and string literals so scans don't match documentation. */
function stripNoise(sql) {
  return sql
    .replace(/--[^\n]*/g, "")
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/'[^']*'/g, "''")
    .replace(/\$\$[\s\S]*?\$\$/g, "$$");
}

const files = readdirSync(SQL_DIR)
  .filter((f) => f.endsWith(".sql"))
  .sort(); // filename order == apply order

if (files.length === 0) {
  console.error(`${RED}No .sql files found in supabase/${OFF}`);
  process.exit(1);
}

console.log(`${BOLD}Migration order${OFF}`);
files.forEach((f, i) => console.log(`  ${DIM}${i + 1}. ${f}${OFF}`));
console.log();

/** Objects defined so far, by the kinds a later file could reference. */
const defined = {
  function: new Set(),
  table: new Set(),
  policy: new Set(),
  trigger: new Set(),
  index: new Set(),
};

const forwardRefs = [];

for (const file of files) {
  const raw = readFileSync(join(SQL_DIR, file), "utf8");
  const sql = stripNoise(raw);

  // ── Definitions ───────────────────────────────────────────────────────────
  for (const m of sql.matchAll(
    /CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?(\w+)/gi,
  )) {
    defined.function.add(m[1].toLowerCase());
  }
  for (const m of sql.matchAll(
    /CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?(\w+)/gi,
  )) {
    defined.table.add(m[1].toLowerCase());
  }
  for (const m of sql.matchAll(/CREATE\s+POLICY\s+"?([^"\s]+)"?/gi)) {
    defined.policy.add(m[1].toLowerCase());
  }
  for (const m of sql.matchAll(
    /CREATE\s+TRIGGER\s+(\w+)/gi,
  )) {
    defined.trigger.add(m[1].toLowerCase());
  }
  for (const m of sql.matchAll(
    /CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)/gi,
  )) {
    defined.index.add(m[1].toLowerCase());
  }

  // ── References that must already exist ────────────────────────────────────
  // Triggers must name a function that is defined by this point.
  for (const m of sql.matchAll(
    /CREATE\s+TRIGGER\s+(\w+)[\s\S]{0,200}?EXECUTE\s+(?:FUNCTION|PROCEDURE)\s+(?:public\.)?(\w+)/gi,
  )) {
    const fn = m[2].toLowerCase();
    if (!defined.function.has(fn)) {
      forwardRefs.push({
        file,
        kind: "function",
        name: fn,
        via: `trigger ${m[1]}`,
      });
    }
  }

  // Policies must name a table that exists by this point.
  for (const m of sql.matchAll(
    /CREATE\s+POLICY\s+"?([^"\s]+)"?\s+ON\s+(?:public\.)?(\w+)/gi,
  )) {
    const table = m[2].toLowerCase();
    if (!defined.table.has(table)) {
      forwardRefs.push({
        file,
        kind: "table",
        name: table,
        via: `policy "${m[1]}"`,
      });
    }
  }

  // Index creation must name an existing table.
  for (const m of sql.matchAll(
    /CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)\s+ON\s+(?:public\.)?(\w+)/gi,
  )) {
    const table = m[2].toLowerCase();
    if (!defined.table.has(table)) {
      forwardRefs.push({
        file,
        kind: "table",
        name: table,
        via: `index ${m[1]}`,
      });
    }
  }

  // ALTER TABLE ... ENABLE ROW LEVEL SECURITY must name an existing table.
  for (const m of sql.matchAll(
    /ALTER\s+TABLE\s+(?:IF\s+EXISTS\s+)?(?:public\.)?(\w+)/gi,
  )) {
    const table = m[1].toLowerCase();
    // Only flag when the table is created nowhere in the whole migration set,
    // so a legitimately pre-existing Supabase table does not trip the check.
    if (!defined.table.has(table)) {
      const createdSomewhere = files.some((f) =>
        new RegExp(
          `CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?(?:public\\.)?${table}\\b`,
          "i",
        ).test(stripNoise(readFileSync(join(SQL_DIR, f), "utf8"))),
      );
      if (!createdSomewhere) {
        forwardRefs.push({
          file,
          kind: "table",
          name: table,
          via: "ALTER TABLE",
        });
      }
    }
  }
}

// ── Report ───────────────────────────────────────────────────────────────────

console.log(`${BOLD}Objects defined by the end of the set${OFF}`);
console.log(`  functions : ${[...defined.function].sort().join(", ") || "(none)"}`);
console.log(`  tables    : ${defined.table.size}`);
console.log();

if (forwardRefs.length) {
  console.error(
    `${RED}${BOLD}Forward references found${OFF}\n` +
      `${RED}These objects are used before any earlier migration creates them, so ` +
      `applying the files in order against an empty database fails.${OFF}\n`,
  );
  for (const ref of forwardRefs) {
    console.error(`  ${RED}${ref.file}${OFF}`);
    console.error(`    ${ref.via} needs ${ref.kind} "${ref.name}", defined later or never`);
  }
  console.error(
    `\n${DIM}Move the definition earlier in the filename sequence, or inline it.${OFF}`,
  );
  process.exit(1);
}

console.log(`${GREEN}${BOLD}No forward references.${OFF}`);
console.log(
  `${DIM}Migration order is internally consistent. This is a static check — it\n` +
    `does not execute SQL, so it cannot catch type errors, constraint conflicts\n` +
    `or a policy that references a missing column. Verify by applying to a\n` +
    `throwaway project, then run scripts/verify-staging.mjs against it.${OFF}`,
);