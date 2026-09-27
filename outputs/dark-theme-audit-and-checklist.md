# Dark Theme Audit & Implementation Checklist
## NEET Mitos Flutter App

---

## 1. Current State Assessment

### What Exists
- **Light & Dark themes defined** in `lib/core/theme/app_theme.dart`
- **Material 3 enabled** (`useMaterial3: true`)
- **Theme persistence** via `SharedPreferences` in `ThemeNotifier`
- **AdaptiveColors helper** in `app_theme.dart` for theme-aware color access
- **Dark color tokens** defined in `app_colors.dart` (`backgroundDark`, `surfaceDark`, `cardBgDark`, `textLight`, `textSubtleDark`, `dividerDark`)
- **System UI overlay** set to light in dark theme (`SystemUiOverlayStyle.light`)

### Current Architecture
```
main.dart
  └─ MaterialApp.router
       ├─ theme: AppTheme.lightTheme
       ├─ darkTheme: AppTheme.darkTheme
       └─ themeMode: ref.watch(themeProvider)
```

---

## 2. Ideal Dark Theme Behavior

A properly implemented dark theme should make **every pixel** of the app adapt when toggled. Nothing should be "stuck" in light mode.

### Core Principles
1. **No hardcoded `Colors.white` / `Colors.black`** in screen/widget code — always use theme-aware colors
2. **No hardcoded `Color(0xFF...)`** unless it's a brand color that works in both modes
3. **All surfaces** (cards, containers, dialogs, bottom sheets) use `Theme.of(context).colorScheme.surface*`
4. **All text** uses `Theme.of(context).colorScheme.onSurface*`
5. **All icons/images** have sufficient contrast in both modes
6. **Elevation/shadows** adapt — dark mode uses less shadow, more surface tint
7. **System UI** (status bar, navigation bar) adapts icons contrast
8. **Images/assets** either have dark variants or use `ColorFiltered` / `BlendMode`
9. **Semantic colors** (error, success, warning) remain recognizable but adapt saturation for dark backgrounds
10. **Component states** (hover, pressed, focused, disabled) are visible in both modes

---

## 3. Comprehensive Checklist

### 3.1 Theme Setup & Architecture
- [ ] `MaterialApp` has both `theme` and `darkTheme` defined
- [ ] `themeMode` is reactive (provider/riverpod/state management)
- [ ] Theme choice persists across app restarts (`SharedPreferences` / secure storage)
- [ ] `ThemeMode.system` is supported OR user can choose light/dark explicitly
- [ ] System theme changes are detected when in `system` mode
- [ ] `DynamicColor` / `MediaQuery.platformBrightnessOf` used correctly if needed

### 3.2 Color System
- [ ] **Primary brand colors** work on both light & dark backgrounds
- [ ] **Surface colors** follow Material 3 surface tiers (surface, surfaceContainer, surfaceContainerHighest)
- [ ] **On-surface colors** have WCAG AA contrast (4.5:1 for body text)
- [ ] **Outline/border colors** are visible in both modes (not too faint in dark, not too strong in light)
- [ ] **Error/success/warning** colors are distinguishable in dark mode
- [ ] **No pure black (`#000000`)** as background — use very dark gray (`#0F1115` or similar)
- [ ] **No pure white (`#FFFFFF`)** as text — use slightly off-white (`#F1F3F7` or similar) to reduce eye strain

### 3.3 Typography
- [ ] All text colors come from `colorScheme.onSurface`, `onSurfaceVariant`, `primary`, etc.
- [ ] **Display/headline** text uses high-emphasis color
- [ ] **Body text** uses medium-emphasis color
- [ ] **Caption/label** text uses low-emphasis color (still readable)
- [ ] Font weights remain consistent across modes
- [ ] Text scaling works in both modes

### 3.4 Components & Widgets
- [ ] **Cards/Containers**: Background adapts, border adapts
- [ ] **Buttons**: Primary, secondary, outlined, text buttons all work in both modes
- [ ] **Input fields**: Fill color, border, hint text, label text, error text adapt
- [ ] **FAB (FloatingActionButton)**: Container color, icon color, shadow adapt
- [ ] **Navigation Bar**: Background, indicator, labels, icons adapt
- [ ] **Bottom Sheets**: Background, handle color, content adapt
- [ ] **Dialogs**: Background, title, content, actions adapt
- [ ] **SnackBars**: Background, content text, action text adapt
- [ ] **Chips**: Background, selected state, label, icon adapt
- [ ] **Switches/Checkboxes/Radios**: Track, thumb, checkmark, border adapt
- [ ] **Sliders**: Track, thumb, value indicator adapt
- [ ] **Progress indicators**: Background, value color adapt
- [ ] **Lists/Tiles**: Background, title, subtitle, trailing, leading icons adapt
- [ ] **Dividers**: Color adapt (not too faint in dark)
- [ ] **Tabs**: Background, indicator, label, icon adapt

