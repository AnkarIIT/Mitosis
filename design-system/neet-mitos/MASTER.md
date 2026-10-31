# NEET Mitos — Calm Precision Design System

> Visual implementation companion to the repository-root `design.md` redesign blueprint. The workspace uses warm neutrals and deep teal; the app icon's navy/bright-teal loop remains the identity mark.

## Product feel

- **Mood:** focused, calm, encouraging, quietly premium.
- **Core idea:** open the app, know the next study action, make progress.
- **Density:** simple launchpad and grouped library; avoid a crowded feature catalogue and repeated cards.
- **Signature:** two-node loop = continuity and cell division. Use on onboarding, empty states, and session completion, never behind question content.
- **Motion:** purposeful 150–250 ms transitions; no constant shimmer or confetti during study/exams. Respect reduced-motion accessibility settings.

## Color system

The app icon establishes the identity pair: deep navy `#0A2344` and bright teal `#00B8A9`. Reserve those for the mark and small brand moments. The Calm Precision workspace uses warm ivory, charcoal, and deep action teal. Keep action teal distinct from semantic success green. Map all roles into shared light/dark tokens; never scatter logo hex values across screens.

| Role | Light | Dark | Use |
|---|---|---|---|
| Logo navy | `#0A2344` | — | Supplied icon field and identity |
| Logo teal | `#00B8A9` | `#52D6C8` | Supplied mark and small brand accents |
| Primary action | `#146C60` | `#72C8B5` | Main actions and selected navigation |
| Primary soft | `#E5F2EC` | `#17483F` | Selected answers and quiet highlights |
| Background | `#F7F8F5` | `#071B18` | App canvas |
| Surface | `#FFFFFF` | `#102521` | Cards and sheets |
| Muted surface | `#F1F4F0` | `#1A3630` | Fields and secondary panels |
| Main text | `#172724` | `#F1F6F4` | Titles and body copy |
| Secondary text | `#566762` | `#B8C7C1` | Supporting labels |
| Success | `#187A55` | `#34D399` | Correct answers and completed goals |
| Warning | `#946200` | `#FBBF24` | Due reminders and caution |
| Error | `#B3261E` | `#F87171` | Validation and destructive actions |

Subject accents remain distinct and consistent: **Biology** teal-green, **Chemistry** violet, **Physics** amber. Prefer soft subject-tinted cards with readable foreground text over full-saturation gradients.

## Typography

Use **Roboto** with Android's Noto Sans Devanagari system fallback. Starting scale: 28 px screen heading, 20 px section heading, 18 px question text, 16 px body/options, and 12–14 px labels. Respect user text scaling and test Hindi, equations, and chemistry notation.

## Layout and shape

- Evolve `AppSpacing`, `AppRadius`, `AppShadows`, and `SubjectColors` in `lib/core/theme/tokens.dart` to this brief.
- Use an 8 px base rhythm and 20 px phone gutter; constrain reading content on wide screens.
- Controls: 12 px radius; cards: 16 px. Pills are for chips/status only.
- Favor flat surfaces with a light border; reserve shadows for transient sheets and key action surfaces.
- Primary buttons: 52 px high (never below 48 px), clear verb-first labels, 12 px radius.
- Form fields: persistent labels, visible focus/error states, comfortable touch targets.
- Keep scrollable content clear of system insets and the persistent bottom navigation.

## Signature screens

### Sign-in and account creation

Use the navy/teal identity with a clear promise, calm form layout, and distinct login, account creation, recovery, Google, and guest paths. Keep guest/local study easy to find. Avoid a mandatory long animation or invented M-like mark; use the supplied app icon as-is.

### Today launchpad

Show today's plan and one clear start action, plus conditional resume/review state and a compact progress signal. Move deep stats, subject catalogue, and secondary tools elsewhere. No long feed of stacked banners or competing CTAs.

### Three-destination navigation

Use **Today · Study · You** as the persistent navigation. Study groups Learn, Practice, and Review; You groups progress, goals, profile, and settings. Keep all existing capabilities reachable without preserving the current five-tab structure.

### Study and practice

Organize subject → chapter → lesson/practice as a coherent journey. Keep question content dominant and state cues consistent. Label CBT as a NEET-style practice simulation; keep timed practice calm and distraction-free.

### Quiz and CBT practice

Keep the question, answers, timer, section, and navigation states easy to scan. Label answer-palette states and do not rely on color alone. Present full-length CBT as a NEET-style practice simulation; do not imply that it reproduces the official OMR-based NEET exam. Keep timed practice visually stable and distraction-free.

