import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_status_badge.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: widget),
    );
  }

  group('MitzoneStatusBadge Tests', () {
    testWidgets('renders icon and text', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MitzoneStatusBadge(
            text: 'Active',
            status: MitzoneStatus.success,
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
