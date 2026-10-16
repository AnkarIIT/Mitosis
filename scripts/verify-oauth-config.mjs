#!/usr/bin/env node
/**
 * Android / Google OAuth configuration validator.
 *
 * NEET Mitos uses google_sign_in with a Web serverClientId, then exchanges the
 * Google ID token through Supabase. Firebase's google-services.json is only
 * relevant if the Firebase SDK or Google Services Gradle plugin is enabled.
 *
 * Usage:
 *   node scripts/verify-oauth-config.mjs
 *   GOOGLE_SERVER_CLIENT_ID=<web-client-id> node scripts/verify-oauth-config.mjs
 *
 * Exit codes: 0 = consistent (live provider credentials and release SHA still
 * need device/console verification), 1 = a local configuration defect.
 */

import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const ROOT = process.cwd();
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const OFF = "\x1b[0m";

const problems = [];
const warnings = [];

function fail(message) { problems.push(message); }
function warn(message) { warnings.push(message); }
function ok(message) { console.log(`  ${GREEN}OK     ${OFF}  ${message}`); }
function bad(message) { console.log(`  ${RED}FAIL   ${OFF}  ${message}`); }
function note(message) { console.log(`  ${YELLOW}WARN   ${OFF}  ${message}`); }
function readJson(path, label) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    fail(`${label} is not valid JSON: ${error.message}`);
    return null;
  }
}

// ── 1. Android application identity ──────────────────────────────────────────

console.log(`${BOLD}Android identifiers${OFF}`);
const gradlePath = join(ROOT, "android/app/build.gradle.kts");
const gradle = readFileSync(gradlePath, "utf8");
const applicationId = gradle.match(/applicationId\s*=\s*"([^"]+)"/)?.[1];
const namespace = gradle.match(/namespace\s*=\s*"([^"]+)"/)?.[1];

if (!applicationId) {
  fail("could not read applicationId from android/app/build.gradle.kts");
} else {
  ok(`applicationId = ${applicationId}`);
}

if (namespace && applicationId && namespace !== applicationId) {
  fail(`namespace (${namespace}) differs from applicationId (${applicationId})`);
} else if (namespace) {
  ok("namespace matches applicationId");
}

// ── 2. Firebase config relevance ─────────────────────────────────────────────

