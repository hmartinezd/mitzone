/// OS permission and product consent are intentionally separate.
enum LocationPermissionState { notRequested, denied, whileUsing, background }

enum PresenceState { inactive, active }

class PresenceConsent {
  const PresenceConsent({
    required this.locationPermission,
    required this.productConsent,
    required this.presenceState,
  });

  final LocationPermissionState locationPermission;
  final bool productConsent;
  final PresenceState presenceState;

  bool get mayCollect =>
      productConsent &&
      presenceState == PresenceState.active &&
      locationPermission == LocationPermissionState.whileUsing;
}
