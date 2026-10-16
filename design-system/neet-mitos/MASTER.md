# NEET Mitos — Premium Mobile Design System

> This file is the visual source of truth for the Flutter app. Keep authentication, onboarding, dashboard, and feature screens within the same calm, premium study-product language.

## Product feel

- **Mood:** focused, reassuring, capable, premium — never institutional or exam-panic themed.
- **Core idea:** a quiet study space with clear next actions and visible progress.
- **Density:** moderate. Prefer one primary action per section, concise labels, and generous but purposeful spacing.
- **Motion:** restrained and useful. The sign-in hero may use a slow dot-matrix shimmer; ordinary controls use short transitions. Respect reduced-motion accessibility settings.

## Color system

| Role | Light | Dark | Use |
|---|---|---|---|
| Primary | `#0D4F4A` | `#4ED3B8` | Primary actions, selected navigation, key progress |
| Primary soft | `#D8F1EA` | `#115E59` | Selection and quiet brand surfaces |
| Background | `#F7F7F2` | `#081719` | App canvas |
| Surface | `#FFFEFB` | `#102528` | Cards and sheets |
| Muted surface | `#F2F4EF` | `#20383A` | Fields, secondary panels |
| Main text | `#132B2F` | `#EDF6F2` | Titles and body copy |
| Secondary text | `#52656A` | `#9CB1AD` | Supporting labels |
| Success | `#0D8B68` | `#34D399` | Correct answers and completed goals |
| Warning | `#B7791F` | `#FBBF24` | Streaks and due reminders |
| Error | `#B94545` | `#F87171` | Validation and destructive actions |

Subject accents remain distinct and consistent: **Biology** teal-green, **Chemistry** violet, **Physics** amber. Prefer soft subject-tinted cards with readable foreground text over full-saturation gradients.

## Typography

Use **Inter** throughout the Flutter app. Use strong, compact headlines for the primary task; use regular-weight body text with comfortable line-height. Reserve uppercase, letter-spaced labels for tiny metadata only. Do not mix in decorative display fonts.

## Layout and shape

- Use the existing `AppSpacing`, `AppRadius`, `AppShadows`, and `SubjectColors` tokens in `lib/core/theme/tokens.dart`.
- Standard screen gutters: 20–24 px; card padding: 16–24 px.
- Cards: 16–24 px radius, subtle outline, minimal shadow. Avoid stacked heavy shadows.
- Primary buttons: minimum 48 px high, clear verb-first labels, 12–16 px radius.
- Form fields: persistent labels, visible focus/error states, comfortable touch targets.
- Keep scrollable content clear of system insets and the persistent bottom navigation.

## Signature screens

### Sign-in and account creation

Use a dark deep-teal hero with a slowly shimmering fine dot field. The dots brighten into an original M-like study mark, then settle; no stock imagery, DNA clip-art, or distracting particle bursts. Keep the brand and one-line promise legible above a light, rounded form surface. Login, account creation, password recovery, Google sign-in, and guest access must remain easy to distinguish and retain their existing behavior.

### Home dashboard

Prioritize a personalized greeting, current study context, streak/accuracy, one prominent continue-or-start action, daily goal, quick practice links, and subject progress. Keep the content live and data-driven. Use calm surfaces and distinct subject accents rather than multiple competing gradient cards.

### Onboarding/setup

Keep steps short and clearly numbered. Make selections visibly selected, explain why a choice is requested, expose Back/Skip/Continue actions, and distinguish required study preferences from optional AI/API configuration.

### Other feature sections

Use consistent app-bar titles, surface cards, section spacing, button and field themes, loading/error states, and shared bottom navigation. Subject colors identify content type but must not replace semantic labels or accessible contrast.

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
- [ ] Bottom navigation does not cover scroll content or system gestures.
- [ ] Subject-specific accents remain consistent.
