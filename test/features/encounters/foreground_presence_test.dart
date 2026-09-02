import 'package:flutter_test/flutter_test.dart';
import 'package:mitzone/features/encounters/data/foreground_location_sources.dart';
import 'package:mitzone/features/encounters/domain/foreground_presence_controller.dart';
import 'package:mitzone/features/encounters/domain/presence_consent.dart';

void main() {
  test('consent and foreground permission are required', () async {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    expect(await c.activate(userId: 'u', productConsent: false, permission: LocationPermissionState.whileUsing, contextId: ''), isNull);
    expect(c.status, ForegroundPresenceStatus.inactive);
  });
  test('active foreground presence records coarse evidence', () async {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    final e = await c.activate(userId: 'u', productConsent: true, permission: LocationPermissionState.whileUsing, contextId: '');
    expect(e?.contextId, startsWith('cell:'));
    expect(c.status, ForegroundPresenceStatus.recorded);
  });
  test('manual stop and background stop deactivate presence', () {
    final c = ForegroundPresenceController(location: const DemoForegroundLocationSource(), now: () => DateTime.utc(2026));
    c.onAppBackgrounded();
    expect(c.status, ForegroundPresenceStatus.inactive);
  });
}
