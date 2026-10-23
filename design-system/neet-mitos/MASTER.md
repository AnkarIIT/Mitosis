# NEET Mitos — Quiet Momentum Design System

> Visual implementation companion to the repository-root `design.md` redesign blueprint. The new direction is simpler, content-first, and built around the app icon's navy/teal loop identity.

## Product feel

- **Mood:** focused, calm, clear, quietly confident.
- **Core idea:** open the app, know the next study action, make progress.
- **Density:** simple launchpad and grouped library; avoid a crowded feature catalogue and repeated cards.
- **Signature:** logo loop = continuity and steady progress. Use sparingly, never as generic decoration.
- **Motion:** purposeful 150–250 ms transitions; no constant shimmer or confetti during study/exams. Respect reduced-motion accessibility settings.

## Color system

The app icon establishes the identity pair: deep navy `#0A2344` and teal `#00B8A9`. Navy anchors type and structure; teal signals meaningful action, selection, or progress. Keep teal distinct from semantic success green. Map brand and semantic colors into shared light/dark tokens with accessible on-colors; never scatter logo hex values across screens. Favor warm light reading surfaces, navy structure, and restrained subject accents. Dark mode needs deep surfaces and accessible teal, not a direct logo inversion.

| Role | Light | Dark | Use |
|---|---|---|---|
| Brand navy | `#0A2344` | Theme-mapped deep navy | Brand structure, headings, focused chrome |
| Brand teal | `#00B8A9` | Theme-mapped accessible teal | Primary action and progress accent |
| Primary action | `#0A2344` | `#52D6C8` | Main actions and selected navigation |
| Primary soft | `#E3F5F2` | `#115E59` | Selection and quiet brand surfaces |
| Background | `#F6F8FB` | `#071629` | App canvas |
| Surface | `#FFFFFF` | `#0D2038` | Cards and sheets |
| Muted surface | `#F2F4EF` | `#1B3450` | Fields, secondary panels |
| Main text | `#0A2344` | `#F1F6FC` | Titles and body copy |
| Secondary text | `#52647A` | `#B2C1D1` | Supporting labels |
| Success | `#0D8B68` | `#34D399` | Correct answers and completed goals |
| Warning | `#B7791F` | `#FBBF24` | Streaks and due reminders |
| Error | `#B94545` | `#F87171` | Validation and destructive actions |

Subject accents remain distinct and consistent: **Biology** teal-green, **Chemistry** violet, **Physics** amber. Prefer soft subject-tinted cards with readable foreground text over full-saturation gradients.

## Typography

Use **Inter** throughout. Use a restrained type scale, human headline on Today, compact section titles, readable lesson/question text, and quiet metadata. Avoid decorative fonts and long all-caps labels.

## Layout and shape

- Evolve `AppSpacing`, `AppRadius`, `AppShadows`, and `SubjectColors` in `lib/core/theme/tokens.dart` to this brief.
- Use an 8 px base rhythm and 20 px phone gutter; constrain reading content on wide screens.
- Controls: 12–16 px radius; feature surfaces: 16–20 px. Pills are for chips/status only.
- Favor flat surfaces with a light border; reserve shadows for transient sheets and key action surfaces.
- Primary buttons: minimum 48 px high, clear verb-first labels, 12–16 px radius.
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
