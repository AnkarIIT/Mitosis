import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'tokens.dart';

/// Adaptive color helpers that resolve to the correct color based on the current theme.
/// Use these instead of hardcoded AppColors.* for theme-aware colors.
class AdaptiveColors {
  const AdaptiveColors._();

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surfaceWarm(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color onSurfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color textTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

  static Color divider(BuildContext context) => Theme.of(context).dividerColor;

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color primaryContainer(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  static Color onPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  static Color warning(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFBBF24)
      : AppColors.warning;

  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF34D399)
      : AppColors.success;

  static Color surfaceContainerHighest(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  static Color outlineVariant(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class AppTheme {
  static TextTheme _textTheme(Color primary, Color subtle) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return Typography.material2021(platform: defaultTargetPlatform).black
        .copyWith(
          displayLarge: TextStyle(
            color: primary,
            fontSize: isIOS ? 34 : 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            color: primary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          displaySmall: TextStyle(
            color: primary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: primary,
            fontSize: isIOS ? 34 : 32,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: primary,
            fontSize: isIOS ? 22 : 28,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: primary,
            fontSize: isIOS ? 20 : 24,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: primary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: primary, fontSize: 18, height: 1.55),
          bodyMedium: TextStyle(
            color: primary,
            fontSize: isIOS ? 17 : 16,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            color: subtle,
            fontSize: isIOS ? 15 : 14,
            height: 1.45,
          ),
          labelLarge: TextStyle(
            color: subtle,
            fontSize: isIOS ? 17 : 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            color: subtle,
            fontSize: isIOS ? 15 : 13,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.brandNavy,
    secondary: Color(0xFF53677F),
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surfaceMuted,
    onSecondaryContainer: Color(0xFF1E2A28),
    tertiary: SubjectColors.biology,
    onTertiary: Colors.white,
    tertiaryContainer: SubjectColors.biologyLight,
    onTertiaryContainer: Color(0xFF064E3B),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.surface,
    onSurface: AppColors.textDark,
    surfaceContainerHighest: AppColors.surfaceWarm,
    onSurfaceVariant: AppColors.textSubtle,
    // Interactive outlines meet 4.5:1 against white; decorative dividers use
    // outlineVariant and never serve as the only control boundary.
    outline: Color(0xFF71817A),
    outlineVariant: AppColors.divider,
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF0F172A),
    inverseSurface: Color(0xFF152024),
    onInverseSurface: AppColors.textLight,
    inversePrimary: AppColors.primaryDark,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.brandNavy,
    primaryContainer: Color(0xFF17483F),
    onPrimaryContainer: Color(0xFFD0EAE2),
    secondary: Color(0xFFC2CDC8),
    onSecondary: Color(0xFF14221E),
    secondaryContainer: Color(0xFF263C35),
    onSecondaryContainer: Color(0xFFE0EAE5),
    tertiary: Color(0xFF34D399),
    onTertiary: Color(0xFF022C22),
    tertiaryContainer: Color(0xFF065F46),
    onTertiaryContainer: Color(0xFFA7F3D0),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textLight,
    surfaceContainerHighest: AppColors.surfaceMutedDark,
    onSurfaceVariant: AppColors.textSubtleDark,
    outline: Color(0xFF81948D),
    outlineVariant: AppColors.dividerDark,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE7EFEB),
    onInverseSurface: Color(0xFF172724),
    inversePrimary: AppColors.primary,
  );

  static ThemeData get lightTheme => _build(_lightScheme, Brightness.light);

  static ThemeData get darkTheme => _build(_darkScheme, Brightness.dark);

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final card = isDark ? AppColors.cardBgDark : AppColors.cardBg;
    final divider = isDark ? AppColors.dividerDark : AppColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? null : 'Roboto',
      fontFamilyFallback: defaultTargetPlatform == TargetPlatform.iOS
          ? null
          : const ['NotoSansDevanagari'],
      cardColor: card,
      dividerColor: divider,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 22 : 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: EdgeInsets.symmetric(
            horizontal: defaultTargetPlatform == TargetPlatform.iOS ? 20 : 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 17 : 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          padding: EdgeInsets.symmetric(
            horizontal: defaultTargetPlatform == TargetPlatform.iOS ? 20 : 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 17 : 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: defaultTargetPlatform == TargetPlatform.iOS ? 17 : 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 24),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceWarm,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceWarm,
        selectedColor: scheme.primary.withValues(alpha: 0.14),
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        elevation: 8,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.cardBgDark : AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: Colors.white),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
        circularTrackColor: scheme.primary.withValues(alpha: 0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outlineVariant;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
