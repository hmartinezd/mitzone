import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/foundation/presentation/entry_failure_screen.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/presentation/create_minimum_profile_screen.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/events/presentation/events_screen.dart';
import 'package:mitzone/features/matches/presentation/matches_screen.dart';
import 'package:mitzone/features/chat/presentation/chat_screen.dart';
import 'package:mitzone/features/profile/presentation/profile_preview_screen.dart';
import 'package:mitzone/features/navigation/presentation/main_navigation_shell.dart';

class MockOnboardingStore implements OnboardingStatusStore {
  bool completed = false;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async => completed = true;
}

class MockIdentityGateway implements IdentityGateway {
  bool shouldFail = false;
  @override
  Future<AppIdentity> ensureIdentity() async {
    if (shouldFail) throw Exception('Failure');
    return const AppIdentity(
      id: 'test-id',
      type: AppIdentityType.localDevelopment,
    );
  }

  @override
  Future<AppIdentity?> getExistingIdentity() async => null;
}

class MockProfileRepository implements ProfileRepository {
  UserProfile? profile;
  @override
  Future<UserProfile?> getProfile(String identityId) async => profile;
  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    final newProfile = UserProfile(
      id: identityId,
      displayName: displayName,
      avatarUri: avatarUri,
    );
    profile = newProfile;
    return newProfile;
  }
}

void main() {
  late MockOnboardingStore onboardingStore;
  late MockIdentityGateway identityGateway;
  late MockProfileRepository profileRepo;

  setUp(() {
    onboardingStore = MockOnboardingStore();
    identityGateway = MockIdentityGateway();
    profileRepo = MockProfileRepository();
  });

  Widget createTestWidget({String? initialLocation}) {
    return ProviderScope(
      overrides: [
        onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
        identityGatewayProvider.overrideWithValue(identityGateway),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          // We need to bridge Ref to WidgetRef if we want to use the factory.
          // Or we can just use the provider.
          final router = ref.watch(routerProvider);
          if (initialLocation != null && initialLocation != AppRoutes.splash) {
            // This is a hack for tests to force initial location if not splash
            // since routerProvider uses splash by default.
            // For real integration we should probably test from splash.
          }
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  group('Navigation Integration', () {
    testWidgets('Splash -> Onboarding when not completed', (tester) async {
      onboardingStore.completed = false;
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets(
      'Splash -> Create Profile when onboarding done but no profile',
      (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = null;
        await tester.pumpWidget(createTestWidget());

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
      },
    );

    testWidgets('Splash -> Home when everything ready', (tester) async {
      onboardingStore.completed = true;
      profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
      await tester.pumpWidget(createTestWidget());

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsOneWidget);
    });

    testWidgets('Splash -> Entry Failure on critical error', (tester) async {
      onboardingStore.completed = true;
      identityGateway.shouldFail = true;
      await tester.pumpWidget(createTestWidget());

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(EntryFailureScreen), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('Entry Failure "Try again" returns to Splash', (tester) async {
      onboardingStore.completed = true;
      identityGateway.shouldFail = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(EntryFailureScreen), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);

      // Clear splash timers
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Main Navigation tabs work', (tester) async {
      onboardingStore.completed = true;
      profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap Events
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();
      expect(find.byType(EventsScreen), findsOneWidget);

      // Tap Matches
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchesScreen), findsOneWidget);

      // Tap Chat
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePreviewScreen), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });
  });
}
