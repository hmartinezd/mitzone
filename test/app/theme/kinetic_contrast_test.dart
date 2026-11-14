import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/shared/widgets/mitzone_button.dart';

void main() {
  double ratio(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
  }

  test('beta light theme supports readable text and action labels', () {
    final theme = AppTheme.lightTheme;
    expect(theme.brightness, Brightness.light);
    final s = theme.colorScheme;
    for (final pair in [
      (s.surface, s.onSurface),
      (s.surfaceContainer, s.onSurfaceVariant),
      (s.primaryContainer, s.onPrimaryContainer),
      (s.secondaryContainer, s.onSecondaryContainer),
      (s.errorContainer, s.onErrorContainer),
    ]) {
      expect(ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
    }
    final button = theme.filledButtonTheme.style!;
    expect(
      ratio(
        button.backgroundColor!.resolve({})!,
        button.foregroundColor!.resolve({})!,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
  testWidgets('destructive actions retain their danger role under beta theme', (
    tester,
  ) async {
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: MitzoneButton(
            text: 'Delete account',
            onPressed: () {},
            variant: MitzoneButtonVariant.destructive,
          ),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), theme.colorScheme.error);
    expect(
      button.style!.foregroundColor!.resolve({}),
      theme.colorScheme.onError,
    );
  });
}
