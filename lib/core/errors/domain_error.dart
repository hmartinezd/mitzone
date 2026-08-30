enum DomainErrorCode { notFound, unauthorized, interactionUnavailable, invalidState, validation }
class DomainError implements Exception {
  const DomainError(this.code, this.message);
  final DomainErrorCode code; final String message;
  @override String toString() => 'DomainError($code): $message';
}
