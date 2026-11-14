import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/shared/widgets/mitzone_brand.dart';

double contrast(Color a, Color b) {
  final values = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (values.last + .05) / (values.first + .05);
}

void main() {
  test(
    'neutral review theme keeps primary reading/action pairs accessible',
    () {
      final theme = AppTheme.lightTheme;
      final scheme = theme.colorScheme;
      for (final pair in [
        [scheme.onSurface, scheme.surface],
        [scheme.onSurfaceVariant, scheme.surface],
        [scheme.onPrimary, scheme.primary],
        [scheme.onPrimaryContainer, scheme.primaryContainer],
        [scheme.onSecondaryContainer, scheme.secondaryContainer],
      ]) {
        expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
      }
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
        scheme.primary,
      );
    },
  );
  testWidgets('temporary branding renders a title, never the retired logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: MitzoneBrand(showTagline: true)),
      ),
    );
    expect(find.text('Mitzone'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
