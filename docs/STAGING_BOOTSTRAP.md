# Staging bootstrap

Everything needed to take this project from "no backend" to "verifiable staging".

The app's local code is in good shape (334 tests, 0 analyzer issues). The gap is
entirely on the Supabase and Google side, and it is not closable from this
repository — it needs account credentials that only you can issue.

## Current state

| Item | State | How it was determined |
|---|---|---|
| Supabase schema | **Not applied.** All 20 tables absent (`PGRST205`) | `scripts/verify-staging.mjs` against the live project |
| Google OAuth | **Not configured.** `oauth_client` array is empty | `scripts/verify-oauth-config.mjs` |
| Release signing | **No keystore.** Build now hard-fails rather than shipping debug-signed | `android/app/build.gradle.kts` |
| Cloud sync | Disabled by design | `AppConfig.enableCloudSync` defaults `false` |

The Supabase project ref is `yobbzpzzjcewknyvexpg`
(`https://yobbzpzzjcewknyvexpg.supabase.co`). The publishable/anon key is in
`.env`.

---

## Step 1 — Apply the migrations

You need a **personal access token**, not the service-role key:

1. Supabase Dashboard → your avatar → **Account Preferences**
2. **Personal Access Tokens** → **Generate new token**
3. Give it the `sql` scope (or read/write) and copy it

Then, from the project root:

```bash
# See what will run, touching nothing.
node scripts/apply-migrations.mjs \
  --project-ref yobbzpzzjcewknyvexpg --token <token> --dry-run

# Apply. --yes is required because this creates schema.
node scripts/apply-migrations.mjs \
  --project-ref yobbzpzzjcewknyvexpg --token <token> --yes
```

The files are applied in filename order. **That order matters** —
`node scripts/verify-migrations.mjs` enforces it in CI, because a forward
reference here fails on a clean database while passing on any database that
already has the schema.

### If you would rather use the SQL editor

Paste them one at a time, in this order, into Supabase → SQL Editor:

1. `supabase/00_core_tables.sql`
2. `supabase/01_content_catalog.sql`
3. `supabase/02_user_data_sync.sql`
4. `supabase/03_ai_proxy.sql`
5. `supabase/04_user_profiles.sql`
6. `supabase/05_learning_analytics.sql`

### If you would rather use psql

Dashboard → Project Settings → Database → Connection string, then:

```bash
for f in supabase/*.sql; do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
```

---

## Step 2 — Verify

```bash
node scripts/verify-staging.mjs
```

This is read-only and uses **only the anon key**, deliberately: the anon key is
public by design, and RLS is the thing protecting data. If this script can read
something it should not, RLS is broken.

Expected once Step 1 succeeds:

- 20/20 tables present
- `ai_response_cache` and `ai_usage_log` **not** readable by the anon key
- Google provider listed as enabled

### What this script cannot prove

A table that returns no rows is ambiguous. From an anon client, "RLS is working"
and "the policy is missing" look identical. To actually prove isolation you need
two real authenticated accounts:

```bash
# Sign in as User A and User B, minting access tokens from the Supabase CLI:
#   supabase login
#   node -e "..."   # or use the Dashboard → Authentication → Users → "JWT"
#
# Then, as User A:
curl "$SUPABASE_URL/rest/v1/bookmarks?select=*" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $USER_A_JWT"
```

The assertion that matters: **every response is empty** for rows belonging to
User B, and a write as User A affects only User A's rows. Repeat for every table
in `USER_OWNED` in `scripts/verify-staging.mjs`.

---

## Step 3 — Configure Google OAuth

Android sign-in is impossible right now: the native SDK resolves an OAuth client
from `google-services.json`, and that array is empty.

### Android OAuth client

Google Cloud Console → the project owning API key
`AIzaSyDuRVSyjaTRNeKPW53N4v465BG-HvFOU-g` → **APIs & Services** → **Credentials**
→ **Create credentials** → **OAuth client ID** → **Android**:

| Field | Value |
|---|---|
| Package name | `com.neetmitos.app` |
| SHA-1 | debug **and** release — see below |

Get the debug SHA-1:

```bash
keytool -list -v \
  -keystore "$USERPROFILE/.android/debug.keystore" \
  -alias androiddebugkey -storepass android -keypass android
```

The release SHA-1 comes from your upload keystore. **A release build is signed
with a different key, so the release SHA-1 is a separate registration.** Skipping
it produces error 12500 on release builds while debug works fine.

Then re-download `google-services.json` and replace
`android/app/google-services.json`.

### Web OAuth client

The native flow exchanges an ID token using a **web** client id:

1. Credentials → **OAuth client ID** → **Web application**
2. Add your redirect URIs: `https://<project-ref>.supabase.co/auth/v1/callback`,
   plus any `localhost` origin used for local web testing
3. Put the client id in `.env` as `GOOGLE_SERVER_CLIENT_ID`

An Android client id here makes the token exchange fail at runtime. The
validator flags a malformed value; it cannot detect a well-formed id of the
wrong type.

### Enable the provider

Supabase Dashboard → **Authentication** → **Providers** → **Google** → enable.
Set the client id and secret from the Web application credentials created above.

### Re-check

```bash
node scripts/verify-oauth-config.mjs
```

This must exit 0 before any device testing is meaningful.

---

## Step 4 — Release signing

The release build **fails on purpose** without `android/key.properties`:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (gitignored):

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

The previous behaviour was to fall back to the debug key. The debug keystore is
publicly known, so that produced a Play-Uploadable APK that anyone could
counter-sign — an update Android would accept as authentic. The build now throws
instead.

---

## Step 5 — Build with credentials

Config is injected at build time, never bundled. `.env` is no longer an asset.

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://yobbzpzzjcewknyvexpg.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable key> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>
```

---

## Enabling cloud sync

Do **not** turn this on yet. It is gated behind a build flag:

```bash
--dart-define=ENABLE_CLOUD_SYNC=true
```

The delta algorithm is covered by 23 integration tests against an in-memory
`CatalogSource` (pagination, cursor advance, per-row failure isolation,
soft-delete propagation, resume after failure, duplicate prevention), and two
real bugs were found and fixed that way. But none of it has run against a real
PostgREST instance with a real composite index. Enable it on staging, sync the
catalog, and confirm the stored questions have four options each — that is the
check that would have caught the original defect.

---

## Quick reference

| Command | Purpose | Expected exit |
|---|---|---|
| `verify-migrations.mjs` | static forward-reference check | 0 |
| `verify-oauth-config.mjs` | Android/Google config consistency | 0 before release |
| `verify-staging.mjs` | live schema + RLS reachability | 0 once applied |
| `apply-migrations.mjs --dry-run` | show what would run | 0 |
| `apply-migrations.mjs --yes` | apply | 0 on success |