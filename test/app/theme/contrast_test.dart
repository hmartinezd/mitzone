import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_colors.dart';

void main() {
  group('Theme Contrast Tests', () {
    double calculateContrast(Color color1, Color color2) {
      final lum1 = color1.computeLuminance();
      final lum2 = color2.computeLuminance();
      final brightest = lum1 > lum2 ? lum1 : lum2;
      final darkest = lum1 > lum2 ? lum2 : lum1;
      return (brightest + 0.05) / (darkest + 0.05);
    }

    test('Background and Primary Text contrast >= 4.5:1', () {
      final contrast = calculateContrast(
        AppColors.background,
        AppColors.textPrimary,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: 'Contrast is $contrast',
      );
    });

    test('Surface and Primary Text contrast >= 4.5:1', () {
      final contrast = calculateContrast(
        AppColors.surface,
        AppColors.textPrimary,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: 'Contrast is $contrast',
      );
    });

    test('Surface and Secondary Text contrast >= 4.5:1', () {
      final contrast = calculateContrast(
        AppColors.surface,
        AppColors.textSecondary,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: 'Contrast is $contrast',
      );
    });

    test('Primary Button Background and Foreground contrast >= 3.0:1', () {
      // Primary foreground is black
      final contrast = calculateContrast(AppColors.primary, Colors.black);
      expect(
        contrast,
        greaterThanOrEqualTo(3.0),
        reason: 'Contrast is $contrast',
      );
    });

    test('Error Container and Error Foreground contrast >= 3.0:1', () {
      final contrast = calculateContrast(
        AppColors.errorContainer,
        AppColors.error,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(3.0),
        reason: 'Contrast is $contrast',
      );
    });

    test('Warning Container and Warning Foreground contrast >= 3.0:1', () {
      final contrast = calculateContrast(
        AppColors.warningContainer,
        AppColors.warning,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(3.0),
        reason: 'Contrast is $contrast',
      );
    });

    test('Success Container and Success Foreground contrast >= 3.0:1', () {
      final contrast = calculateContrast(
        AppColors.successContainer,
        AppColors.success,
      );
      expect(
        contrast,
        greaterThanOrEqualTo(3.0),
        reason: 'Contrast is $contrast',
      );
    });
  });
}
