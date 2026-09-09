enum DomainErrorCode {
  notFound,
  unauthorized,
  conflict,
  unavailable,
  interactionUnavailable,
  invalidState,
  validation,
}

class DomainError implements Exception {
  const DomainError(this.code, this.message);
  final DomainErrorCode code;
  final String message;
  @override
  String toString() => 'DomainError($code): $message';
}
