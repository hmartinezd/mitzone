abstract interface class BlockRepository {
  Future<bool> isBlocked(String blockerUserId, String blockedUserId);
  Future<bool> isPairBlocked(String userAId, String userBId) async =>
      await isBlocked(userAId, userBId) || await isBlocked(userBId, userAId);
  Future<void> block({
    required String blockerUserId,
    required String blockedUserId,
  });
  Future<void> unblock({
    required String blockerUserId,
    required String blockedUserId,
  });
  Future<List<String>> getBlocked(String blockerUserId);
}
