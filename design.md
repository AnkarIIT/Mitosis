# NEET Mitos — App Redesign Blueprint

This is the product brief and implementation plan for a full NEET Mitos redesign. It intentionally resets the product direction while preserving useful, working study capabilities. The current app is a Flutter Android/iOS/web product with a broad feature set and an established theme foundation; redesign navigation and screens around student needs before polishing individual components. The shared theme/tokens in `lib/core/theme/` describe current implementation, not a constraint on the new direction. `design-system/neet-mitos/MASTER.md` is the concise visual companion and must stay aligned with this blueprint.

## North star

NEET Mitos is a free, offline-first NEET preparation app for Android and web. The promise: **open the app, know what to study next, and make measurable progress in one focused session.** It should feel like a calm, capable study companion, not a coaching institute portal, a crowded feature catalogue, or a gamified social feed. The core loop is **decide → study → practice → learn from mistakes → return**.

### Design goals

- Make the next useful study action obvious.
- Keep progress, revision due dates, and weak topics understandable at a glance.
- Support both short practice sessions and formal, timed NEET-style CBT exams.
- Make core study flows usable offline and communicate connectivity honestly.
- Build confidence through clear feedback, predictable controls, and readable content.

## Brand identity

The supplied app icon is a two-node continuous loop on a deep navy field. It suggests repetition, connection, and steady progress. Carry that simple geometry and contrast into the interface with restrained use of the loop mark, connected progress indicators, and clear recurring study rhythms. Do not use literal spinner imagery as a decorative motif, or imply that a feature is available when it is not.

### Brand mark and workspace palette

The supplied icon provides the identity pair. Keep it recognizable on launch,
onboarding, and small brand placements. Study screens use the restrained
**Calm Precision** palette below so bright logo teal remains a distinct accent.

| Token | Hex | Intended role |
|---|---|---|
| Logo navy | `#0A2344` | Supplied icon field and identity moments |
| Logo teal | `#00B8A9` | Supplied mark and restrained brand accents |
| Action teal | `#146C60` | Primary workspace actions and selected navigation |
| Warm ivory | `#F7F8F5` | Main light canvas |
| Soft mint | `#E5F2EC` | Selected answers and quiet highlights |
| Deep charcoal | `#172724` | Main study text |
| Muted slate | `#566762` | Supporting text |

Reserve logo navy and bright teal for identity moments. Use deep action teal
for important controls; use semantic success and error colors for correctness
and validation rather than making every green state look like branding.

## Experience principles

1. **One clear next step.** Give each screen one primary action; keep secondary paths visible without equal visual weight.
2. **Study first.** Keep learning material, question wording, timers, and answer controls more prominent than decoration.
3. **Calm density.** Show enough information to act, with progressive disclosure for detailed analytics and settings.
4. **Honest progress.** Use real user data; never fabricate scores, streaks, availability, or resumable state.
5. **Offline clarity.** Distinguish local-ready content from network-dependent capabilities and explain when sync or AI is unavailable.
6. **Respect exam focus.** Timed CBT mode should use a stable, compact layout and avoid celebratory or distracting motion while the exam is active.

## Proposed product structure

Replace the current five-tab bottom navigation with **three destinations**. This reduces choice at the top level and moves secondary tools closer to the moment they are useful. This is the recommended redesign direction; retain all working capabilities as reachable destinations.

| Destination | Purpose | Typical content |
|---|---|---|
| **Today** | Decide and resume | Today's plan, one next action, due review, continue study, small progress signal |
| **Study** | Learn and practice | Subjects/chapters, NCERT, modules, practice sets, PYQs, DPP, mocks, flashcards, error review |
| **You** | Personalize and understand | Progress, study history, goals, account/profile, downloads, settings/help |

Keep primary navigation labels and order consistent across phone and wide layouts. Within Study, use a simple segmented entry such as **Learn · Practice · Review**, or a clear top-level section index; avoid adding a fourth/fifth persistent tab. Make global search available from Study and Today only if it searches real content. On wide screens, use space for readable content columns and supporting navigation, not stretched question text.

### Screen map

```text
Today
├── Today's plan / Start session
├── Continue session (only when resumable state exists)
├── Review due (only when items are due)
└── Progress snapshot → You / detailed progress

Study
├── Learn: Subjects → Chapters → Topic / NCERT / notes
├── Practice: Quick practice / DPP / PYQ / Mock tests / Mark booster
└── Review: Error book / flashcards / bookmarks

You
├── Progress & study history
├── Goals and schedule
├── Profile / account
└── Downloads / settings / help
```

