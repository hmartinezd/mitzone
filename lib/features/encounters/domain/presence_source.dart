import '../../../core/errors/domain_error.dart';
import 'presence_consent.dart';
import 'presence_evidence.dart';

/// Coarse, non-location identity used by the encounter pipeline.
class PresenceContext {
  const PresenceContext({required this.placeKey});
  final String placeKey;
  bool get isSafe => placeKey.trim().isNotEmpty && placeKey.length <= 128;
}

class PresenceWindow {
  PresenceWindow({required this.from, required this.until}) {
    if (!from.isUtc || !until.isUtc || until.isBefore(from)) {
      throw const DomainError(DomainErrorCode.validation, 'Invalid UTC presence window');
    }
    if (until.difference(from) > const Duration(hours: 8)) {
      throw const DomainError(DomainErrorCode.validation, 'Presence window is too long');
    }
  }
  final DateTime from;
  final DateTime until;
}

abstract interface class PresenceSource {
  /// Converts an already-resolved, coarse observation into source-neutral evidence.
  Future<PresenceEvidence?> resolve({
    required String userId,
    required PresenceConsent consent,
    required PresenceContext context,
    required PresenceWindow window,
  });
}
