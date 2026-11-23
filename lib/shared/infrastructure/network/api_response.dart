/// HTTP status and decoded JSON returned to a feature-specific response mapper.
final class ApiResponse {
  const ApiResponse(this.status, this.body);
  final int status;
  final Object? body;
}

/// Stable transport failure code safe to translate without exposing response bodies.
final class ApiTransportException implements Exception {
  const ApiTransportException(this.code);
  final String code;

  @override
  String toString() => 'ApiTransportException($code)';
}
