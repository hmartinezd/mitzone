import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/profile_screen.dart';

void main() {
  Widget profileWidget({
    required UserProfile profile,
    required Future<Set<String>> Function(Ref ref) loadActivity,
  }) => ProviderScope(
    retry: (_, _) => null,
    overrides: [
      currentProfileProvider.overrideWith((ref) async => profile),
      joinedEventIdsProvider.overrideWith(loadActivity),
    ],
    child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
  );

  testWidgets('renders populated profile content and joined activity', (
    tester,
  ) async {
    const profile = UserProfile(
      id: 'profile-id',
      displayName: 'Hector Martinez',
      avatarUri: '/avatar.png',
      city: 'Tampa, FL',
      bio: 'Interested in technology and shared experiences.',
      interests: ['Technology', 'Travel'],
      languages: ['Spanish', 'English'],
      connectionGoal: ConnectionGoal.both,
    );

    await tester.pumpWidget(
      profileWidget(
        profile: profile,
        loadActivity: (_) async => {'tech-mixer-2026', 'morning-yoga'},
      ),
    );
    await tester.pumpAndSettle();

    for (final text in [
      'Hector Martinez',
      'Tampa, FL',
      'Social + Professional',
      'Interested in technology and shared experiences.',
      'Technology',
      'Travel',
      'Spanish',
      'English',
      '100%',
      'Joined events',
      '2',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('Complete profile'), findsNothing);
    expect(find.textContaining('Your profile is complete'), findsOneWidget);
  });

  testWidgets(
    'minimum profile uses progressive empty states without fake data',
    (tester) async {
      await tester.pumpWidget(
        profileWidget(
          profile: const UserProfile(id: 'profile-id', displayName: 'Hector'),
          loadActivity: (_) async => {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hector'), findsOneWidget);
      expect(find.text('14%'), findsOneWidget);
      expect(find.text('Add bio'), findsOneWidget);
      expect(find.text('Add interests'), findsOneWidget);
      expect(find.text('Add languages'), findsOneWidget);
      expect(find.text('Complete profile'), findsOneWidget);
      expect(find.text('Not added yet'), findsNothing);
      expect(find.text('Joined events'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets('activity loading does not hide profile', (tester) async {
    final activity = Completer<Set<String>>();
    await tester.pumpWidget(
      profileWidget(
        profile: const UserProfile(id: 'profile-id', displayName: 'Hector'),
        loadActivity: (_) => activity.future,
      ),
    );
    await tester.pump();

    expect(find.text('Hector'), findsOneWidget);
    expect(find.text('Loading your activity…'), findsOneWidget);
  });

  testWidgets('activity error retries only activity and keeps profile usable', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      profileWidget(
        profile: const UserProfile(id: 'profile-id', displayName: 'Hector'),
        loadActivity: (_) async {
          attempts++;
          if (attempts == 1) throw Exception('failed');
          return {'tech-mixer-2026'};
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hector'), findsOneWidget);
    expect(find.text("We couldn't load your activity."), findsOneWidget);

    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Joined events'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
