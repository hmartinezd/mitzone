sealed class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppException(this.message, [this.stackTrace]);
}

class ConfigException extends AppException {
  const ConfigException(super.message, [super.stackTrace]);
}

class UnexpectedException extends AppException {
  const UnexpectedException(super.message, [super.stackTrace]);
}