## Core flows and screen direction

### Today — one calm launchpad

The home screen should answer, in order: **What should I do today? How do I start? What needs attention?** Show a brief greeting, today's commitment/progress, one clear primary session card, and at most one conditional review/resume card. Put deeper stats, subject catalog, resource shortcuts, and secondary tools behind Study or You. Avoid a long feed of banners, repeated CTAs, and multiple competing cards. The primary action can be generated from the plan but must always have a sensible fallback such as choosing a subject.

### Study — a single organized library

Open on clear choices: continue learning, browse subjects, or start practice. Keep Learn, Practice, and Review as modes within this destination. Group subjects, chapters, offline NCERT resources, modules, PYQs, DPPs, memory tools, and error review into predictable browse patterns. Use a small number of grouped sections, not a wall of feature tiles. Make subject/chapter hierarchy and downloaded/offline status visible. Preserve reading comfort and location context in lesson and PDF views. Do not let subject accent colors replace subject names.

### Practice and quiz

Keep one question as the visual focus. Make question number, subject/topic, timer when applicable, answer options, selection state, and navigation controls unambiguous. Selected, correct, incorrect, flagged, visited, and unanswered states need distinct shape/icon/text cues as well as color. Keep explanations and hints available without obscuring the question. Results should summarize performance and offer a concrete review or retry action.

### Full-length CBT practice exam

Prioritize exam content, remaining time, section context, and the answer palette. Use restrained high-contrast status colors with labels for answered, unanswered, marked, and answered-and-marked states. Confirmation is required for submission; checkpoint/resume state must be communicated clearly. Do not use celebratory animation until the practice exam is complete, and keep all exam controls reachable at narrow widths. Describe this mode as a NEET-style CBT practice simulation; do not imply that it reproduces the official NEET exam, which is OMR-based.

### Review and progress

Frame revision as a manageable next session, with due counts and missed concepts easy to scan. Surface a small due cue on Today only when actionable; put the full review tools inside Study. Put detailed progress in You, with a small honest snapshot on Today. Explain time range and denominator (for example, attempts/questions) and distinguish practice accuracy from predicted exam score. Pair every chart or metric with a plain-language label and useful next step.

### Onboarding and account

Ask only for information needed to personalize study. Keep steps short, numbered when multi-step, and explain why a preference is requested. Guest/local study remains a first-class entry path. Separate optional account, AI, and cloud configuration from required study setup; accurately describe beta or unavailable features.

## Visual system

### Overall art direction: “Calm Precision”

Use a focused, trustworthy study workspace with warm ivory surfaces, deep teal
actions, crisp familiar typography, and generous spacing. The app should feel
encouraging rather than clinical or like a coaching poster. Let the two-node
loop carry the Mitos identity on onboarding, empty states, and session
completion; do not decorate question screens with it. Prefer clear structure,
plain rows, light borders, and purposeful spacing over nested cards, gradients,
glass effects, and heavy shadows.

Use mostly warm neutral canvas, charcoal text, teal actions, then small
semantic and subject accents. Offer a considered dark theme with deep neutral
surfaces and readable teal controls; do not simply invert the logo or use
saturated teal as body text.

### Design foundations

- **Color:** establish explicit brand, semantic, subject, background, surface, text, and border tokens. Logo teal is not the primary action or success color. Provide on-color tokens and verify contrast.
- **Type:** Roboto with a system Devanagari fallback; use a restrained scale, readable lesson/question text, and quiet metadata. Respect user text scaling.
- **Grid:** 8 px base rhythm; 20 px phone gutter; content max-width around 720 px for reading and forms; tighter, intentional layouts for CBT.
- **Shape:** 12 px control radius and 16 px card radius; pills only for filters/chips/status.
- **Elevation:** mostly flat. Use a light border or subtle shadow to separate surfaces; reserve elevated treatment for transient sheets and key action cards.
- **Iconography:** one family, stroke/filled states consistently paired. No emojis for controls. Use the supplied icon asset faithfully; do not improvise a new wordmark.
- **Motion:** purposeful 150–250 ms transitions; progress may animate once on entry. No constant shimmer or confetti during study/exams; honor reduced motion.

### Color and theme

The Flutter theme defines semantic colors and light/dark behavior (`lib/core/theme/app_colors.dart`, `app_theme.dart`). Use adaptive theme colors in widgets rather than hardcoded one-off values. The shared theme follows Calm Precision: the logo navy/bright teal remain identity colors, while deep teal is the workspace action color.

