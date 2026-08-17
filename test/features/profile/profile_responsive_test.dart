import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/core/identity/app_identity.dart';
import 'package:mitzone/core/identity/identity_gateway.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_providers.dart';
import 'package:mitzone/features/onboarding/data/onboarding_status_store.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';
import 'package:mitzone/features/profile/data/profile_repository.dart';
import 'package:mitzone/features/profile/domain/user_profile.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/features/profile/presentation/widgets/profile_avatar.dart';

class MockOnboardingStore implements OnboardingStatusStore {
  @override
  Future<bool> isCompleted() async => true;
  @override
  Future<void> markCompleted() async {}
}

class MockIdentityGateway implements IdentityGateway {
  @override
  Future<AppIdentity> ensureIdentity() async =>
      const AppIdentity(id: 'test-id', type: AppIdentityType.localDevelopment);
  @override
  Future<AppIdentity?> getExistingIdentity() async => null;
}

class MockProfileRepository implements ProfileRepository {
  UserProfile? profile = const UserProfile(
    id: 'test-id',
    displayName: 'Hector',
  );

  @override
  Future<UserProfile?> getProfile(String identityId) async => profile;

  @override
  Future<UserProfile> saveMinimumProfile({
    required String identityId,
    required String displayName,
    String? avatarUri,
  }) async => throw UnimplementedError();

  @override
  Future<UserProfile> saveProfile(UserProfile p) async {
    profile = p;
    return p;
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

  Widget createTestWidget({
    String? initialLocation,
    double textScale = 1.0,
    Size size = const Size(800, 600),
  }) {
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
          return MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp.router(routerConfig: router),
          );
        },
      ),
    );
  }

  group('Profile Responsive Matrix', () {
    final viewSizes = [
      const Size(320, 480),
      const Size(414, 896),
      const Size(896, 414),
      const Size(1024, 768),
    ];

    for (final size in viewSizes) {
      testWidgets('Profile Screen layout at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profile),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Hector'), findsOneWidget);
      });

      testWidgets('Edit Profile layout at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileEdit),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Basic Identity'), findsOneWidget);
      });

      testWidgets('Profile Details layout at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.profileDetails),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Connection Goal'), findsOneWidget);
      });

      testWidgets('Settings layout at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(initialLocation: AppRoutes.settings),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Account'), findsOneWidget);
        expect(find.text('Delete account'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Profile Text Scaling 2.0', () {
    testWidgets('Profile with 2.0 text scale keeps later actions usable', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(initialLocation: AppRoutes.profile, textScale: 2.0),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Complete profile'),
        100,
        scrollable: scrollable,
      );
      expect(find.text('14%'), findsOneWidget);
      expect(find.text('Complete profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit Profile with 2.0 text scale remains usable', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: AppRoutes.profileEdit,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Profile Details with 2.0 text scale remains usable', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: AppRoutes.profileDetails,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(find.text('Save Details'), findsOneWidget);
    });

    testWidgets(
      'Account settings with 2.0 text scale keeps deferred actions readable',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialLocation: AppRoutes.settingsAccount,
            textScale: 2.0,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign out'), findsOneWidget);
        expect(find.text('Delete account'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ProfileAvatar Accessibility', () {
    testWidgets('Edit photo target is at least 48x48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(displayName: 'Hector', onEdit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButton = find.bySemanticsLabel('Change profile photo');
      final size = tester.getSize(editButton);

      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });
}
