import 'presence_consent.dart';
import 'presence_evidence.dart';
import 'presence_source.dart';
import 'location_observation.dart';

enum ForegroundPresenceStatus { inactive, requestingPermission, locating, active, recorded, denied, unavailable }

class ForegroundPresenceController {
  ForegroundPresenceController({required this.location, required this.now, this.duration = const Duration(minutes: 30)});
  final LocationObservationSource location;
  final DateTime Function() now;
  final Duration duration;
  ForegroundPresenceStatus status = ForegroundPresenceStatus.inactive;
  DateTime? expiresAt;

  Future<PresenceEvidence?> activate({required String userId, required bool productConsent, required LocationPermissionState permission, required String contextId}) async {
    if (!productConsent || permission != LocationPermissionState.whileUsing) {
      status = permission == LocationPermissionState.denied ? ForegroundPresenceStatus.denied : ForegroundPresenceStatus.inactive;
      return null;
    }
    status = ForegroundPresenceStatus.locating;
    final started = now().toUtc();
    final observation = await location.observeForeground();
    final expiry = started.add(duration);
    expiresAt = expiry;
    if (!now().toUtc().isBefore(expiry)) { stop(); return null; }
    final cell = '${(observation.latitude * 100).round()}:${(observation.longitude * 100).round()}';
    final evidence = PresenceEvidence(
      id: 'foreground:$userId:$cell', subjectUserId: userId, contextId: contextId.isEmpty ? 'cell:$cell' : contextId,
      observedStart: started, observedEnd: observation.observedAt.isAfter(started) ? observation.observedAt : started,
      source: PresenceEvidenceSource.geolocation, consentScope: 'foreground-explicit', expiresAt: expiry,
    );
    status = ForegroundPresenceStatus.recorded;
    return evidence;
  }

  void stop() { expiresAt = null; status = ForegroundPresenceStatus.inactive; }
  void onAppBackgrounded() => stop();
}
