import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/app/theme/mitzone_theme_colors.dart';

void main() {
  group('MitzoneThemeColors', () {
    test('is registered in AppTheme', () {
      final theme = AppTheme.darkTheme;
      final mitzoneColors = theme.extension<MitzoneThemeColors>();
      expect(mitzoneColors, isNotNull);
    });

    test('exposes all required semantic roles', () {
      final theme = AppTheme.darkTheme;
      final mitzoneColors = theme.extension<MitzoneThemeColors>()!;

      expect(mitzoneColors.brandCyan, isA<Color>());
      expect(mitzoneColors.brandBlue, isA<Color>());
      expect(mitzoneColors.brandPurple, isA<Color>());
      expect(mitzoneColors.success, isA<Color>());
      expect(mitzoneColors.warning, isA<Color>());
      expect(mitzoneColors.info, isA<Color>());
      expect(mitzoneColors.successContainer, isA<Color>());
      expect(mitzoneColors.warningContainer, isA<Color>());
      expect(mitzoneColors.infoContainer, isA<Color>());
      expect(mitzoneColors.focusIndicator, isA<Color>());
    });

    test('error roles use ColorScheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.error, isA<Color>());
      expect(theme.colorScheme.errorContainer, isA<Color>());
      expect(theme.colorScheme.onError, isA<Color>());
      expect(theme.colorScheme.onErrorContainer, isA<Color>());
    });

    test('copyWith works correctly', () {
      final theme = AppTheme.darkTheme;
      final mitzoneColors = theme.extension<MitzoneThemeColors>()!;
      final updated = mitzoneColors.copyWith(brandCyan: Colors.red);
      expect(updated.brandCyan, Colors.red);
      expect(updated.brandBlue, mitzoneColors.brandBlue);
    });

    test('lerp works correctly', () {
      final theme = AppTheme.darkTheme;
      final mitzoneColors = theme.extension<MitzoneThemeColors>()!;
      final other = mitzoneColors.copyWith(brandCyan: Colors.white);
      final lerped = mitzoneColors.lerp(other, 0.5);
      expect(
        lerped.brandCyan,
        Color.lerp(mitzoneColors.brandCyan, Colors.white, 0.5),
      );
    });
  });
}
