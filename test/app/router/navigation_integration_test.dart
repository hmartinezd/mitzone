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
        if (initialLocation != null)
          routerInitialLocationProvider.overrideWithValue(initialLocation),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
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

      final navBar = find.byType(NavigationBar);

      // Tap Events
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Events')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EventsScreen), findsOneWidget);

      // Tap Matches
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Matches')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MatchesScreen), findsOneWidget);

      // Tap Chat
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Chat')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);

      // Tap Profile
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Profile')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePreviewScreen), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });

    group('Direct Route Tests', () {
      testWidgets('Directly access /app/home', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.home),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);
      });

      testWidgets('Directly access /app/events', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.events),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EventsScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 1);
      });

      testWidgets('Directly access /app/matches', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.matches),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MatchesScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 2);
      });

      testWidgets('Directly access /app/chat', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.chat),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ChatScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 3);
      });

      testWidgets('Directly access /app/profile', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profile),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfilePreviewScreen), findsOneWidget);
        expect(find.byType(MainNavigationShell), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 4);
      });
    });

    group('Responsive and Text Scaling', () {
      testWidgets('Navigation works at 320x480', (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.home),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);

        // Verify only selected label is shown at narrow width (rule < 360)
        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(
          navBar.labelBehavior,
          NavigationDestinationLabelBehavior.onlyShowSelected,
        );

        final navBarFinder = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Events')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Matches')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Chat')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Profile')),
          findsOneWidget,
        );
      });

      testWidgets('Navigation works at 414x896', (tester) async {
        tester.view.physicalSize = const Size(414, 896);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.home),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);

        final navBarFinder = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Events')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Matches')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Chat')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Profile')),
          findsOneWidget,
        );
      });

      testWidgets('Navigation works at 896x414 (Landscape)', (tester) async {
        tester.view.physicalSize = const Size(896, 414);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.home),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);

        final navBarFinder = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Events')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Matches')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Chat')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Profile')),
          findsOneWidget,
        );
      });

      testWidgets('Navigation works at 1024x768 (Tablet)', (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.home),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);

        final navBarFinder = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Events')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Matches')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Chat')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Profile')),
          findsOneWidget,
        );
      });

      testWidgets('Navigation works with 2.0 text scaling', (tester) async {
        onboardingStore.completed = true;
        profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: createTestWidget(initialLocation: AppRoutes.home),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MainNavigationShell), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.selectedIndex, 0);

        final navBarFinder = find.byType(NavigationBar);
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Home')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Events')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Matches')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Chat')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Profile')),
          findsOneWidget,
        );
      });
    });

    testWidgets('Branch state is preserved', (tester) async {
      // Force a small viewport to ensure content overflows and scrolling is possible
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      onboardingStore.completed = true;
      profileRepo.profile = const UserProfile(id: 'id', displayName: 'User');
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.events),
      );
      await tester.pumpAndSettle();

      // EventsScreen content should be scrollable via SingleChildScrollView in MitzonePageBody
      final scrollableFinder = find.byType(Scrollable).first;

      // Scroll down significantly
      await tester.drag(scrollableFinder, const Offset(0, -300));
      await tester.pump();

      // Get current scroll offset
      final scrollPosition = tester
          .state<ScrollableState>(scrollableFinder)
          .position;
      final initialOffset = scrollPosition.pixels;
      expect(initialOffset, greaterThan(0));

      // Switch to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Return to Events
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();
      expect(find.byType(EventsScreen), findsOneWidget);

      // Verify scroll offset is preserved
      final newScrollPosition = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(newScrollPosition.pixels, initialOffset);
    });
  });
}