| Role | Current light token | Current dark token | Guidance |
|---|---|---|---|
| Primary action | `#146C60` | `#72C8B5` | Main actions, active navigation |
| Logo accent | `#00B8A9` | `#52D6C8` | Supplied mark and limited identity accents |
| Primary soft | `#E5F2EC` | `#17483F` | Selected answers and quiet highlights |
| App background | `#F7F8F5` | `#071B18` | Main canvas |
| Surface | `#FFFFFF` | `#102521` | Cards and sheets |
| Main text | `#172724` | `#F1F6F4` | Titles and body copy |
| Supporting text | `#566762` | `#B8C7C1` | Secondary metadata and hints |
| Success | `#187A55` | `#34D399` | Correct answers and completed goals |
| Warning | `#946200` | `#FBBF24` | Due reminders and caution |
| Error | `#B3261E` | `#F87171` | Errors and destructive actions |

Subject accents from `SubjectColors`: Biology green (`#059669`), Chemistry violet (`#7C3AED`), Physics amber (`#D97706`). Use soft tints for larger surfaces and saturated accents for small markers/icons. Maintain readable contrast in both themes.

### Typography

Use **Roboto** as the interface typeface, with Android's Noto Sans Devanagari system fallback for Hindi. Use a restrained 28 px screen title, 20 px section title, 18 px question text, 16 px body/options, and 12–14 px metadata. Keep comfortable line height, respect user font scaling, and verify Hindi, equations, and chemical notation with real content.

### Spacing, shape, and elevation

Use existing `AppSpacing`, `AppRadius`, and `AppShadows` in `lib/core/theme/tokens.dart` rather than introducing arbitrary values.

- Standard page gutter: 20 px; allow up to 24 px on roomy screens.
- Common spacing rhythm: 4, 8, 12, 16, 24, 32, 48 px.
- Card padding: 16–20 px; standard card radius: 16 px.
- Controls: 52 px primary buttons (never below 48 px); target at least 44 px touch areas.
- Prefer thin outlines and subtle shadows; avoid stacked elevation and glass effects that reduce clarity.
- Use the existing rounded, contained bottom navigation on phones; ensure content scrolls above it and respects system insets.

### Iconography and imagery

Use the existing Material icon family consistently. Functional icons need labels or tooltips where their purpose is not obvious. Prefer subject diagrams and authentic learning content over stock photos. Use the supplied logo without distorting its proportions or placing teal on a low-contrast background. Avoid emoji as controls, generic DNA/evolution clip-art, and decorative noise.

### Motion and feedback

Use short transitions for selection, navigation, and progress updates; motion should explain state, not compete with studying. Reserve celebration for meaningful completed goals or finished practice, never during active CBT. Respect reduced-motion preferences. Loading skeletons should resemble the content shape and resolve to useful empty, offline, or error states rather than indefinite shimmer.

## Responsive behavior

- Design mobile-first for compact Android phones and the PWA shell.
- Keep primary actions and quiz controls reachable without horizontal scrolling.
- At wider widths, constrain reading/question line length and use a centered content column or deliberate split pane.
- Use a persistent sidebar only where there is enough width; preserve the same three destinations and labels as phone navigation.
- Account for keyboard, safe areas, display cutouts, and the bottom navigation when laying out forms and scrollable content.

## Accessibility and states

- Meet WCAG AA contrast for text and meaningful controls.
- Pair color with text, icon, outline, or shape for selected, correct, incorrect, flagged, urgent, and disabled states.
- Provide semantic names/tooltips for icon-only controls and visible keyboard focus on web.
- Support text scaling without clipping critical labels or exam actions.
- Provide visible loading, empty, offline, error, success, and disabled states.
- Keep errors specific and actionable; preserve entered answers and form values when possible.

## Redesign delivery plan

The project has a useful technical foundation: Material 3, Roboto, adaptive light/dark theme definitions, spacing/radius/shadow tokens, subject accents, shared widgets, and the three-destination shell. Reuse technical primitives where they fit; continue bringing feature screens onto the same visual system.

### Phase 1 — Redefine brand foundations

- Keep logo navy/bright teal as identity colors; use the Calm Precision workspace palette and define adaptive semantic mappings in `app_colors.dart` and `AppTheme`.
- Keep success green distinct from brand teal; check text/icon contrast on every brand surface.
- Keep `design-system/neet-mitos/MASTER.md` aligned with this brief and remove competing or stale palette guidance.
- Establish logo usage (icon-only, wordmark if one exists, clear space, minimum size, background choices) from the supplied asset; do not invent a wordmark asset.

