import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/domain/presence_consent.dart';
import 'package:mitzone/features/encounters/domain/presence_source.dart';

void main() {
  test('OS permission does not grant product consent', () {
    const consent = PresenceConsent(
      locationPermission: LocationPermissionState.whileUsing,
      productConsent: false,
      presenceState: PresenceState.active,
    );
    expect(consent.mayCollect, isFalse);
  });

  test('presence requires explicit consent and active state', () {
    const consent = PresenceConsent(
      locationPermission: LocationPermissionState.whileUsing,
      productConsent: true,
      presenceState: PresenceState.active,
    );
    expect(consent.mayCollect, isTrue);
  });

  test('windows are UTC and bounded', () {
    expect(
      () => PresenceWindow(
        from: DateTime.utc(2026, 1, 1),
        until: DateTime.utc(2026, 1, 1, 9),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('raw coordinates have no representation in presence context', () {
    const context = PresenceContext(placeKey: 'venue:example');
    expect(context.isSafe, isTrue);
    expect(context.placeKey, isNot(contains(',')));
  });
}