### Onboarding/setup

Keep steps short and clearly numbered. Make selections visibly selected, explain why a choice is requested, expose Back/Skip/Continue actions, and distinguish required study preferences from optional AI/API configuration.

### Other feature sections

Use consistent page titles, restrained surfaces, section spacing, buttons/fields, loading and error states, and the three-destination navigation. Subject colors identify content type but must not replace semantic labels or accessible contrast.

## Accessibility and interaction

- Maintain WCAG AA contrast for text and meaningful controls.
- Preserve semantic labels/tooltips for icon-only actions and at least 44 px touch targets.
- Keep focus, pressed, selected, disabled, loading, and error states visible.
- Never use color alone to communicate correctness, selection, or urgency.
- Avoid emojis as functional icons; use the existing Material icon family.
- No horizontal overflow at narrow phone widths; verify both light and dark themes.

## Review checklist

- [ ] Auth and setup actions/validation still work.
- [ ] Motion pauses when reduced motion is requested.
- [ ] Main text and field labels are legible in light and dark themes.
- [ ] Primary action is obvious without scrolling where practical.
- [ ] Today · Study · You navigation remains clear and does not cover scroll content or system gestures.
- [ ] Subject-specific accents remain consistent.

## v1.0 implementation handoff — Android light theme

The exact light tokens, contrast calculations, typography, dimensions, MCQ
states, and acceptance checklist live in `tokens.light.json` and the root
`design.md` section **Calm Precision v1.0**. These are targets; they do not
claim full implementation or device verification.

Key component measurements: screen title 28/36sp 600; section 20/28sp 600;
question 18/28sp 400; body/options 16/24sp 400; labels 14/20sp 500; metadata
12/16sp 400. Use a 20dp phone gutter, 20dp card padding, 16dp card radius,
12dp control radius, and 640dp maximum question-reading width. Main buttons
are at least 52dp high. MCQ rows are at least 64dp high with 16dp padding,
24dp answer marker, 12dp gap, and a 1dp interactive outline in the default
state. Let every dimension grow under text scaling.

For answer behavior, practice is **Select → Check answer → Feedback → Next**;
test is **Select → Save & next**, with correctness hidden until submitted
review. The current `EnhancedQuizScreen` reveals correctness immediately on
selection; mode-specific behavior remains implementation work. Do not mark
this acceptance item complete until the quiz mode is explicit and verified.

Contrast figures use WCAG relative luminance: white on primary 6.28:1,
secondary on white 5.98:1, charcoal on warm canvas 14.57:1, success/error/
warning on their containers 5.86:1 / 5.71:1 / 4.78:1. `outline` on white is
4.10:1, which passes the 3:1 non-text boundary target, not the 4.5:1 text
target. Reserve `borderSubtle` for decorative dividers and non-interactive
card edges; controls need `outline` or stronger contrast.

## iOS adaptation

Keep the shared Mitos palette, content hierarchy, signature loop, MCQ feedback
colors, and product behavior. Do not port Material components literally.
`tokens.light.json` now contains an iOS profile; `design.md` has the complete
platform handoff.

- Layout units are **pt**. Use SF Pro/system text styles and Dynamic Type:
  large title 34pt, compact title 22pt, section 20pt, question 18pt scaled,
  body/button 17pt, supporting 15pt, caption 12pt.
- Use SF Symbols consistently; targets are at least 44×44pt. Primary actions
  are 52pt minimum height, 20pt horizontal padding, 12pt radius.
- Keep cards at 16pt radius and 20pt padding, with a subtle border and no
  default shadow. Let text grow; MCQ rows are minimum 64pt, not fixed height.
- Use iOS navigation stack/back swipe, native phone tab bar, native sheets and
  alerts for contextual tasks, safe areas/home-indicator handling, VoiceOver,
  and Reduce Motion. Adapt iPad to readable columns.
- Light semantic colors and MCQ feedback logic stay shared. Design dark colors
  separately; never invert automatically. Test feedback stays hidden until
  submitted review; practice offers check-answer feedback before moving on.

The Flutter target currently has a platform-aware system font/text scale,
Cupertino route transition, and Cupertino phone tab bar. Other controls and
accessibility states still need an iOS-specific audit. Simulator/device QA is
pending; this Windows environment cannot run Xcode or an iOS simulator.
