# NEET Mitos — App Redesign Blueprint

This is the product brief and implementation plan for a full NEET Mitos redesign. It intentionally resets the product direction while preserving useful, working study capabilities. The current app is a Flutter Android/web product with a broad feature set and an established theme foundation; redesign navigation and screens around student needs before polishing individual components. The shared theme/tokens in `lib/core/theme/` describe current implementation, not a constraint on the new direction. `design-system/neet-mitos/MASTER.md` is the concise visual companion and must stay aligned with this blueprint.

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

### Logo-derived brand colors

Approximate colors sampled from the supplied 1024 px icon:

| Token | Hex | Intended role |
|---|---|---|
| Brand navy | `#0A2344` | Brand field, focused exam chrome, high contrast anchor |
| Brand teal | `#00B8A9` | Brand mark, progress emphasis, selected/highlight accents |
| White | `#FFFFFF` | Contrast on dark brand surfaces |

Use navy and teal as the recognizable brand pair, especially in identity and selected high-emphasis moments. Teal should not become a large-area background everywhere; protect its meaning by reserving it for actions, progress, selection, and brand accents. Use semantic success/error colors for correctness and validation rather than making all green states look like branding.

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

### Overall art direction: “quiet momentum”

Use a confident, editorial study interface: strong navy typography and anchors, bright teal for meaningful actions and forward motion, warm near-white reading surfaces, generous whitespace, and a small number of crisp subject accents. The app should feel simpler and more distinctive than the current green-on-green generic dashboard. The loop symbol is the visual signature; use it sparingly as a progress/continuity motif, not as a watermark behind every card. Prefer flat, well-structured surfaces and purposeful dividers over endless rounded cards, gradients, glass, or heavy shadows.

Brand ratios are guidance rather than literal screen coverage: mostly light neutral canvas, navy text/structure, teal accents, then small semantic/subject colors. Offer a considered dark theme using deep navy-adjacent surfaces and accessible teal; do not simply invert the logo or use saturated teal as dark-mode body text.

### Design foundations

- **Color:** establish explicit brand, semantic, subject, background, surface, text, and border tokens. Brand teal is not the success color. Provide on-color tokens and verify contrast before changing primary action colors.
- **Type:** Inter, with a restrained scale; large, human headline on Today, compact section titles, highly readable lesson/question text, quiet metadata.
- **Grid:** 8 px base rhythm; 20 px phone gutter; content max-width around 720 px for reading and forms; tighter, intentional layouts for CBT.
- **Shape:** consistent 12–16 px control radius; 16–20 px feature surface radius; pills only for filters/chips/status. Use less rounding than the current every-element-is-a-pill/card pattern.
- **Elevation:** mostly flat. Use a light border or subtle shadow to separate surfaces; reserve elevated treatment for transient sheets and key action cards.
- **Iconography:** one family, stroke/filled states consistently paired. No emojis for controls. Use the supplied icon asset faithfully; do not improvise a new wordmark.
- **Motion:** purposeful 150–250 ms transitions; progress may animate once on entry. No constant shimmer or confetti during study/exams; honor reduced motion.

### Color and theme

The Flutter theme defines the current semantic colors and light/dark behavior (`lib/core/theme/app_colors.dart`, `app_theme.dart`). Use adaptive theme colors in widgets rather than hardcoded one-off values. The shared theme has been moved toward the icon's navy/teal identity; continue replacing old per-screen colors with these tokens while preserving semantic state colors.

| Role | Current light token | Current dark token | Guidance |
|---|---|---|---|
| Primary action | `#0A2344` | `#52D6C8` | Main actions, active navigation |
| Brand accent | `#00B8A9` | `#52D6C8` | Progress, selection, identity accents |
| Primary soft | `#E3F5F2` | `#115E59` | Quiet selection and brand-tinted surfaces |
| App background | `#F6F8FB` | `#071629` | Main canvas |
| Surface | `#FFFFFF` | `#0D2038` | Cards and sheets |
| Main text | `#0A2344` | `#F1F6FC` | Titles and body copy |
| Supporting text | `#52647A` | `#B2C1D1` | Secondary metadata and hints |
| Success | `#0D8B68` | `#34D399` | Correct answers and completed goals |
| Warning | `#B7791F` | `#FBBF24` | Due reminders and caution |
| Error | `#B94545` | `#F87171` | Errors and destructive actions |

Subject accents from `SubjectColors`: Biology green (`#059669`), Chemistry violet (`#7C3AED`), Physics amber (`#D97706`). Use soft tints for larger surfaces and saturated accents for small markers/icons. Maintain readable contrast in both themes.

### Typography

Use **Inter** as the interface typeface, consistent with `AppTheme`. Use compact, semibold/bold headings for hierarchy, regular body text with comfortable line height for study content, and medium labels for controls. Avoid decorative typefaces, excessive all-caps, and long passages set in small text. Keep mathematical notation and question content especially legible.

### Spacing, shape, and elevation

Use existing `AppSpacing`, `AppRadius`, and `AppShadows` in `lib/core/theme/tokens.dart` rather than introducing arbitrary values.

- Standard page gutter: 20 px; allow up to 24 px on roomy screens.
- Common spacing rhythm: 4, 8, 12, 16, 24, 32, 48 px.
- Card padding: 16–24 px; standard card radius: 16–24 px.
- Controls: at least 48 px high for primary buttons; target at least 44 px touch areas.
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

The project has a useful technical foundation: Material 3, Inter, adaptive light/dark theme definitions, spacing/radius/shadow tokens, subject accents, shared widgets, and the new three-destination shell. Reuse technical primitives where they fit; continue bringing feature screens onto the same visual system.

### Phase 1 — Redefine brand foundations

- Confirm logo navy/teal as brand identity colors and define accessible light/dark semantic mappings in `app_colors.dart` and `AppTheme`.
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
- The supplied icon palette and current app theme differ. Before broad UI restyling, reconcile brand navy/teal with semantic light/dark tokens and verify contrast; avoid sprinkling logo hex values ad hoc across screens.
- This file guides future product design and is not a claim that every screen already conforms.

## Design review checklist

- [ ] Is the primary next action clear without competing calls to action?
- [ ] Does the screen reflect the plan, learn, practice, review, progress loop?
- [ ] Are all visible metrics and availability claims based on real state?
- [ ] Are brand, subject, and semantic colors used consistently and accessibly?
- [ ] Are light and dark themes readable, including selected/error/correct states?
- [ ] Are touch, keyboard, text-scaling, safe-area, and narrow-width needs covered?
- [ ] Does motion support the task and pause/reduce when requested?
- [ ] Are offline, loading, empty, and failure states clear and actionable?
