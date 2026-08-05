import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_button.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: widget),
    );
  }

  group('MitzoneButton Tests', () {
    testWidgets('invokes callback when pressed', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        wrap(MitzoneButton(text: 'Press Me', onPressed: () => pressed = true)),
      );

      await tester.tap(find.text('Press Me'));
      expect(pressed, isTrue);
    });

    testWidgets('does not invoke callback when disabled', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        wrap(
          MitzoneButton(
            text: 'Disabled',
            enabled: false,
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      expect(pressed, isFalse);
    });

    testWidgets('does not invoke callback when loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        wrap(
          MitzoneButton(
            text: 'Loading',
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(CircularProgressIndicator));
      expect(pressed, isFalse);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(MitzoneButton(text: 'Loading', isLoading: true, onPressed: () {})),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('has at least 48px height', (tester) async {
      await tester.pumpWidget(
        wrap(
          Center(
            child: MitzoneButton(text: 'Height Test', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.style?.minimumSize?.resolve({})?.height,
        greaterThanOrEqualTo(48.0),
      );
    });
  });
}
