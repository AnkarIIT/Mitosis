# NEET Mitosis: exam algorithm and NTA-parity review

**Date:** 11 October 2026  
**Scope:** Static review of current repository code and official NTA public sources. No code or exam configuration was changed; Flutter tests were not run because Flutter/Dart are unavailable in this environment.

## The key correction: NEET-UG is not an NTA CBT

NTA's own NEET-UG 2026 public notices refer to scanned **OMR answer sheets and recorded responses**. That is a paper-and-OMR exam workflow, not a computer question-palette CBT.[1][2] NTA separately publishes a generic CBT familiarisation guide and practice site for computer-based exams; the practice site explicitly says its mock is for familiarisation and practice.[4][5]

So an app cannot truthfully claim “exact NTA NEET CBT”. The closest honest product is two labelled modes: **NEET OMR-pattern full mock** to simulate the actual NEET answer method and current bulletin, plus a separate **CBT familiarisation/practice mode** using generic NTA-style controls. Official NTA’s 2025 clarification states 180 compulsory questions in 180 minutes; verify the current season’s bulletin before freezing any year-specific pattern.[3]

## What the current exam code does

`ExamConfig.neet()` currently creates 180 compulsory slots, split internally into Physics 45, Chemistry 45, Botany 45 and Zoology 45, with 180 minutes and +4/−1 scoring. Its default is **free navigation, no section lock and no breaks** (`lib/core/services/exam_engine_service.dart:115–188`). This configuration resembles the 2025 NEET question-count/time/marking pattern, but the four internal buckets are not four timed exam sections.

The allocation algorithm filters previously seen IDs, shuffles with a seed, then fills each configured subject quota without repeating an ID. If every question was excluded as recently seen, it falls back to the complete pool. Pool validation checks basic gradability (question text, at least two non-empty options and an answer matching an option); it does not establish syllabus coverage, source rights, difficulty balance, or semantic duplicate quality. Scoring itself normalizes the selected answer and implements correct/wrong/unanswered marks. The code also retains a Section-B optional-question configuration; do not use that historic variant as the current NEET default unless a future official bulletin brings it back.

## Parity gaps that matter

- **Wrong instructions for the default:** `cbt_instructions_screen.dart:320–325` claims fixed section timers, no return after expiry, a five-minute section warning, and mandatory section submission. The default has `sectionLock: false`; `cbt_test_screen.dart:422–430` therefore disables section deadlines. In the default full mock, the timer is overall, not per-section. The instructions page must be generated from actual settings.
- **Answer review can contradict scoring:** `cbt_result_screen.dart:475–484` uses raw string equality for correct/incorrect; option highlighting at `:559–563` compares selected answers to A/B/C labels and the key to an index string. The grading engine accepts normalized formats. Result review must use the saved `QuestionResult`/shared normalizer.
- **Submission can lose recovery state:** `cbt_test_screen.dart:738–765` clears the checkpoint even after all three attempt-save retries fail. The exit confirmation at `:817–840` also clears a full-mock checkpoint when a student chooses Exit. Keep a pending result/checkpoint until durable storage succeeds, or clearly distinguish “discard attempt” from a recoverable pause.
- **Desktop is not locked down:** `SecureScreenService` only calls an Android native secure-window flag and silently no-ops when there is no native handler (`lib/core/services/secure_screen_service.dart:3–22`). `SystemChrome` immersive UI/orientation code in `cbt_test_screen.dart:120–125,269–280` is not a desktop kiosk/window lock. No desktop window-manager, focus-loss/fullscreen-exit listener or exam keyboard-shortcut policy was found. Current violation tracking only uses Flutter lifecycle callbacks (`:283–329`), not a platform-secured exam client.
- **A personal laptop cannot be made NTA-secure by an in-app fullscreen switch:** a fullscreen practice window is deterrence/telemetry, not a guarantee against OS-level task switching, screen capture, browser tools, another device or a user with OS privileges. Genuine kiosk enforcement needs managed devices/OS policy and controlled deployment. The app should call its desktop mode “strict practice” or “honour mode”, not proctored/secure.
- **Fresh-install availability is a risk:** the full mock requires all configured quotas. Bundled seeds are starter data, not evidence of a complete, balanced NEET bank. Gate the full-paper CTA on an actual validated subject-wise inventory and show shortages before the student begins.

The interface does contain CBT-like building blocks—answer selection, Clear, Save & Next, Mark & Next, question palette and overall timer. That makes it useful as a computer-based practice screen, but it does not make it an exact simulation of the actual NEET OMR exam, and its current instructions/review/desktop protections are not at parity.

## Recommended build order

1. **Choose two explicit products:** (a) NEET OMR-pattern mock, with answer-sheet simulation and current official pattern; (b) optional NTA-style CBT familiarisation mode, clearly not represented as the NEET exam. Keep all pattern values versioned by exam year and cite the official bulletin.
2. **Fix correctness and durability before strictness:** derive review from the same graded result; align instructions with config; retain checkpoint/pending results through save failure and recoverable exit; test all of these with widget/integration tests.
3. **Add desktop strict-practice controls only with honest limits:** request fullscreen on desktop, warn/count focus loss or leaving fullscreen where supported, block in-app navigation and disallow exam-time links/tools, autosave at each answer and persist violation records. Offer accommodation and practice settings deliberately. Do not promise OS-level lockdown; use a managed kiosk only for supervised institutional testing.
4. **Ship a real, offline chapter module as a separate content project:** start with one pilot chapter. Include learning goals, original bite-size explanations, worked examples, original/permission-cleared diagrams, misconception checks, reviewed MCQs with answer reasoning, error review, and exact NCERT edition/section/page links to the bundled PDF. Save lesson and attempt progress locally. Do not republish complete NCERT prose/images without confirmed rights. Hide or mark “Coming soon” any PYQ/formula/diagram card that does not open distinct complete content.
5. **Quality gates:** subject-expert/content-editor review; answer-key and citation QA; offline fresh-install test; exact exam-year pattern test; unique-ID/quota checks; answer-review normalization tests; timer/expiry/save-failure/resume tests; desktop fullscreen/focus-loss behavior tests; and a real-device/browser acceptance run.

**No test suite was executed for this note.** Static source evidence is useful for prioritisation, but it is not runtime or release certification.

## Official sources

[1]: https://neet.nta.nic.in/display-of-scanned-images-of-omr-answer-sheet-and-recorded-response/ "NEET-UG 2026: Display of Scanned Images of OMR Answer Sheet and Recorded Response"
[2]: https://neet.nta.nic.in/public-notices/ "Official NEET-UG public notices, including 2026 OMR notices"
[3]: https://www.nta.ac.in/Download/Notice/Notice_20250125132355.pdf "NTA clarification on NEET-UG 2025 paper pattern and examination duration"
[4]: https://www.nta.ac.in/Download/AboutCBT.pdf "NTA Computer Based Test (CBT) familiarisation guide"
[5]: https://www.nta.ac.in/quiz "NTA Test Practice Centre CBT familiarisation mock"