### Phase 2 — Restructure navigation and Today

- Replace five persistent tabs with Today, Study, and You; update routing and deep-link destinations without losing feature access.
- Rebuild Today as a short launchpad: plan/session card, conditional resume/review state, compact progress snapshot.
- Consolidate feature discovery under Study and account/progress under You.
- Establish navigation, app-bar, and page-shell components before screen-by-screen styling.

### Phase 3 — Rebuild Study journeys and shared components

- Build a cohesive subject → chapter → lesson/practice journey and organize DPP/PYQ/mocks/review as grouped Study modes.
- Audit shared cards, buttons, chips, fields, progress, and status components against the new foundations.
- Redesign quiz, result, flashcard, and CBT practice screens for content-first clarity and consistent state language.
- Keep CBT practice chrome compact; make palette states understandable with labels, symbols, and accessible semantics.

### Phase 4 — Rebuild You, accessibility, and responsive polish

- Consolidate profile, settings, study goals, history, and detailed progress in You.
- Verify representative flows in light/dark mode, narrow phone, large text, keyboard/web, and wide layouts.
- Check keyboard focus and navigation on web, safe areas and gesture insets on mobile, and contrast for all interactive states.
- Reduce or pause motion when requested; remove nonessential motion from timed practice.
- Reconcile documented state behavior with real offline, loading, empty, error, and beta/disabled product states.

These phases are the recommended redesign sequence, not a claim that the work is already implemented. Do not attempt a cosmetic pass over every feature before simplifying the navigation and core journeys. Validate each phase against current app behavior and preserve working capabilities while changing the structure.

## Implementation guidance

- Treat `lib/core/theme/app_theme.dart`, `app_colors.dart`, `tokens.dart`, and shared widgets in `lib/core/theme/` and `lib/core/widgets/` as the Flutter design-system implementation.
- Prefer shared components/tokens for repeated cards, chips, progress indicators, buttons, fields, and status badges.
- Keep real feature behavior and capability limits intact when changing presentation.
- The logo identity and Calm Precision workspace palettes are mapped separately in shared light/dark tokens; keep using adaptive colors and verify contrast in each screen.
- This file guides future product design and is not a claim that every screen already conforms.

## Current implementation status

The shared theme now uses the Calm Precision workspace palette, Roboto with a
Devanagari system fallback, Material 3 controls, and the logo colors for
identity moments. Today, Study, and You have been simplified; quiz answer
states, study-plan feedback, and progress empty states follow the same direction.

The app-wide migration is still in progress. Continue applying these tokens to
remaining feature pages and verify the full study journey with real content on
small phones, large text, dark mode, and web. Check every route for empty,
loading, error, offline, and completion states before calling the redesign done.

## Design review checklist

- [ ] Is the primary next action clear without competing calls to action?
- [ ] Does the screen reflect the plan, learn, practice, review, progress loop?
- [ ] Are all visible metrics and availability claims based on real state?
- [ ] Are logo, workspace, subject, and semantic colors used consistently and accessibly?
- [ ] Are light and dark themes readable, including selected/error/correct states?
- [ ] Are touch, keyboard, text-scaling, safe-area, and narrow-width needs covered?
- [ ] Does motion support the task and pause/reduce when requested?
- [ ] Are offline, loading, empty, and failure states clear and actionable?

## Calm Precision v1.0 — Android light-theme implementation handoff

This section turns the visual direction into measurable component and state
rules for Android light theme. It is a target specification, not a claim that
every rule is already implemented or device-verified. A machine-readable copy
of the tokens is in `design-system/neet-mitos/tokens.light.json`.

### Exact foundations

| Role | Token | Value | Use |
|---|---|---|---|
| Main canvas | `background` | `#F7F8F5` | Warm neutral screen background |
| Surface | `surface` | `#FFFFFF` | Cards, sheets, answer rows |
| Primary text | `textPrimary` | `#172724` | Titles, questions, answer text |
| Secondary text | `textSecondary` | `#566762` | Supporting copy and labels |
| Main action | `primary` | `#146C60` | Primary CTA and selected controls |
| On action | `onPrimary` | `#FFFFFF` | Text/icons on primary action |
| Selected container | `primaryContainer` | `#E5F2EC` | Selected answer/control background |
| Interactive outline | `outline` | `#71817A` | MCQ and input boundaries; focus |
| Decorative border | `borderSubtle` | `#DCE5DF` | Dividers and non-interactive card edges only |
| Success | `success` / `successContainer` | `#216A43` / `#EAF5ED` | Correct answer and positive status |
| Error | `error` / `errorContainer` | `#B3261E` / `#FCECEB` | Incorrect answer and validation |
| Warning | `warning` / `warningContainer` | `#946200` / `#FFF4D6` | Caution and due status |

