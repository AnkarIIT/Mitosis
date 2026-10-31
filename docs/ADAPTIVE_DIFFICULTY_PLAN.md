# Adaptive Difficulty — Design Plan

**Date:** 2026-10-31 · **Status:** plan only, no code changed yet
**Goal:** a practice mode where a correct answer makes the next question harder and a
wrong answer makes it easier — the behaviour you described — without breaking the
fixed-paper mock.

---

## 0. Scope boundary (read this first)

There are two different products here, and mixing them would be dishonest:

| Mode | Paper | Behaviour |
|---|---|---|
| **Mock / full test** (existing, `/cbt`) | Fixed, allocated once by `ExamEngineService.allocateQuestions` | Must **never** adapt. A real NTA paper does not change because you answered the last question. If we adapt the mock, the score stops meaning anything. |
| **Adaptive practice** (new) | Built question-by-question from what you just did | This is what adapts. Separate route, separate `testType`, separate stats. |

So: adaptive lives in a **new mode**, and mock scores stay comparable.

---

## 1. Why questions feel basic — measured, not guessed

| Source | Easy | Medium | Hard | Total |
|---|---|---|---|---|
| `neet_sample_data.dart` | 12 | 13 | 1 | 26 |
| `neet_sample_data_phase2.dart` | 31 | 18 | 2 | 51 |
| `assets/questions/neet_sample_10.json` | 5 | 5 | 0 | 10 |
| **Gradable total** | **48** | **36** | **3** | **87** |

Three findings:

1. **The whole bank holds 3 Hard questions.** 87% of what a student can be asked is
   Easy or Medium. That is why every test feels basic — it is not a sampling bug,
   it is the content.
2. **`ExamEngineService.allocateQuestions` (line 509) ignores difficulty entirely.**
   It shuffles the pool and takes the first N per section. The 40/40/20
   `QuestionPaperGenerator` is a different path and cannot help when the Hard
   bucket has 3 items.
3. **`QuestionRequest.recentAccuracy` (line 564) is declared with the comment
   "For adaptive difficulty" and never read.** The hook exists; the behaviour
   does not.

### About `assets/questions/pyq_official.json`

It looks like the answer to the volume problem — 817 questions, 2015–2022,
subjects Bot 230 / Phy 219 / Chem 206 / Zoo 162, all with 4 options. It is **not
usable yet**:

- `correctAnswer` is `null` for **all 817**;
- `answer_keys` is the literal string
  `"PENDING - correctAnswer is null; auto-grading disabled until an official key source is added"`;
- options are pypdf layout extractions, so maths is corrupted
  (`5√2 h` arrived as `"5 2 h"`, `βx⁻²ⁿ` as `"βx-2n"`);
- nothing in `lib/` or `test/` references the file, so it is not seeded.

Grading on it today would be guessing. It needs an answer key + a math-repair pass
before it counts as content.

---

## 2. The rule you asked for (v0 — ship this first)

Strict step rule, exactly as described: **correct → one band harder, wrong → one
band easier.** Three bands map to the existing `difficulty` strings.

```dart
enum Band { easy, medium, hard }

Band nextBand(Band current, bool correct) => switch ((current, correct)) {
  (Band.easy,   true)  => Band.medium,
  (Band.medium, true)  => Band.hard,
  (Band.hard,   true)  => Band.hard,   // clamp
  (Band.easy,   false) => Band.easy,   // clamp
  (Band.medium, false) => Band.easy,
  (Band.hard,   false) => Band.medium,
};
```

Selection for each slot:

```dart
Question? pick(Band band, Set<String> usedIds) {
  final exact = pool.where((q) => q.band == band && !usedIds.contains(q.id));
  if (exact.isNotEmpty) return _random(exact);
  // Never fail silently and never jump two bands: take the nearest band and
  // record that the request was clamped, so the result screen can say so.
  for (final neighbour in _neighboursOf(band)) {
    final alt = pool.where((q) => q.band == neighbour && !usedIds.contains(q.id));
    if (alt.isNotEmpty) { clampedCount++; return _random(alt); }
  }
  return null; // pool exhausted
}
```

