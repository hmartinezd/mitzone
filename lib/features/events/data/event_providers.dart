import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identity/identity_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/event_catalog.dart';
import '../domain/event_participation_repository.dart';
import 'demo_events.dart';
import 'local_event_participation_repository.dart';

final eventCatalogProvider = Provider<EventCatalog>(
  (ref) => const DemoEventCatalog(),
);

final eventParticipationRepositoryProvider =
    Provider<EventParticipationRepository>((ref) {
      return LocalEventParticipationRepository(ref.watch(localStorageProvider));
    });

final joinedEventIdsProvider = FutureProvider<Set<String>>((ref) async {
  final identity = await ref.watch(identityGatewayProvider).ensureIdentity();
  return ref
      .watch(eventParticipationRepositoryProvider)
      .getJoinedEventIds(identity.id);
});

final eventParticipationControllerProvider =
    Provider<EventParticipationController>(EventParticipationController.new);

class EventParticipationController {
  EventParticipationController(this._ref);

  final Ref _ref;
  final Set<String> _mutatingEventIds = {};

  Future<bool> setJoined({
    required String eventId,
    required bool joined,
  }) async {
    if (!_mutatingEventIds.add(eventId)) return false;
    try {
      final identity = await _ref
          .read(identityGatewayProvider)
          .ensureIdentity();
      final repository = _ref.read(eventParticipationRepositoryProvider);
      if (joined) {
        await repository.join(identityId: identity.id, eventId: eventId);
      } else {
        await repository.leave(identityId: identity.id, eventId: eventId);
      }
      _ref.invalidate(joinedEventIdsProvider);
      return true;
    } finally {
      _mutatingEventIds.remove(eventId);
    }
  }
}