Contrast was calculated using WCAG relative luminance for these pairs: white on
primary **6.28:1**, secondary text on white **5.98:1**, charcoal on warm canvas
**14.57:1**, success on its container **5.86:1**, error on its container
**5.71:1**, and warning on its container **4.78:1**. The interactive outline
`#71817A` on white is **4.10:1**: suitable as a non-text control boundary under
the 3:1 target, but not for small text. Never use `borderSubtle` as the sole
visible boundary of an MCQ option or input. Recalculate if any value changes.

### Android type and layout

Roboto is the interface font; use Noto Sans Devanagari as the Android Hindi
fallback. Scale is in Android `sp`; line heights are starting minimums and may
grow with font scaling or Devanagari shaping.

| Role | Size / line height | Weight |
|---|---:|---:|
| Screen title | 28 / 36 sp | 600 |
| Section heading | 20 / 28 sp | 600 |
| Question | 18 / 28 sp | 400 |
| Body / answer | 16 / 24 sp | 400 |
| Button | 16 / 24 sp | 500 |
| Label | 14 / 20 sp | 500 |
| Metadata | 12 / 16 sp | 400 |

Spacing scale: `4, 8, 12, 16, 20, 24, 32, 48, 64 dp`. Phone gutter is 20dp;
cards use 20dp padding; option rows have 12dp gaps; sections use 24–32dp.
Use 8dp small, 12dp control, 16dp card, and 24dp sheet radii. Constrain wide
question reading columns to 640dp. Heights are minimums, never fixed sizes:
long questions, Hindi, chemistry notation, equations, and large system text
must be allowed to wrap and grow.

### Buttons, cards, and fields

- Primary button: 52dp minimum height, 12dp radius, 20dp horizontal padding;
  keep its width and label stable while loading and block duplicate submits.
- Button states: default, pressed, keyboard/accessibility focused, disabled,
  and loading. Secondary actions use text or outline treatment.
- Card: white surface, 16dp radius, 20dp padding, 1dp subtle border, zero
  default elevation. Add shadow only when a layer truly floats.
- Field: persistent visible label, 48dp or taller touch target, 2dp focused
  outline, clear error text and icon. Placeholder is supplementary only.
- Icons: one Material rounded family; navigation keeps text labels. Chips are
  for filters/status, never the only affordance for a primary action.

### MCQ component and state contract

Option anatomy: whole row selectable; at least 64dp tall; 16dp inner padding;
24dp letter/selection marker; 12dp marker-to-copy gap; 12dp radius. Reserve
border space in every state so the row never shifts. Long option text wraps;
never truncate it. Keep correct/incorrect label and icon alongside color.

| State | Visual contract | Interaction |
|---|---|---|
| Default | White, 1dp `outline`, empty letter marker | Selectable |
| Selected | Mint fill, 1.5dp teal outline, checked marker | Can change before check/save |
| Submitting | Preserve selection and row geometry | Lock briefly; no correctness shown |
| Correct review | Success container, check icon, “Correct answer” | Review state |
| Selected incorrect review | Error container, close icon, “Your answer · Incorrect”; highlight correct row too | Review state |
| Other review options | Neutral surface and text | Do not mark every distractor red |
| Unanswered review | Question-level “Not answered”; correct row identified | Review state |
| Submission failure | Keep selected answer; announce actionable retry | Never infer correctness |

**Practice flow:** Select → Check answer → Correct/incorrect feedback → Next.
**Test flow:** Select → Save & next; hide correctness until the test is submitted
and the user enters review. Revisit/change answers before submission where the
test rules allow. The quiz screen now derives reveal behavior from `testType`
(`mock`/`exam` hide correctness until completion; practice/review reveal it);
the mode-specific behavior is implemented.

### Acceptance checklist

- [ ] Verify token contrast in the rendered Android theme; keep the listed
  foreground/container ratios at or above 4.5:1 for text and 3:1 for
  non-text boundaries.
