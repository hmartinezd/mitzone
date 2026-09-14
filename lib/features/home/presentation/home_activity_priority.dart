enum HomeActivityPriority { lowActivity, growingActivity, active }

HomeActivityPriority homeActivityPriority({
  required int encounters,
  required int incomingRequests,
  required int connections,
  required int conversations,
}) {
  final signals = [encounters, incomingRequests, connections, conversations]
      .where((count) => count > 0)
      .length;
  if (connections > 0 && conversations > 0 || signals >= 3) {
    return HomeActivityPriority.active;
  }
  if (signals > 0) return HomeActivityPriority.growingActivity;
  return HomeActivityPriority.lowActivity;
}
