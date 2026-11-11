import 'event_check_in.dart';

abstract interface class EventCheckInRepository {
  Future<List<EventCheckIn>> getCheckIns(String identityId);

  Future<EventCheckIn?> getCheckIn({
    required String identityId,
    required String eventId,
  });

  Future<void> recordCheckIn(EventCheckIn checkIn);
}
