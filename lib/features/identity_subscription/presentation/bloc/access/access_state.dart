import '../../../domain/entities/account_session.dart';

/// Observable access phases; authenticated state requires acknowledged session data.
enum AccessStatus {
  initial,
  busy,
  anonymous,
  authenticated,
  consentRequired,
  failure,
}

/// Contains public session metadata only, never an email/password or bearer token.
final class AccessState {
  const AccessState({
    this.status = AccessStatus.initial,
    this.session,
    this.errorCode,
  });
  final AccessStatus status;
  final AccountSession? session;
  final String? errorCode;
}
