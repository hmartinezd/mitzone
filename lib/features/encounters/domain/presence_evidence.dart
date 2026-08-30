enum PresenceEvidenceSource { localDemo, eventParticipation, qr, geolocation, venueVerification }
/// Bounded evidence that a user occupied a context during an interval.
class PresenceEvidence {
  const PresenceEvidence({required this.id, required this.subjectUserId, required this.contextId, required this.observedStart, required this.observedEnd, required this.source, this.confidence, this.consentScope, this.expiresAt}) : assert(id != ''), assert(subjectUserId != ''), assert(contextId != ''), assert(!observedEnd.isBefore(observedStart)), assert(confidence == null || (confidence >= 0 && confidence <= 1));
  final String id, subjectUserId, contextId; final DateTime observedStart, observedEnd; final PresenceEvidenceSource source; final double? confidence; final String? consentScope; final DateTime? expiresAt;
  bool get isUtc => observedStart.isUtc && observedEnd.isUtc && (expiresAt?.isUtc ?? true);
}
