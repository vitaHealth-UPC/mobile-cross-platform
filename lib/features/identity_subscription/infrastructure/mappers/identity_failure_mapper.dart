import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Maps known HTTP/code pairs to safe failures without displaying server diagnostics.
AppFailure<T> identityFailure<T>(ApiResponse response) {
  final body = response.body;
  final code = body is Map<String, dynamic> ? body['title'] : null;
  if (response.status == 400 && code == 'INVALID_RECOVERY_CODE') {
    return const AppFailure('INVALID_RECOVERY_CODE');
  }
  if (response.status == 409 && code == 'DUPLICATE_EMAIL') {
    return const AppFailure('DUPLICATE_EMAIL');
  }
  if (response.status == 410 && code == 'VERIFICATION_EXPIRED') {
    return const AppFailure('VERIFICATION_EXPIRED');
  }
  if (response.status == 401 && code == 'INVALID_VERIFICATION') {
    return const AppFailure('INVALID_VERIFICATION');
  }
  if (response.status == 401) {
    return const AppFailure('AUTHENTICATION_REQUIRED');
  }
  if (response.status == 403) return const AppFailure('ACCESS_DENIED');
  if (response.status == 429) return const AppFailure('RATE_LIMITED');
  const known = {
    'INVALID_CREDENTIALS',
    'ACCOUNT_NOT_VERIFIED',
    'ACCOUNT_DISABLED',
    'REQUEST_VALIDATION_FAILED',
  };
  return AppFailure(
    code is String && known.contains(code) ? code : 'REQUEST_FAILED',
  );
}
