# Task for worker

You are a delegated subagent running from a fork of the parent session. Treat the inherited conversation as reference-only context, not a live thread to continue. Do not continue or answer prior messages as if they are waiting for a reply. Your sole job is to execute the task below and return a focused result for that task using your tools.

Task:
Fix two-factor authentication (2FA) in the NEET Mitos Flutter app so it can be enabled from Settings and works with the new local email/password auth system.

Context:
- We recently removed Supabase/OAuth and replaced it with local auth in lib/core/services/auth_service.dart and lib/core/providers/auth_providers.dart
- 2FA was temporarily disabled: toggle2FA() just returns false
- The Users table already has isTwoFactorEnabled column
- EmailService exists and can send transactional emails via Resend or backend
- AuthStatus enum currently only has: initial, loading, authenticated, unauthenticated, error
- The auth flow currently: login -> success -> authenticated

Requirements:
1. Add 2FA to local auth flow:
   - When user enables 2FA in settings, send a verification email with OTP to confirm
   - When 2FA is enabled and user logs in with correct password, send OTP email and require verification before granting access
   - Use 6-digit numeric OTP codes
   - Store 2FA state in local database (already have isTwoFactorEnabled)

2. Update auth flow states:
   - Add AuthStatus.awaiting2FA back
   - After password login, if 2FA enabled -> transition to awaiting2FA -> send OTP -> verify OTP -> authenticated
   - If 2FA not enabled -> authenticated directly

3. Update settings:
   - Settings screen has a 2FA toggle that currently calls toggle2FA() which returns false
   - Make it work: when toggled on, require email verification first, then enable
   - When toggled off, disable immediately

4. Update screens:
   - Auth screen: after login, if 2FA required, navigate to OTP verification
   - Reuse existing OTP screen if possible, or add 2FA-specific flow
   - Settings: make toggle functional

5. Database changes needed:
   - Add columns to users table for 2FA: twoFactorCode, twoFactorExpiresAt
   - Update drift_database.dart with migration and queries
   - Update auth_service.dart with 2FA methods: enable2FA, verify2FACode, disable2FA

6. Keep it simple:
   - Don't use Supabase
   - Use local Drift database + EmailService
   - 15 minute OTP expiry
   - Rate limit OTP sends

Files to modify:
- lib/core/database/tables/users_table.dart
- lib/core/database/drift_database.dart
- lib/core/services/auth_service.dart
- lib/core/providers/auth_providers.dart
- lib/features/auth/auth_screen.dart
- lib/features/auth/otp_screen.dart (reuse or update)
- lib/features/settings/settings_screen.dart

Please implement the complete 2FA solution. After making changes, run flutter analyze and fix any issues.

---
**Output:**
Write your findings to exactly this path: C:/Users/ankar/neet_mitos/outputs/2fa-fix-summary.md
This path is authoritative for this run.
Ignore any other output filename or output path mentioned elsewhere, including output destinations in the base agent prompt, system prompt, or task instructions.

## Acceptance Contract
Acceptance level: checked
Completion is not accepted from prose alone. End with a structured acceptance report.

Criteria:
- criterion-1: Implement the requested change without widening scope
- criterion-2: Return evidence sufficient for an independent acceptance review

Required evidence: changed-files, tests-added, commands-run, residual-risks, no-staged-files

Review gate: required by reviewer.

Finish with a fenced JSON block tagged `acceptance-report` in this shape:
Use empty arrays when no items apply; array fields contain strings unless object entries are shown.
`criteriaSatisfied[].status` must be exactly one of: satisfied, not-satisfied, not-applicable.
`commandsRun[].result` must be exactly one of: passed, failed, not-run.
`manualNotes` and `notes` are optional strings; an empty string means no note and does not satisfy `manual-notes` evidence.
```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "specific proof"
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "specific proof"
    }
  ],
  "changedFiles": [
    "src/file.ts"
  ],
  "testsAddedOrUpdated": [
    "test/file.test.ts"
  ],
  "commandsRun": [
    {
      "command": "command",
      "result": "passed",
      "summary": "short result"
    }
  ],
  "validationOutput": [
    "validation output or concise summary"
  ],
  "residualRisks": [
    "none"
  ],
  "noStagedFiles": true,
  "diffSummary": "short description of the diff",
  "reviewFindings": [
    "blocker: file.ts:12 - issue found, or no blockers"
  ],
  "manualNotes": "anything else the parent should know"
}
```