### 3.5 Images & Media
- [ ] **Logo/icons** have dark variants or use adaptive color
- [ ] **Illustrations** either have dark variants or are desaturated for dark mode
- [ ] **Photos/images** look good on dark backgrounds (consider adding subtle border or shadow)
- [ ] **QR codes / diagrams** remain scannable in dark mode
- [ ] **Video players** controls adapt

### 3.6 Elevation & Depth
- [ ] **Card elevation** uses surface tint in dark mode instead of heavy shadows
- [ ] **App bar elevation** adapts
- [ ] **Navigation bar elevation** adapts
- [ ] **Modal surfaces** (dialogs, bottom sheets) have proper elevation

### 3.7 System UI
- [ ] **Status bar icons** adapt (light icons on dark bg, dark icons on light bg)
- [ ] **Navigation bar** (Android) buttons adapt
- [ ] **Keyboard toolbar** colors adapt (if customized)

### 3.8 Edge Cases & Polish
- [ ] **Splash screen** adapts
- [ ] **Onboarding screens** adapt
- [ ] **Empty states** illustrations/text adapt
- [ ] **Error states** adapt
- [ ] **Loading states** (shimmer, spinners) adapt
- [ ] **Selection/highlight states** adapt
- [ ] **Web links** (underline color) adapt
- [ ] **Disabled states** are visible but not jarring

### 3.9 Testing
- [ ] Test on **OLED** (pure black backgrounds)
- [ ] Test on **LCD** (dark gray backgrounds)
- [ ] Test with **system brightness** changes
- [ ] Test **high contrast** mode on Android
- [ ] Test **accessibility** (screen reader + dark mode)
- [ ] Test **screenshot sharing** doesn't reveal hardcoded colors

---

## 4. Specific Issues Found in NEET Mitos

### 4.1 Critical — Auth Screen (`auth_screen.dart`)
**Problem**: The auth screen has a gradient background with `AppColors.primary`. All text, icons, and inputs inside use **hardcoded `Colors.white`**.

| Element | Current | Issue |
|---------|---------|-------|
| Title text | `Colors.white` | Should use `AppColors.textLight` or adaptive |
| Body text | `Colors.white.withValues(alpha: 0.8)` | Should use theme-aware |
| Input text | `Colors.white` | Should use theme-aware |
| Input hint | `Colors.white.withValues(alpha: 0.7)` | Should use theme-aware |
| Input prefix icon | `Colors.white70` | Should use theme-aware |
| Input fill | `Colors.white.withValues(alpha: 0.1)` | Should use theme-aware |
| Input border | `Colors.white.withValues(alpha: 0.2)` | Should use theme-aware |
| Checkbox | Hardcoded white | Should adapt |
| Google button | `Colors.white` | Should adapt |

**Impact**: HIGH — Login/signup is broken in dark mode

### 4.2 Critical — Home Tab (`home_tab.dart`)
**Problem**: Extensive use of `Colors.white` in cards, subject tiles, progress bars, and stats. Also has hardcoded `Colors.grey.shade300` and `Colors.grey.shade100` for shimmer.

| Element | Current | Issue |
|---------|---------|-------|
| Subject card icons | `Colors.white` | Should use subject color or adaptive |
| Subject card text | `Colors.white` | Should use adaptive |
| Progress bars | `Colors.white`, `Colors.white24` | Should use theme-aware |
| Profile avatar | `Colors.white` background | Should adapt |
| Daily goal card | `Colors.white` background | Should adapt |
| Shimmer skeleton | `Colors.grey.shade300/100` | Should use dark/light variants |

**Impact**: HIGH — Home screen is unreadable in dark mode

### 4.3 Critical — App Card Widget (`app_card.dart`)
**Problem**: Uses `Colors.black` for shadow which is invisible in dark mode. Also uses `Colors.white12` for dark border which may not be visible enough.

| Line | Current | Issue |
|------|---------|-------|
| 37-38 | `Colors.black.withValues(alpha: 0.05)` shadow | Invisible in dark mode |
| 44 | `Colors.black.withValues(alpha: 0.03)` shadow | Invisible in dark mode |

**Impact**: MEDIUM — Cards lose depth definition in dark mode

### 4.4 Medium — App Button Widget (`app_button.dart`)
**Problem**: Default foreground is `Colors.white` which won't adapt if button background changes.

