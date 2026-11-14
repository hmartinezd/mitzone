import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/edit_profile_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_details_screen.dart';

void main() {
  testWidgets('display-name visibility helper supports multiple lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: EditProfileForm(
              profile: UserProfile(id: 'test', displayName: 'Test'),
            ),
          ),
        ),
      ),
    );
    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    final decoration = tester
        .widget<TextField>(find.byType(TextField).first)
        .decoration!;
    expect(decoration.helperText, 'Visible to everyone on Mitzone');
    expect(decoration.helperMaxLines, 3);
    expect(field, isNotNull);
  });

  testWidgets('Bio has one built-in counter and no duplicate helper', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileDetailsForm(
              profile: UserProfile(
                id: 'test',
                displayName: 'Test',
                bio: 'Hello',
              ),
            ),
          ),
        ),
      ),
    );
    final bio = tester.widget<TextField>(find.byType(TextField).first);
    expect(bio.maxLength, 240);
    expect(bio.decoration!.helperText, isNull);
    expect(find.text('5/240'), findsOneWidget);
  });
}
