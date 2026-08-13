import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/edit_profile_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_details_screen.dart';
import 'package:mitzone/shared/widgets/mitzone_loading_indicator.dart';

void main() {
  const profile = UserProfile(id: 'test-id', displayName: 'Hector');

  Widget createWidget({
    required String location,
    required Future<UserProfile?> Function(Ref ref) loadProfile,
  }) {
    return ProviderScope(
      retry: (_, _) => null,
      overrides: [
        currentProfileProvider.overrideWith(loadProfile),
        routerInitialLocationProvider.overrideWithValue(location),
      ],
      child: Consumer(
        builder: (context, ref, _) =>
            MaterialApp.router(routerConfig: ref.watch(routerProvider)),
      ),
    );
  }

  final screens = <({String route, String title, Type form})>[
    (
      route: AppRoutes.profileEdit,
      title: 'Edit Profile',
      form: EditProfileForm,
    ),
    (
      route: AppRoutes.profileDetails,
      title: 'Profile Details',
      form: ProfileDetailsForm,
    ),
  ];

  for (final screen in screens) {
    group('${screen.title} async states', () {
      testWidgets('loading keeps title, Back, and loading indicator', (
        tester,
      ) async {
        final completer = Completer<UserProfile?>();
        await tester.pumpWidget(
          createWidget(
            location: screen.route,
            loadProfile: (_) => completer.future,
          ),
        );
        await tester.pump();

        expect(find.text(screen.title), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.byType(MitzoneLoadingIndicator), findsOneWidget);
        expect(find.text('Your profile could not be found.'), findsNothing);
      });

      testWidgets('success renders the initialized form', (tester) async {
        await tester.pumpWidget(
          createWidget(
            location: screen.route,
            loadProfile: (_) async => profile,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(screen.form), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
      });

      testWidgets('missing profile offers controlled recovery', (tester) async {
        await tester.pumpWidget(
          createWidget(location: screen.route, loadProfile: (_) async => null),
        );
        await tester.pumpAndSettle();

        expect(find.text(screen.title), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.text('Your profile could not be found.'), findsOneWidget);
        expect(find.text('Finish your profile'), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('error keeps Back and retry reaches success', (tester) async {
        var attempts = 0;
        await tester.pumpWidget(
          createWidget(
            location: screen.route,
            loadProfile: (_) async {
              attempts++;
              if (attempts == 1) throw Exception('load failed');
              return profile;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(screen.title), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.textContaining("We couldn't load"), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(attempts, 2);
        expect(find.byType(screen.form), findsOneWidget);
      });
    });
  }
}
