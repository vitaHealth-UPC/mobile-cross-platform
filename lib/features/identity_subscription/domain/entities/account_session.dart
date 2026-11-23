import '../../../../shared/application/session/session_owner.dart';

/// Public session metadata. Bearer credentials remain outside presentation state.
final class AccountSession {
  const AccountSession({required this.owner, required this.expiresAt});
  final SessionOwner owner;
  final DateTime expiresAt;
}