### 4.5 Medium — Error Book Screen (`error_book_screen.dart`)
**Problem**: Hardcoded warm beige background `Color(0xFFFDFBF7)` which clashes with dark theme.

### 4.6 Medium — DPP Screens (`dpp_screen.dart`, `dpp_attempt_screen.dart`)
**Problem**: Hardcoded `Colors.red`, `Colors.orange`, `Colors.green`, `Colors.grey[300]` for status indicators.

### 4.7 Medium — CBT Screens (`cbt_test_screen.dart`, `cbt_result_screen.dart`)
**Problem**: Hardcoded `Colors.red`, `Colors.orange`, `Colors.white` for flags, results, and markers.

### 4.8 Medium — Flashcard Screens
**Problem**: Hardcoded `Colors.white` for card backgrounds and controls.

### 4.9 Low — Router Splash (`app_router.dart`)
**Problem**: Loading indicator in splash has hardcoded colors.

### 4.10 Low — Components (`components.dart`)
**Problem**: `MitosActionButton` filled variant uses `Colors.white` foreground.

### 4.11 Low — Onboarding Screens
**Problem**: `onboarding_screen.dart` and `batch_onboarding_screen.dart` have hardcoded `Colors.purple`, `Colors.blue`, `Colors.green` backgrounds.

### 4.12 Low — Model Colors (`achievement_model.dart`)
**Problem**: Hardcoded `Colors.green`, `Colors.teal`, `Colors.blue`, etc. for achievement badges. These are semantic enough but should ideally use theme-aware variants.

---

## 5. Recommended Fixes

### 5.1 Immediate Actions (Critical)
1. **Auth Screen**: Replace all `Colors.white` with `AppColors.textLight` or `AdaptiveColors.textPrimary(context)`
2. **Home Tab**: Replace all hardcoded white colors with theme-aware alternatives
3. **App Card**: Use `Theme.of(context).colorScheme.shadow` instead of `Colors.black`

### 5.2 Short-term (Medium Priority)
1. **DPP/CBT/Error screens**: Use `AppColors.error`, `AppColors.success`, `AppColors.warning` instead of raw `Colors.red/green/orange`
2. **Flashcard screens**: Use `AdaptiveColors.cardBackground(context)` instead of `Colors.white`
3. **Shimmer skeletons**: Detect theme and use appropriate base/highlight colors

### 5.3 Long-term (Low Priority / Polish)
1. **Onboarding**: Consider adaptive backgrounds or at least ensure text contrast
2. **Achievement badges**: Consider using theme-aware semantic colors
3. **Router splash**: Use theme-aware colors

### 5.4 Systemic Improvements
1. **Create a lint rule** or script to flag `Colors.white`, `Colors.black`, and hardcoded `Color(0xFF...)` outside `app_colors.dart`, `app_theme.dart`, and `tokens.dart`
2. **Add `AdaptiveColors` coverage** — ensure every screen uses it consistently
3. **Add dark mode to CI** — run flutter analyze + widget tests in dark mode
4. **Add golden tests** for both light and dark themes

---

## 6. How to Audit Your Own App

Run these commands to find hardcoded colors:

```bash
# Find all hardcoded Colors.white/black outside theme files
grep -rn "Colors\.white\|Colors\.black" lib/ --include="*.dart" | \
  grep -v "AppColors\.\|AdaptiveColors\.\|app_theme\|app_colors"

# Find all hardcoded Color(0xFF...) outside theme files
grep -rn "Color(0xFF" lib/ --include="*.dart" | \
  grep -v "AppColors\.\|tokens\.dart\|app_colors\.dart\|app_theme\.dart"

# Find all hardcoded background colors
grep -rn "backgroundColor:" lib/ --include="*.dart" | \
  grep -v "AppColors\.\|AdaptiveColors\.\|Theme.of"

# Find all BoxShadow with hardcoded colors
grep -rn "BoxShadow" lib/ --include="*.dart" | \
  grep -v "AdaptiveColors\|Theme.of"
```

---

## 7. References

- [Flutter Dark Mode Complete Guide](https://flutterstudio.dev/blog/flutter-dark-mode-guide.html)
- [Adaptive Theming Guide - RydMike](https://rydmike.com/blog_adaptive_theming_guide.html)
- [Flutter Themes Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [Material 3 Migration](https://github.com/flutter/website/blob/main/sites/docs/src/content/release/breaking-changes/material-3-migration.md)

---

*Generated: 2025*
*Project: NEET Mitos*
*Working Directory: C:/Users/ankar/neet_mitos*
