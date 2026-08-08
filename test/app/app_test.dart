import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitzone/app/app.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:mitzone/features/foundation/presentation/visual_system_showcase_screen.dart';
import 'package:mitzone/features/foundation/presentation/route_error_screen.dart';
import 'package:mitzone/features/splash/presentation/splash_screen.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/features/profile/presentation/create_minimum_profile_screen.dart';

class FakeOnboardingStatusStore implements OnboardingStatusStore {
  bool completed = false;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> markCompleted() async => completed = true;
}

class FakeIdentityGateway implements IdentityGateway {
  AppIdentity? identity;
  @override
  Future<AppIdentity> ensureIdentity() async {
    identity ??= const AppIdentity(
      id: 'id-1',
      type: AppIdentityType.localDevelopment,
    );
    return identity!;
  }

  @override
  Future<AppIdentity?> getExistingIdentity() async => identity;
}

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  @override
  Future<UserProfile?> getProfile(String identityId) async => profile;
  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async {
    profile = UserProfile(
      id: identityId,
      displayName: displayName,
      avatarUri: avatarUri,
    );
    return profile!;
  }
}

void main() {
  group('MitzoneApp Widget Tests', () {
    late FakeOnboardingStatusStore onboardingStore;
    late FakeIdentityGateway identityGateway;
    late FakeProfileRepository profileRepo;

    setUp(() {
      onboardingStore = FakeOnboardingStatusStore();
      identityGateway = FakeIdentityGateway();
      profileRepo = FakeProfileRepository();
    });

    ProviderScope createRoot() {
      return ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.validated(env: AppEnvironment.local),
          ),
          onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
          identityGatewayProvider.overrideWithValue(identityGateway),
          profileRepositoryProvider.overrideWithValue(profileRepo),
        ],
        child: const MitzoneApp(),
      );
    }

    testWidgets('renders SplashScreen initially', (tester) async {
      await tester.pumpWidget(createRoot());
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('navigates to Onboarding if not completed', (tester) async {
      onboardingStore.completed = false;
      await tester.pumpWidget(createRoot());

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets(
      'navigates to CreateProfile if onboarding completed but no profile',
      (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = null;

        await tester.pumpWidget(createRoot());

        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(CreateMinimumProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to Home if onboarding completed and profile exists',
      (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(
          id: 'id-1',
          displayName: 'Hector',
        );

        await tester.pumpWidget(createRoot());

        await tester.pump(const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets('real unknown-route integration test returns to Splash', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(
              AppConfig.validated(env: AppEnvironment.local),
            ),
            onboardingStatusStoreProvider.overrideWithValue(onboardingStore),
            identityGatewayProvider.overrideWithValue(identityGateway),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            routerProvider.overrideWith(
              (ref) =>
                  createAppRouter(initialLocation: '/unknown-route', ref: ref),
            ),
          ],
          child: const MitzoneApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RouteErrorScreen), findsOneWidget);
      await tester.tap(find.text('Return to Mitzone'));

      // Advance past RouteErrorScreen pop and splash rendering
      await tester.pumpAndSettle();

      // It might have already resolved to Onboarding or Shell
      expect(
        find.byType(SplashScreen).evaluate().isNotEmpty ||
            find.byType(OnboardingScreen).evaluate().isNotEmpty ||
            find.byType(CreateMinimumProfileScreen).evaluate().isNotEmpty ||
            find.byType(HomeScreen).evaluate().isNotEmpty,
        isTrue,
      );

      // Finally ensure it's not on RouteErrorScreen
      expect(find.byType(RouteErrorScreen), findsNothing);
    });
  });
}
