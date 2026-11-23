import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/social_provider.dart';

/// Transient Firebase evidence; never persisted as the Tata session credential.
final class SocialIdentityToken {
  SocialIdentityToken(this.value) {
    if (value.isEmpty || value.length > 16384 || value.trim() != value) {
      throw const FormatException('Invalid social identity evidence');
    }
  }
  final String value;

  @override
  String toString() => 'SocialIdentityToken[REDACTED]';
}

/// Opens provider authentication and exchanges its credential through Firebase.
/// Null success denotes cancellation; failures contain stable codes only.
abstract interface class SocialCredentials {
  Future<AppResult<SocialIdentityToken?>> authenticate(SocialProvider provider);
}
