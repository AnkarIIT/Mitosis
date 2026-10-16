# NEET Mitos Public Release Roadmap

**Target:** staging-verified controlled beta and public-launch candidate within
eight weeks, subject to external OAuth, Supabase, Android signing, and
real-device verification.

**Execution model:** solo owner. Workstreams are parallel in design, but
implementation is sequenced by dependency and risk. A phase is complete only
when its exit gate passes.

## Release principles

- Keep development, staging, and production Supabase projects separate.
- Never commit secrets, service-role keys, signing keys, or real user data.
- Treat exam, DPP, quiz, authentication, and ownership correctness as launch
  blockers; defer cosmetic work when they compete with these.
- Use the physical Android device and desktop web browser as the minimum
  acceptance targets.
- Keep a tested rollback path before enabling production cloud features.

## Phase plan

### Week 1 — Environment, staging, and migration baseline

1. Install/configure the Android SDK, licenses, Java, and signing prerequisites.
2. Verify `flutter doctor`, Android debug/release builds, web release build,
   full tests, analyzer, formatting, and coverage.
3. Create and configure the staging Supabase project before security testing.
4. Apply and verify all SQL migrations and Edge Functions in staging.
5. Record schema version, row counts, RLS status, feature flags, and external
   dependencies.
6. Freeze the data migration design:
   - preserve remote question UUIDs;
   - introduce a local surrogate only through a compatible migration;
   - backfill and collision-check before switching reads/writes;
   - retain a reversible compatibility path;
   - never delete old identifiers until post-release verification.

**Exit gate:** staging is usable, builds are reproducible, and the migration
and rollback strategy is reviewed before destructive schema changes.

### Week 2A — Google OAuth and account switching

1. Create Android and web OAuth clients in Google Cloud.
2. Register debug/release SHA-1 certificates and Supabase redirect URLs.
3. Populate build-time configuration without committing secrets.
4. Test Google signup/login on Android and web.
5. Add explicit local/cloud account state and account-switch confirmation.
6. Invalidate user-scoped providers, caches, and onboarding state on every
   guest, logout, login, and account transition.

**Exit gate:** Google auth and account switching work on staging without
cross-account data visibility.

### Week 2B — Security, reset, 2FA, and deletion

1. Test local ownership isolation across all user-owned tables.
2. Verify password reset hashing, expiry, cooldown, attempts, replay
   prevention, and generic responses.
3. Verify 2FA hashing, expiry, resend limits, lockout, and one-time use.
4. Deploy and test account deletion with cloud cascade and local cleanup.
5. Run dependency, secret, logging, and input-validation audits.

**Exit gate:** no critical/high auth or ownership issue remains open.

### Week 3 — Security and isolation acceptance

1. Execute staging RLS tests for read, insert, update, and delete.
2. Test User A/User B, guest/authenticated, logout/login, and deletion flows.
3. Verify service-role access is limited to Edge Functions.
4. Add regression tests for every corrected ownership invariant.

**Exit gate:** unauthorized data access is rejected and deletion leaves no
residual session or cloud-owned data.

### Week 4A — Exam engine hardening

1. Persist immutable question, option-order, configuration, and seed
   snapshots.
2. Make checkpoint writes awaited, retryable, and observable.
3. Make expiry, resume, and submission idempotent.
4. Recalculate grading from the saved answer snapshot.
5. Test app kill/resume, background/foreground, timer expiry, duplicate
   lifecycle events, section transitions, and storage failure.

**Exit gate:** an interrupted exam resumes from the durable snapshot and can
never double-submit or lose answers.

### Week 4B — DPP and quiz hardening

1. Persist DPP per-question results and accurate subject/topic analytics.
2. Test quota allocation, weak-topic bias, difficulty, shortage, repeat
   exclusion, and deterministic generation.
3. Recalculate quiz results from persisted answers.
4. Test answer replacement, negative marking, timer submission, and all
   supported answer formats.

**Exit gate:** engine scores and analytics remain correct after reload and
   interruption.

### Week 4C — Sync reliability

1. Complete remote UUID/local surrogate migration.
2. Add tombstones/deletion handling.
3. Use transactional batches and preserve watermarks on failure.
4. Add failed-row diagnostics, retry behavior, and conflict tests.

