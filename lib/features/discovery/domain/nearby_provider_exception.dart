import '../../../core/errors/domain_error.dart';

enum NearbyProviderFailure {
  authentication,
  notConfigured,
  upstream,
  invalidResponse,
}

/// Discovery failures are independent of location permission and presence.
class NearbyProviderException extends DomainError {
  const NearbyProviderException(this.provider, this.failure)
    : super(
        failure == NearbyProviderFailure.authentication
            ? DomainErrorCode.unauthorized
            : DomainErrorCode.unavailable,
        'Nearby discovery is unavailable.',
      );

  final String provider;
  final NearbyProviderFailure failure;

  factory NearbyProviderException.fromStatus(String provider, int status) =>
      NearbyProviderException(provider, switch (status) {
        401 || 403 => NearbyProviderFailure.authentication,
        404 || 503 => NearbyProviderFailure.notConfigured,
        _ => NearbyProviderFailure.upstream,
      });

  @override
  String toString() => 'NearbyProviderException($provider, $failure)';
}