Why v0 instead of immediately building IRT: it is explainable to a student
("you got 3 right, the paper got harder"), testable in an afternoon, and it is
literally the behaviour that was asked for. If the data ever supports it, v1
below upgrades the same UI without changing the screen.

---

## 3. v1 — ability model (only after there is data)

One-parameter logistic (Rasch). Same three-band UI, finer targeting.

```
P(correct | θ, b) = 1 / (1 + exp(-(θ - b)))
target difficulty  b* = θ - ln(1/0.7 - 1) ≈ θ - 0.847     // aim ~70% success
after each answer  θ ← θ + K · (score - P),  K = 0.4 early, 0.2 after 30 items
```

- Initial `b`: Easy = −1.0, Medium = 0.0, Hard = +1.0.
- Recalibrate items from real attempts:
  `b_i = ln((1 − p_i)/p_i)` with `p_i = correct/attempts`, shrunk toward the
  prior with `n₀ = 10` pseudo-attempts.
- Item parameters are only "real" after ~200 attempts; until then the band
  labels drive selection and the model is just a smoothing layer.

v1 is worth it only once the bank has ≥ 200 questions **with answer keys** and
≥ 30 per subject per band. Today: 3 Hard in total.

---

## 4. Session design

| Decision | Choice | Reason |
|---|---|---|
| Length | 10 / 20 / 30 questions | Fixed length keeps the score comparable between two attempts. Do **not** stop when ability converges. |
| Blueprint | NEET weights: Physics 25%, Chemistry 25%, Botany 25%, Zoology 25% | Prevents "hard mode = Physics only". |
| Difficulty state | **one ability/band per subject** | A student can be strong in Bio and weak in Physics; a single global band makes Physics impossible and Bio boring. |
| Repeats | no repeat inside a session | Obvious. |
| Cooldown | reuse `UnifiedQuestionPoolService.applyCooldown` | Already implemented. |
| Topic cap | max 2 questions from the same `topicId` per 10 | Stops a hard streak from drilling one chapter. |
| Timer | off by default, optional | Difficulty and speed are separate skills. |
| Marking | +4/−1 optional, default +4/0 | Negative marking punishes exploration in a mode that is supposed to stretch you. |
| Feedback | mode + band shown **after** the answer, never before | Showing "HARD" before answering biases the attempt. |

---

## 5. Where it plugs into the existing code

| Layer | File | Change |
|---|---|---|
| Selector | **new** `lib/core/services/adaptive_engine_service.dart` | Pure Dart: `nextBand`, `pick`, `AdaptiveSession` state. No Flutter imports → unit-testable like `exam_engine_service.dart`. |
| Request hook | `lib/core/services/unified_question_pool_service.dart:564` | `recentAccuracy` becomes a real input, or is deleted. Right now it is a lie in the API. |
| Config | `lib/core/services/exam_engine_service.dart` | New `ExamMode.adaptive`; adaptive sessions get a fixed-length `ExamConfig` so the existing timer/checkpoint machinery still works. |
| Screen | **new** `lib/features/exam_engine/adaptive_test_screen.dart` | Reuse the NTA chrome and palette from `cbt_test_screen.dart`; the only difference is that the next question is chosen after each submit. |
| Persistence | `lib/core/database/drift_database.dart` | New table `item_stats(questionId, attempts, correct, b)`; `quiz_attempts` gains `ability_before`, `ability_after`, `mode`. Migration step, same pattern as the existing 40. |
| Entry point | `lib/features/practice/...` hub | "Adaptive Practice" card, only visible when the pool qualifies (see §6). |
| Result | `cbt_result_screen.dart` or a sibling | Band trajectory (Easy→Medium→Hard), topic breakdown, **no percentile** — an adaptive score is not comparable to a fixed paper, and saying otherwise would be the same dishonesty as the old fake PYQ screen. |

