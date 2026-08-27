import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/events/domain/event_check_in.dart';
import 'package:mitzone/features/events/domain/presence_overlap.dart';

void main() {
  final day = DateTime.utc(2026, 8, 15);
  EventCheckIn presence(int start, int end) => EventCheckIn(
        eventId: 'event',
        identityId: 'user-$start',
        checkedInAt: day.add(Duration(hours: start)),
        checkedOutAt: day.add(Duration(hours: end)),
        method: EventCheckInMethod.manual,
      );

  test('calculates partial overlap duration', () {
    final result = PresenceOverlap.calculate(presence(18, 21), presence(19, 22));
    expect(result.overlaps, isTrue);
    expect(result.duration, const Duration(hours: 2));
  });

  test('rejects touching and disjoint windows', () {
    expect(PresenceOverlap.calculate(presence(18, 21), presence(21, 22)).overlaps, isFalse);
    expect(PresenceOverlap.calculate(presence(15, 17), presence(18, 21)).overlaps, isFalse);
  });

  test('supports contained windows and open-ended presence', () {
    final contained = PresenceOverlap.calculate(presence(18, 22), presence(19, 20));
    expect(contained.duration, const Duration(hours: 1));
    final open = EventCheckIn(eventId: 'event', identityId: 'open', checkedInAt: day.add(const Duration(hours: 19)), method: EventCheckInMethod.manual);
    expect(PresenceOverlap.calculate(open, presence(18, 21)).duration, const Duration(hours: 2));
  });
}