console.log(`\n${BOLD}Firebase config relevance${OFF}`);
const pubspec = readFileSync(join(ROOT, "pubspec.yaml"), "utf8");
const mainDart = readFileSync(join(ROOT, "lib/main.dart"), "utf8");
const usesGoogleServicesPlugin = /id\s*\(\s*["']com\.google\.gms\.google-services["']\s*\)/.test(gradle);
const usesFirebasePackage = /^\s*firebase_(?:core|auth|messaging|analytics|crashlytics)\s*:/m.test(pubspec);
const initializesFirebase = /\bFirebase\.initializeApp\s*\(/.test(mainDart);
const usesFirebase = usesGoogleServicesPlugin || usesFirebasePackage || initializesFirebase;
const gservicesPath = join(ROOT, "android/app/google-services.json");

if (!usesFirebase) {
  ok("Firebase SDK/Google Services plugin is not active; google-services.json is not part of this Supabase sign-in flow");
} else if (!existsSync(gservicesPath)) {
  fail("Firebase integration is active, but android/app/google-services.json is absent");
} else {
  const gservices = readJson(gservicesPath, "android/app/google-services.json");
  if (gservices) {
    const clients = gservices.client ?? [];
    if (clients.length === 0) {
      fail("google-services.json contains no Android client entries");
    }
    for (const client of clients) {
      const pkg = client.client_info?.android_client_info?.package_name;
      if (applicationId && pkg !== applicationId) {
        fail(`google-services.json package_name is "${pkg}" but the app builds as "${applicationId}"`);
      } else if (pkg) {
        ok(`Firebase package_name matches (${pkg})`);
      }
    }
  }
}

// ── 3. Local Dart defines and Google Web client ID ────────────────────────────

console.log(`\n${BOLD}Build-time auth config${OFF}`);
const definesPath = join(ROOT, ".dart-defines.local.json");
let localDefines = {};
if (existsSync(definesPath)) {
  localDefines = readJson(definesPath, ".dart-defines.local.json") ?? {};
  if (localDefines && typeof localDefines === "object" && !Array.isArray(localDefines)) {
    const required = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "GOOGLE_SERVER_CLIENT_ID"];
    const missing = required.filter((key) => typeof localDefines[key] !== "string" || !localDefines[key].trim());
    if (missing.length) {
      fail(`.dart-defines.local.json is missing required values: ${missing.join(", ")}`);
    } else {
      ok("local Dart-defines file has the required auth values (values suppressed)");
    }
  } else {
    fail(".dart-defines.local.json must contain a JSON object");
  }
} else {
  warn(".dart-defines.local.json is absent; supply the three public auth values with --dart-define at build time");
}

const serverClientId =
  process.env.GOOGLE_SERVER_CLIENT_ID?.trim() ||
  (typeof localDefines.GOOGLE_SERVER_CLIENT_ID === "string"
    ? localDefines.GOOGLE_SERVER_CLIENT_ID.trim()
    : "");

if (!serverClientId) {
  warn("No GOOGLE_SERVER_CLIENT_ID was supplied. Android Google Sign-In needs the public Web client ID as serverClientId.");
} else if (/^\d+-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$/.test(serverClientId)) {
  ok("GOOGLE_SERVER_CLIENT_ID has Google OAuth client-ID format (value suppressed)");
} else {
  fail("GOOGLE_SERVER_CLIENT_ID does not look like a Google OAuth client ID; use the Web client, not an empty value");
}

const appConfigPath = join(ROOT, "lib/core/config/app_config.dart");
const appConfig = readFileSync(appConfigPath, "utf8");
if (/String\.fromEnvironment\(\s*['"]SUPABASE_URL['"]/.test(appConfig) &&
    /String\.fromEnvironment\(\s*['"]SUPABASE_ANON_KEY['"]/.test(appConfig) &&
    /String\.fromEnvironment\(\s*['"]GOOGLE_SERVER_CLIENT_ID['"]/.test(appConfig)) {
  ok("AppConfig reads the Supabase URL, publishable/anon key, and Google Web ID from Dart defines");
} else {
  fail("AppConfig is missing one or more required String.fromEnvironment keys");
}

const googleService = readFileSync(join(ROOT, "lib/core/services/google_auth_service.dart"), "utf8");
if (/GoogleSignIn\s*\(\s*serverClientId:\s*AppConfig\.googleServerClientId\s*\)/s.test(googleService) &&
    /signInWithIdToken\s*\(/.test(googleService)) {
  ok("GoogleSignIn receives the Web serverClientId and exchanges an ID token with Supabase");
} else {
  fail("Google sign-in is not wired to AppConfig.googleServerClientId and Supabase ID-token auth");
}

// ── 4. Safety gates ──────────────────────────────────────────────────────────

console.log(`\n${BOLD}Build safety${OFF}`);
const flutterBlock = pubspec.slice(pubspec.indexOf("\nflutter:"));
if (/^\s*-\s*\.env\s*$/m.test(flutterBlock)) {
  fail(".env is bundled as a Flutter asset; remove it and use build-time defines");
} else {
  ok(".env is not bundled as a Flutter asset");
}

for (const gate of ["ENABLE_CLOUD_SYNC", "ENABLE_AI_PROXY"]) {
  if (new RegExp(`'${gate}',\\s*defaultValue:\\s*false`).test(appConfig)) {
    ok(`${gate} defaults to false`);
  } else {
    fail(`${gate} must default to false until its backend is verified`);
  }
}

// ── Verdict ───────────────────────────────────────────────────────────────────

console.log(`\n${BOLD}Summary${OFF}`);
console.log(`  ${RED}${problems.length} blocking problem(s)${OFF}`);
console.log(`  ${YELLOW}${warnings.length} warning(s)${OFF}`);

if (problems.length) {
  console.log(`\n${RED}${BOLD}Local OAuth config needs fixes:${OFF}`);
  for (const problem of problems) console.log(`  - ${problem}`);
  process.exit(1);
}

if (warnings.length) {
  console.log(`\n${YELLOW}Warnings:${OFF}`);
  for (const warning of warnings) console.log(`  - ${warning}`);
}

console.log(`\n${GREEN}${BOLD}Local OAuth configuration is internally consistent.${OFF}`);
console.log(
  `${DIM}Still requires a real-device check and the correct release/Play App Signing SHA-1 in Google Cloud.${OFF}`,
);
