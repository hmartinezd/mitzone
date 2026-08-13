abstract interface class EventParticipationRepository {
  Future<Set<String>> getJoinedEventIds(String identityId);

  Future<bool> isJoined({required String identityId, required String eventId});

  Future<void> join({required String identityId, required String eventId});

  Future<void> leave({required String identityId, required String eventId});
}