- [ ] Verify option states, semantics, keyboard/focus feedback, no layout jump,
  and no correctness leakage during test mode.
- [ ] Verify long English/Hindi questions, chemical notation, diagrams, and
  maximum Android font scale on a narrow phone and a 640dp+ window.
- [ ] Verify TalkBack names for option letter, answer text, selected state,
  and result label; color alone must never communicate meaning.
- [ ] Check loading, empty, failed submission, disabled, and resumed states.
- [ ] Treat JSON as the project's custom token schema, not a drop-in Android
  resource or generated theme. Dark theme remains separately specified.

## iOS adaptation — shared brand, native platform behavior

The Android spec above is the visual baseline, not a component blueprint to
copy onto iOS. Keep Mitos's shared palette, content hierarchy, calm composition,
cell-division motif, spacing rhythm, semantic answer colors, and practice/test
rules. Use iOS-specific layout units and familiar iOS navigation, typography,
controls, and presentation. JSON includes both platform profiles.

### iOS foundations

- **Units:** define iOS layout in points (`pt`), separately from Android `dp`.
  Shared spacing intent can map to the same numeric rhythm, but components must
  follow platform conventions and adapt to available width.
- **Type:** use the iOS system font (SF Pro) and semantic text styles, not a
  forced Roboto family. Starting defaults: `.largeTitle` 34pt, `.title2` 22pt,
  `.title3` 20pt, question 18pt scaled relative to `.body`, `.body` 17pt,
  `.headline` 17pt, `.subheadline` 15pt, and `.caption` 12pt. In Flutter, keep
  text scale enabled and use the platform system font; map app text roles to
  equivalent semantic sizes rather than pinning fixed heights.
- **Dynamic Type:** support the full accessibility text-size range. Rows,
  buttons, navigation labels, and sheets grow with content. Do not truncate
  questions or use fixed-height answer rows.
- **Color:** reuse the exact shared light tokens from the Android profile and
  `tokens.light.json`. Use named Asset Catalog colors or central semantic
  tokens. Dark appearance needs deliberately designed values; never auto-invert
  the light palette.
- **Controls:** primary button 52pt minimum height, 20pt horizontal padding,
  12pt radius, `.headline` text. Cards use 16pt radius, 20pt padding, white
  surface, subtle border, and no default shadow. Touch targets are at least
  44×44pt; these are Mitos component choices, not claims about Apple's required
  dimensions.
- **Icons:** prefer SF Symbols with consistent weight and clear selected
  variants. Keep visible text labels for primary navigation.

### iOS navigation and system behavior

- Use a native-feeling navigation stack with conventional back behavior,
  interactive swipe-back, and a native tab bar on phone. In this Flutter app,
  retain GoRouter as routing state while using Cupertino page transitions and
  `CupertinoTabBar` for the primary iOS shell.
- Use platform-appropriate buttons, form affordances, sheets, and alerts for
  short contextual tasks. Keep the full practice flow in a full screen, never a
  cramped sheet.
- Respect safe areas, home-indicator inset, keyboard, and interactive-dismiss
  behavior. Keep bottom actions above the home indicator.
- Use haptics only for meaningful feedback. Support VoiceOver, Dynamic Type,
  Reduce Motion, and accessible focus states; decorative icons should not be
  announced separately.
- For iPad, adapt to available width with a readable constrained question
  column or deliberate split layout. Do not stretch a phone composition across
  the whole window.

### Shared MCQ behavior

Keep the Android state colors and semantics: selected = mint + teal outline;
correct = success tint + check + label; selected incorrect = error tint + cross
+ label; other options remain neutral. The whole row is selectable. VoiceOver
must announce the option's complete text, selected state, and review result.
Do not expose correctness before review in test mode. Practice remains Select
→ Check answer → Feedback → Next; test remains Select → Save & next → Submit
→ Review. This product behavior is platform-independent.

### Current iOS implementation status

The repository has a Flutter iOS target. Shared semantic colors now apply;
the app theme uses platform text sizing/system font on iOS, page transitions
use the Cupertino transition, and the primary phone navigation uses
`CupertinoTabBar`. This is a first adaptation pass, not a full native-control
migration. Forms, alerts/sheets, MCQ interaction polish, VoiceOver, Dynamic
Type extremes, Reduce Motion, safe-area behavior, iPad layout, and visual
contrast still require iOS simulator/device review. This environment cannot
run Xcode or an iOS simulator, so iOS visual QA is unverified.
