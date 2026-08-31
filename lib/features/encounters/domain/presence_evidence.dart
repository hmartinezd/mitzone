import '../../../core/errors/domain_error.dart';

enum PresenceEvidenceSource {
  localDemo,
  eventParticipation,
  qr,
  geolocation,
  venueVerification,
}

/// Bounded evidence that a user occupied a context during an interval.
class PresenceEvidence {
  factory PresenceEvidence({
    required String id,
    required String subjectUserId,
    required String contextId,
    required DateTime observedStart,
    required DateTime observedEnd,
    required PresenceEvidenceSource source,
    double? confidence,
    String? consentScope,
    DateTime? expiresAt,
  }) {
    if (id.trim().isEmpty ||
        subjectUserId.trim().isEmpty ||
        contextId.trim().isEmpty)
      throw const DomainError(
        DomainErrorCode.validation,
        'Presence evidence identifiers are required',
      );
    if (!observedStart.isUtc ||
        !observedEnd.isUtc ||
        (expiresAt != null && !expiresAt.isUtc))
      throw const DomainError(
        DomainErrorCode.validation,
        'Presence evidence timestamps must be UTC',
      );
    if (observedEnd.isBefore(observedStart))
      throw const DomainError(
        DomainErrorCode.validation,
        'Presence evidence interval is reversed',
      );
    if (confidence != null && (confidence < 0 || confidence > 1))
      throw const DomainError(
        DomainErrorCode.validation,
        'Presence confidence must be between 0 and 1',
      );
    if (expiresAt != null && expiresAt.isBefore(observedEnd))
      throw const DomainError(
        DomainErrorCode.invalidState,
        'Presence evidence expires before it ends',
      );
    return PresenceEvidence._(
      id,
      subjectUserId,
      contextId,
      observedStart,
      observedEnd,
      source,
      confidence,
      consentScope,
      expiresAt,
    );
  }
  const PresenceEvidence._(
    this.id,
    this.subjectUserId,
    this.contextId,
    this.observedStart,
    this.observedEnd,
    this.source,
    this.confidence,
    this.consentScope,
    this.expiresAt,
  );
  final String id, subjectUserId, contextId;
  final DateTime observedStart, observedEnd;
  final PresenceEvidenceSource source;
  final double? confidence;
  final String? consentScope;
  final DateTime? expiresAt;
  bool get isUtc =>
      observedStart.isUtc && observedEnd.isUtc && (expiresAt?.isUtc ?? true);
}