---

## 6. Honesty guardrails (non-negotiable)

1. **Do not ship the mode if the pool cannot support it.** Gate on
   `hardCount >= 10 && mediumCount >= 20 && easyCount >= 10` **per subject**.
   Today the gate fails for Hard everywhere. Options: (a) hide the card, or
   (b) show it with the label "Easy ⇄ Medium only — the bank has no Hard
   questions yet". Option (b) is honest and still useful.
2. **Never silently clamp.** If the engine wanted Hard and had to serve Medium,
   the result screen says: *"4 questions were easier than requested — the bank
   ran out of Hard items."* That is also the most useful content-gap report the
   team can get.
3. **Never reuse adaptive scores in rank/percentile estimates.** Different
   measurement, different meaning.
4. **Never label the fixed mock "adaptive".** The mock must stay a faithful NTA
   simulation.

---

## 7. Work plan

| Phase | Deliverable | Effort |
|---|---|---|
| **P0 — content truth** | `scripts/audit_question_bank.py` (difficulty by subject, missing answers, duplicate stems); decide the fate of `pyq_official.json`; fix `allocateQuestions` to respect difficulty for the *custom paper* path | 0.5 d |
| **P1 — engine** | `adaptive_engine_service.dart` + unit tests (band rule, clamping, blueprint, no-repeat) | 1 d |
| **P2 — screen** | Adaptive test screen reusing CBT chrome; 10/20/30 sessions | 1 d |
| **P3 — persistence** | `item_stats` table + migration + result screen with band trajectory | 1 d |
| **P4 — calibration** | Recompute `b` from attempts on app start; only then enable v1 targeting | 0.5 d |
| **P5 — content** | Fill Hard questions per subject; the mode becomes genuinely adaptive | ongoing |

P1 can start today; it needs no new content and no DB changes.

---

## 8. Test plan

**Unit (fast, no widgets)**
- `nextBand` truth table — all 6 transitions + both clamps.
- `pick` returns the exact band when available; nearest band when not; `null`
  only when the whole pool is empty.
- Blueprint: a 20-question session has 5 per subject ±1.
- Topic cap and no-repeat invariants over 1000 random sessions.
- Exhaustion: 40-question session on a 12-question pool terminates cleanly and
  reports `clamped`.

**Widget**
- Correct streak: band rises Easy → Medium → Hard.
- Wrong streak: band falls back.
- Result screen shows the clamped count when it is non-zero.

**Simulation (the one that matters)**
- Generate 10 000 synthetic students with known ability; run 30-item sessions;
  check recovered ability is within ±0.3 for a 200-item calibrated bank. If the
  recovery is worse, the selector is wrong — not the students.

---

## 9. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Only 3 Hard questions | Mode stops stretching after ~3 correct answers | P5 content; clamp reporting |
| `pyq_official.json` has no answers | 817 "new" questions cannot be graded | Answer-key pass before import; do not import as-is |
| Adaptive scores compared with mock scores | Misleading rank/percentile | Separate `testType`, no percentile on adaptive results |
| Per-subject ability with small pools | Physics may have no Hard item in the current chapter | Blueprint + nearest-band fallback + honest clamp message |
| Checkpoint/resume | Adaptive state must survive an app kill | Persist band + ability in the checkpoint model alongside answers |

---

## 10. Recommendation

Build **v0 (step rule)** now — it is what was asked, it is ~1.5 days of work, and
it makes the existing 87 questions feel meaningfully different. Do **not** build
the IRT layer until the bank has answer-keyed volume; with 3 Hard questions it
would be sophisticated maths pointing at an empty bucket.

The single highest-leverage action is still content: **answer-key the 817-question
dump and re-band it.** That converts a currently unusable asset into the pool
this feature needs.
