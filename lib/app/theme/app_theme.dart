import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'mitzone_theme_colors.dart';
import 'kinetic_colors.dart';

class AppTheme {
  /// Neutral canvas with a restrained blue accent, provisional for review.
  /// The dark theme remains available for legacy review and regression tests.
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: KineticColors.primary,
      onPrimary: Colors.white,
      primaryContainer: KineticColors.cyan,
      onPrimaryContainer: Color(0xff19365e),
      secondary: KineticColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: KineticColors.mint,
      onSecondaryContainer: Color(0xff243e61),
      tertiary: Color(0xff795900),
      onTertiary: Colors.white,
      tertiaryContainer: KineticColors.amber,
      onTertiaryContainer: Color(0xff5b4300),
      surface: KineticColors.canvas,
      onSurface: KineticColors.ink,
      surfaceContainer: KineticColors.surface,
      surfaceContainerLow: KineticColors.surfaceLow,
      onSurfaceVariant: KineticColors.inkMuted,
      outline: KineticColors.outline,
      outlineVariant: KineticColors.outlineVariant,
      error: Color(0xffba1a1a),
      onError: Colors.white,
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
    );
    final text = AppTypography.kineticTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: KineticColors.canvas,
      fontFamily: 'PlusJakartaSans',
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: KineticColors.canvas,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: KineticColors.inkMuted),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KineticColors.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KineticColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KineticColors.teal,
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: KineticColors.teal, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KineticColors.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KineticColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KineticColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KineticColors.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: KineticColors.mint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? KineticColors.teal
                : KineticColors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          const IconThemeData(color: KineticColors.inkMuted),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KineticColors.outlineVariant,
        thickness: .5,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xff2a3231),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [
        MitzoneThemeColors(
          brandCyan: KineticColors.cyan,
          brandBlue: KineticColors.teal,
          brandPurple: KineticColors.amber,
          surfaceSubtle: KineticColors.surfaceLow,
          surfaceStrong: Colors.white,
          success: Color(0xff216753),
          successContainer: Color(0xffabf1d6),
          onSuccess: Colors.white,
          onSuccessContainer: Color(0xff002117),
          warning: Color(0xff795900),
          warningContainer: Color(0xffffdf9e),
          onWarning: Colors.white,
          onWarningContainer: Color(0xff261a00),
          info: KineticColors.primary,
          infoContainer: KineticColors.mint,
          onInfo: Colors.white,
          onInfoContainer: Color(0xff19365e),
          focusIndicator: KineticColors.primary,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surfaceElevated,
      onSurfaceVariant: AppColors.textSecondary,
      primary: AppColors.primary,
      onPrimary: Colors.black,
      primaryContainer: AppColors.primary.withValues(alpha: 0.2),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accent.withValues(alpha: 0.2),
      onTertiaryContainer: AppColors.accent,
      error: AppColors.error,
      onError: Colors.black,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.error,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineStrong,
      scrim: AppColors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(AppSpacing.vhu),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(AppSpacing.vhu),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, AppSpacing.vhu),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
        helperStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.error),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusLg),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusXl),
        titleTextStyle: AppTypography.textTheme.headlineSmall,
        contentTextStyle: AppTypography.textTheme.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: AppSpacing.lg,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusMd),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: AppTypography.textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: AppColors.outlineStrong),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusSm),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.outlineStrong;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.surfaceElevated;
        }),
      ),
      extensions: [
        MitzoneThemeColors(
          brandCyan: AppColors.primary,
          brandBlue: AppColors.secondary,
          brandPurple: AppColors.accent,
          surfaceSubtle: AppColors.surfaceSubtle,
          surfaceStrong: AppColors.surfaceElevated,
          success: AppColors.success,
          successContainer: AppColors.successContainer,
          onSuccess: Colors.black,
          onSuccessContainer: AppColors.success,
          warning: AppColors.warning,
          warningContainer: AppColors.warningContainer,
          onWarning: Colors.black,
          onWarningContainer: AppColors.warning,
          info: AppColors.info,
          infoContainer: AppColors.infoContainer,
          onInfo: Colors.white,
          onInfoContainer: AppColors.info,
          focusIndicator: AppColors.focusIndicator,
        ),
      ],
    );
  }
}
