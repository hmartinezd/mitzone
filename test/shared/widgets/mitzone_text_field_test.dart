import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/shared/widgets/mitzone_text_field.dart';
import 'package:mitzone/app/theme/app_theme.dart';

void main() {
  Widget wrap(Widget widget) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: widget),
    );
  }

  group('MitzoneTextField Tests', () {
    testWidgets('text entry works', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(MitzoneTextField(controller: controller)));

      await tester.enterText(find.byType(TextFormField), 'Hello Mitzone');
      expect(controller.text, 'Hello Mitzone');
    });

    testWidgets('error text is displayed', (tester) async {
      await tester.pumpWidget(
        wrap(const MitzoneTextField(errorText: 'Required field')),
      );

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('disabled field is not editable', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        wrap(MitzoneTextField(controller: controller, enabled: false)),
      );

      await tester.enterText(find.byType(TextFormField), 'Should not work');
      expect(controller.text, '');
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MitzoneTextField(obscureText: true, showObscureToggle: true),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final updatedTextField = tester.widget<TextField>(find.byType(TextField));
      expect(updatedTextField.obscureText, isFalse);
    });
  });
}
