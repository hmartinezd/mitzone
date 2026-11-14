import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/presentation/widgets/profile_tags_field.dart';

void main() {
  testWidgets('keeps existing tags and unfinished custom entry in save value', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Travel');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: ProfileTagsField(
              controller: controller,
              label: 'Interests',
              singular: 'interest',
              fieldKey: const Key('tags'),
              suggestions: const ['Music'],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('tags')), 'Cycling');
    expect(controller.text, 'Travel, Cycling');
    await tester.tap(find.byTooltip('Add interest'));
    await tester.pump();
    expect(find.widgetWithText(InputChip, 'Cycling'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Travel'));
    await tester.pump();
    expect(controller.text, 'Cycling');
    await tester.tap(find.widgetWithText(ActionChip, 'Music'));
    await tester.pump();
    expect(controller.text, 'Cycling, Music');
  });
}
