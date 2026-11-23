import '../../../../shared/common/result/app_result.dart';

/// Reads the push SDK's current token; a null value means this build has no push
/// configuration, which is not an error.
abstract interface class DevicePushTokenSource {
  Future<AppResult<String?>> currentToken();
}
