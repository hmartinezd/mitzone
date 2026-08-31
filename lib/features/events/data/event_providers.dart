import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/identity/identity_providers.dart';
import '../../../core/identity/current_user_provider.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/event_catalog.dart';
import '../domain/event_check_in.dart';
import '../domain/event_check_in_repository.dart';
import '../domain/event_participation_repository.dart';
import 'demo_events.dart';
import 'local_event_check_in_repository.dart';
import 'local_event_participation_repository.dart';
import 'mock_event_attendees.dart';
import '../../encounters/data/presence_providers.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../encounters/domain/presence_evidence.dart';

typedef DemoPresenceRequest = ({String eventId, DateTime referenceTime});

final mockEventAttendeesProvider =
    Provider.family<List<EventCheckIn>, DemoPresenceRequest>(
      (ref, request) => mockAttendeesForEvent(
        eventId: request.eventId,
        referenceTime: request.referenceTime,
      ),
    );

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

final eventCheckInRepositoryProvider = Provider<EventCheckInRepository>((ref) {
  return LocalEventCheckInRepository(ref.watch(localStorageProvider));
});

final utcNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final eventCheckInsProvider = FutureProvider<List<EventCheckIn>>((ref) async {
  if (ref.watch(productionModeProvider)) {
    final id = await ref.watch(currentUserIdProvider.future);
    final evidence = await ref
        .watch(presenceRepositoryProvider)
        .getEvidenceForUser(id);
    return evidence
        .map(
          (e) => EventCheckIn(
            eventId: e.contextId,
            identityId: e.subjectUserId,
            checkedInAt: e.observedStart,
            checkedOutAt: e.observedEnd,
            method: EventCheckInMethod.localDemo,
          ),
        )
        .toList();
  }
  final identity = await ref.watch(identityGatewayProvider).ensureIdentity();
  return ref.watch(eventCheckInRepositoryProvider).getCheckIns(identity.id);
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
      if (_ref.read(productionModeProvider)) {
        final id = await _ref.read(currentUserIdProvider.future);
        final participation = _ref.read(eventParticipationRepositoryProvider);
        if (!await participation.isJoined(identityId: id, eventId: eventId))
          return false;
        final now = _ref.read(utcNowProvider)().toUtc();
        final evidence = PresenceEvidence(
                id: Uuid().v5(Uuid.NAMESPACE_URL, 'presence:$id:$eventId'),
                subjectUserId: id,
                contextId: eventId,
                observedStart: now,
                observedEnd: now.add(const Duration(minutes: 45)),
                source: PresenceEvidenceSource.eventParticipation,
                consentScope: 'explicit-check-in',
                expiresAt: now.add(const Duration(days: 30)),
              );
        final recorded = await _ref
            .read(presenceRepositoryProvider)
            .recordEvidence(evidence, actorUserId: id);
        await _ref.read(encounterRepositoryProvider).processEvidence(
              recorded,
              actorUserId: id,
            );
        _ref.invalidate(eventCheckInsProvider);
        return true;
      }
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

final eventCheckInControllerProvider = Provider<EventCheckInController>(
  EventCheckInController.new,
);

class EventCheckInController {
  EventCheckInController(this._ref);

  final Ref _ref;
  final Set<String> _mutatingEventIds = {};

  Future<bool> recordLocalDemoCheckIn(String eventId) async {
    eventId = eventId.trim();
    if (eventId.isEmpty || !_mutatingEventIds.add(eventId)) return false;
    try {
      final identity = await _ref
          .read(identityGatewayProvider)
          .ensureIdentity();
      final participation = _ref.read(eventParticipationRepositoryProvider);
      if (!await participation.isJoined(
        identityId: identity.id,
        eventId: eventId,
      )) {
        return false;
      }
      await _ref
          .read(eventCheckInRepositoryProvider)
          .recordCheckIn(
            EventCheckIn(
              eventId: eventId,
              identityId: identity.id,
              checkedInAt: _ref.read(utcNowProvider)().toUtc(),
              method: EventCheckInMethod.localDemo,
            ),
          );
      _ref.invalidate(eventCheckInsProvider);
      return true;
    } finally {
      _mutatingEventIds.remove(eventId);
    }
  }
}
