import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_feedback_banner.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: widget),
    );
  }

  group('MitzoneFeedbackBanner Tests', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MitzoneFeedbackBanner(
            title: 'Error Title',
            message: 'Something went wrong',
            type: MitzoneFeedbackType.error,
          ),
        ),
      );

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('dismiss callback works', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        wrap(
          MitzoneFeedbackBanner(
            title: 'Dismissible',
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });
  });
}
