import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_confirmation_dialog.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  group('MitzoneConfirmationDialog Tests', () {
    testWidgets('confirm returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await MitzoneConfirmationDialog.show(
                    context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Confirm'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await MitzoneConfirmationDialog.show(
                    context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final cancelButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Cancel'),
      );
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
