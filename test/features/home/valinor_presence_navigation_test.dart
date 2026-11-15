import 'package:mitzone/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/app/router/app_router.dart';
import 'package:mitzone/app/router/app_routes.dart';
import 'package:mitzone/app/theme/app_theme.dart';
import 'package:mitzone/core/auth/auth_providers.dart';
import 'package:mitzone/core/config/app_config.dart';
import 'package:mitzone/core/config/app_environment.dart';
import 'package:mitzone/core/identity/current_user_provider.dart';
import 'package:mitzone/core/identity/identity_providers.dart';
import 'package:mitzone/core/providers/core_providers.dart';
import 'package:mitzone/core/storage/storage_providers.dart';
import 'package:mitzone/features/chat/data/chat_providers.dart';
import 'package:mitzone/features/connections/data/connection_providers.dart';
import 'package:mitzone/features/discovery/data/discovery_providers.dart';
import 'package:mitzone/features/encounters/data/encounter_providers.dart';
import 'package:mitzone/features/encounters/data/foreground_presence_service.dart';
import 'package:mitzone/features/encounters/data/presence_providers.dart';
import 'package:mitzone/features/encounters/domain/location_observation.dart';
import 'package:mitzone/features/encounters/presentation/foreground_presence_card.dart';
import 'package:mitzone/features/events/data/event_providers.dart';
import 'package:mitzone/features/events/data/demo_events.dart';
import 'package:mitzone/features/profile/data/profile_providers.dart';

import '../../support/memory_local_storage.dart';
import '../events/event_experience_test.dart'
    show TestIdentityGateway, TestParticipationRepository;

// Offline fixtures exercise the real router and presence service, not Supabase.
class _Location implements LocationObservationSource {
  int calls = 0;
  @override
  Future<LocationObservation> observeForeground() async {
    calls++;
    return LocationObservation(
      latitude: 12,
      longitude: 34,
      observedAt: DateTime.now().toUtc(),
    );
  }
}

class _Gateway
    implements ForegroundPresenceGateway, ForegroundPresenceRefreshGateway {
  int records = 0;
  int refreshes = 0;
  int stops = 0;
  @override
  Future<DateTime> recordForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    records++;
    return DateTime.now().toUtc().add(const Duration(minutes: 30));
  }

  @override
  Future<DateTime> refreshForegroundPresence({
    required double latitude,
    required double longitude,
  }) async {
    refreshes++;
    return DateTime.now().toUtc().add(const Duration(minutes: 30));
  }

  @override
  Future<void> stopForegroundPresence() async => stops++;
}

void main() {
  for (final startOnHome in [true, false]) {
    testWidgets(
      '${startOnHome ? 'Home to detail' : 'Detail to Home'} Stop survives retained-branch navigation without duplicate collection',
      (tester) async {
        final location = _Location();
        final gateway = _Gateway();
        final participation = TestParticipationRepository();
        final detail = AppRoutes.eventDetails('tech-mixer-2026');
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig.validated(env: AppEnvironment.local),
              ),
              productionModeProvider.overrideWithValue(true),
              currentUserIdProvider.overrideWithValue(
                const AsyncValue.data('identity-a'),
              ),
              localStorageProvider.overrideWithValue(MemoryLocalStorage()),
              identityGatewayProvider.overrideWithValue(TestIdentityGateway()),
              foregroundPresenceServiceProvider.overrideWithValue(
                ForegroundPresenceService(
                  location: location,
                  presence: gateway,
                ),
              ),
              eventCatalogProvider.overrideWithValue(const DemoEventCatalog()),
              nearbyEventsProvider.overrideWithValue(
                AsyncValue.data(demoEvents),
              ),
              eventCheckInsProvider.overrideWithValue(
                const AsyncValue.data([]),
              ),
              eventParticipationRepositoryProvider.overrideWithValue(
                participation,
              ),
              currentProfileProvider.overrideWithValue(
                const AsyncValue.data(null),
              ),
              homeDiscoveryInterestsProvider.overrideWithValue(
                const <String>{},
              ),
              nearbyDiscoveryProvider(
                const <String>{},
              ).overrideWithValue(const AsyncValue.data([])),
              encountersForCurrentUserProvider.overrideWithValue(
                const AsyncValue.data([]),
              ),
              incomingConnectionRequestsProvider.overrideWithValue(
                const AsyncValue.data([]),
              ),
              connectionsProvider.overrideWithValue(const AsyncValue.data([])),
              chatConversationsProvider.overrideWithValue(
                const AsyncValue.data([]),
              ),
              routerInitialLocationProvider.overrideWithValue(
                startOnHome ? AppRoutes.home : detail,
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp.router(
                theme: AppTheme.lightTheme,
                routerConfig: ref.watch(routerProvider),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ForegroundPresenceCard)),
        );
        final router = container.read(routerProvider);
        Future<void> tap(String label) async {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        void oneCard() => expect(
          find.byType(ForegroundPresenceCard, skipOffstage: false),
          findsOneWidget,
        );
        oneCard();
        expect(location.calls, 0);
        await tap('Activate presence');
        await tap('Continue');
        expect(gateway.records, 1);
        expect(location.calls, 1);
        router.go(startOnHome ? detail : AppRoutes.home);
        await tester.pumpAndSettle();
        oneCard();
        expect(find.text('Resume presence'), findsOneWidget);
        await tester.pump(const Duration(minutes: 2));
        expect(
          location.calls,
          1,
          reason: 'Restoration must not restart collection',
        );
        expect(gateway.refreshes, 0);
        await tap('Stop');
        expect(gateway.stops, 1);
        router.go(startOnHome ? AppRoutes.home : detail);
        await tester.pumpAndSettle();
        oneCard();
        expect(find.text('Resume presence'), findsNothing);
        expect(find.text('Activate presence'), findsOneWidget);
        await tester.pump(const Duration(minutes: 2));
        expect(location.calls, 1);
        // Attendance intent is independent of presence on the actual detail route.
        router.go(detail);
        await tester.pumpAndSettle();
        expect(find.text('DEVELOPER PRESENCE'), findsNothing);
        await tap('Join event');
        expect(participation.idsByIdentity['identity-a'], {'tech-mixer-2026'});
        expect(location.calls, 1);
        expect(gateway.records, 1);
        await tap('Leave event');
        expect(participation.idsByIdentity['identity-a'], isEmpty);
        expect(location.calls, 1);
        expect(gateway.refreshes, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
