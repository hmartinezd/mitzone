import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/home/presentation/home_activity_priority.dart';

void main() {
  test('no social activity is low activity', () {
    expect(
      homeActivityPriority(
        encounters: 0,
        incomingRequests: 0,
        connections: 0,
        conversations: 0,
      ),
      HomeActivityPriority.lowActivity,
    );
  });

  test('one social signal is growing activity', () {
    expect(
      homeActivityPriority(
        encounters: 1,
        incomingRequests: 0,
        connections: 0,
        conversations: 0,
      ),
      HomeActivityPriority.growingActivity,
    );
  });

  test('connections and conversations are active', () {
    expect(
      homeActivityPriority(
        encounters: 0,
        incomingRequests: 0,
        connections: 1,
        conversations: 1,
      ),
      HomeActivityPriority.active,
    );
  });
}
