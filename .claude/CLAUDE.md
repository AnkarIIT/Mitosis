# NEET Mitos — Claude Code Guide

## Project: AI-Powered NEET Preparation App (Flutter)

### Design System: Calm Precision
- **Palette:** Warm ivory canvas `#F7F8F5`, deep teal actions `#146C60`, charcoal text `#172724`
- **Identity:** Logo navy `#0A2344` / bright teal `#00B8A9` for brand moments only
- **Typography:** Roboto + Noto Sans Devanagari fallback. Sizes: 28px title, 20px section, 18px question, 16px body, 14px label, 12px metadata
- **Shape:** 12px control radius, 16px card radius, pills only for chips/status
- **Spacing:** 8px base rhythm: 4, 8, 12, 16, 20, 24, 32, 48, 64
- **Motion:** Purposeful 150–250ms transitions; honor `prefers-reduced-motion`

### Navigation: Three Destinations
Today · Study · You — NOT five tabs. Study groups Learn/Practice/Review.

### Quiz Flow Contract (CRITICAL)
- **Practice:** Select → Check answer → Feedback → Next
- **Test/Exam:** Select → Save & next → Submit → Review (correctness HIDDEN until submitted)
- OptionTile must accept a `showResults` bool. Practice mode shows correctness immediately; test mode reveals only on quiz completion.

### Key Files
- Theme: `lib/core/theme/app_theme.dart`, `app_colors.dart`, `tokens.dart`, `components.dart`
- Quiz: `lib/features/quiz/enhanced_quiz_screen.dart`, `option_tile.dart`, `quiz_header.dart`, `quiz_footer.dart`
- Design spec: `design.md`, `design-system/neet-mitos/tokens.light.json`

### Running
```bash
flutter run -d emulator-5554 --debug
```

### Build Notes
- Java 21 at `C:/Users/bamba/apkrev-tools/jdk` (Java 25 breaks Gradle 8.14)
- Android SDK at `C:\Users\bamba\AppData\Local\Android\Sdk`
- Desktop platforms disabled (symlink/Developer Mode issues)
- Debug builds only (no signing key for release)

### Pending Design Tasks (from design.md acceptance checklist)
1. Fix quiz mode distinction (practice shows correctness, test hides until submit)
2. Align MCQ option states to `tokens.light.json` spec
3. Fix timer bar to use semantic colors (not subject accent)
4. Align Today action card to theme tokens (no hardcoded sizes)
5. Verify empty/loading/error/offline states on all screens
