import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_empty_state.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: widget),
    );
  }

  group('MitzoneEmptyState Tests', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MitzoneEmptyState(
            title: 'Empty',
            message: 'No items',
            icon: Icons.search,
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
