import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'kinetic_colors.dart';

class AppTypography {
  static TextTheme get valinorTextTheme {
    final base = textTheme.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: const Color(0xff1a1c1a),
      displayColor: const Color(0xff1a1c1a),
    );
    TextStyle heading(double size, double line, FontWeight weight) => TextStyle(
      fontFamily: 'EBGaramond',
      fontSize: size,
      height: line / size,
      letterSpacing: -size * .01,
      fontWeight: weight,
      color: const Color(0xff1a1c1a),
    );
    return base.copyWith(
      displayLarge: heading(48, 56, FontWeight.w400),
      displayMedium: heading(40, 48, FontWeight.w400),
      displaySmall: heading(36, 44, FontWeight.w400),
      headlineLarge: heading(36, 44, FontWeight.w400),
      headlineMedium: heading(30, 38, FontWeight.w500),
      headlineSmall: heading(28, 36, FontWeight.w400),
      titleLarge: heading(22, 30, FontWeight.w500),
      titleMedium: heading(18, 26, FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.6,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        height: 20 / 13,
        letterSpacing: 0,
        color: const Color(0xff466274),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.4,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.4,
        letterSpacing: .2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.4,
        letterSpacing: .2,
      ),
    );
  }

  static TextTheme get kineticTextTheme {
    final base = textTheme.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: KineticColors.ink,
      displayColor: KineticColors.ink,
    );
    TextStyle heading(double size, double line, FontWeight weight) => TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: size,
      height: line / size,
      letterSpacing: -size * .01,
      fontWeight: weight,
      color: KineticColors.ink,
    );
    return base.copyWith(
      headlineLarge: heading(32, 40, FontWeight.w600),
      headlineMedium: heading(26, 34, FontWeight.w600),
      headlineSmall: heading(24, 32, FontWeight.w600),
      titleLarge: heading(20, 28, FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: .07,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.5,
        color: KineticColors.inkMuted,
      ),
    );
  }

  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }
}