**Exit gate:** interrupted or conflicting sync cannot overwrite or deactivate
valid content.

### Week 5 — Public web, SEO, accessibility, and performance

1. Add crawlable public landing pages for NEET, DPP, mocks, subjects, and
   previous-year papers.
2. Add unique metadata, canonical URLs, structured data, sitemap, and
   internal links.
3. Validate Lighthouse, narrow mobile layouts, keyboard navigation, contrast,
   and screen-reader labels.
4. Test offline startup, slow networks, deep links, and browser refresh.

**Exit gate:** public pages are indexable independently of authenticated app
routes and meet agreed accessibility/performance thresholds.

### Week 6 — Operations and rollback

1. Add crash reporting, structured diagnostics, and alert thresholds.
2. Configure backups and perform a restore drill.
3. Add CI gates for tests, coverage, secrets, dependencies, migrations,
   generated code, Android release, and web release.
4. Publish the rollback runbook below and rehearse it in staging.
5. Finalize privacy, terms, deletion, support, and data-retention pages.

**Exit gate:** a failed release can be detected, rolled back, and restored
without data loss.

### Week 7 — Must-pass real-device beta

Run the must-pass matrix before nice-to-have tests. Test fresh install,
upgrade, offline/online startup, local auth, Google auth, account switching,
full exam, DPP, quiz, app kill/resume, timer behavior, PDF flow, and deletion
on the physical Android device. Test OAuth, refresh/deep links, storage reset,
and slow network in a desktop browser.

**Exit gate:** no release-blocking defect remains in the must-pass matrix.

### Week 8 — Release candidate and controlled rollout

1. Freeze feature work.
2. Re-run all automated and staging acceptance gates.
3. Build and sign the Android artifact.
4. Deploy the web and production Edge Functions/migrations.
5. Release to a small beta cohort with monitoring and rollback ready.
6. Expand only after crash, auth, sync, exam, and deletion metrics remain
   within thresholds.

## Exam-engine must-pass matrix

| Scenario | Required result |
|---|---|
| Start with valid pool | Exact saved question/order snapshot |
| Insufficient pool | Visible warning; invalid paper cannot start |
| Answer replacement | Only final answer is graded |
| Negative marking | Correct, wrong, and blank marks match configuration |
| App killed during exam | Resume from durable checkpoint |
| Storage/checkpoint failure | Error and retry; no false success |
| Timer expiry | Exactly one submission |
| Repeated submit event | Idempotent result and attempt |
| Background/foreground | Timer remains consistent |
| Section transition | Correct allocation and saved position |
| Result reload | Same score and per-question result |
| User switch/logout | Previous exam data is not visible |

## Real-device prioritization

**Must pass:** install/upgrade, startup offline/online, local login, Google
login, logout/account switch, exam start/resume/submit, DPP generation,
quiz scoring, timer expiry, data isolation, account deletion, and crash-free
navigation.

**Nice to have:** notifications, PDF bulk download, AI generation, theme
variants, low-battery behavior, and secondary desktop browsers.

## Data migration strategy

Migrations must be additive first, then dual-read/dual-write if necessary,
followed by backfill validation and only then read-path cutover. Every
migration records pre/post row counts, duplicate counts, collision counts,
and schema version. A failed migration must leave the previous watermark and
previous usable identifier path intact. Destructive cleanup requires a
separate release after successful production observation.

## Rollback runbook

Trigger rollback for a critical auth/data-isolation issue, exam answer loss or
incorrect grading, widespread startup failure, deletion failure, or crash-rate
regression above the release threshold.

1. Pause rollout and record the incident timestamp and release version.
2. Disable the affected feature flag or Edge Function route where possible.
3. Revert the app distribution to the last known-good artifact.
4. Revert Edge Functions to the last known-good deployment.
5. Do not blindly reverse database migrations; restore from the verified
   backup or run the tested compatibility migration.
6. Preserve logs and affected identifiers for diagnosis without exposing
   secrets or user content.
7. Notify beta users with a safe status message and retry guidance.
8. Re-run smoke tests before resuming rollout.

The release owner decides rollback; no irreversible production change proceeds
without a backup and a documented recovery path.
