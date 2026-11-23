import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import 'identity_failure_mapper.dart';

/// Preserves only documented social-authentication status/code pairs.
AppFailure<T> socialFailure<T>(ApiResponse response) {
  final body = response.body;
  final code = body is Map<String, dynamic> ? body['title'] : null;
  final expectedStatus = switch (code) {
    'SOCIAL_LINK_REQUIRED' || 'SOCIAL_LINK_CONFLICT' => 409,
    'INVALID_SOCIAL_CREDENTIAL' => 401,
    'SOCIAL_EMAIL_REQUIRED' => 422,
    'SOCIAL_PROVIDER_UNAVAILABLE' => 503,
    _ => null,
  };
  if (expectedStatus == response.status && code is String) {
    return AppFailure(code);
  }
  return identityFailure(response);
}
