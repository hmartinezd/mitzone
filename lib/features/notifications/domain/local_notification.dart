enum LocalNotificationType { connectionRequest, connectionAccepted, newMessage }

class LocalNotification {
  const LocalNotification({required this.id, required this.type, required this.userId, required this.timestamp, required this.entityId, required this.destination, this.read = false});
  final String id;
  final LocalNotificationType type;
  final String userId;
  final DateTime timestamp;
  final String entityId;
  final String destination;
  final bool read;
  LocalNotification copyWith({bool? read}) => LocalNotification(id: id, type: type, userId: userId, timestamp: timestamp, entityId: entityId, destination: destination, read: read ?? this.read);
}
