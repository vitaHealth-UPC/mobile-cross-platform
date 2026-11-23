import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../ports/omission_ports.dart';

/// Removes already displayed clinical notices when their local recipient session ceases to
/// apply: on the first observation of the process, when the owner changes and when the
/// credential expires.
final class OmissionNotificationSessionCleanup {
  OmissionNotificationSessionCleanup({required this._notifier, Clock? now})
    : _now = now ?? DateTime.now;

  final OmissionNotifier _notifier;
  final Clock _now;
  bool _initialized = false;
  SessionOwner? _previous;
  Timer? _expiry;

  /// Reports the session in force; call it whenever the access state changes.
  Future<void> observe(StoredSession? session) async {
    _expiry?.cancel();
    _expiry = null;
    final now = _now();
    final owner =
        session != null &&
            session.owner.role != SessionRole.linkSetup &&
            session.isValidAt(now)
        ? session.owner
        : null;
    final changed = !_initialized || _previous != owner;
    _initialized = true;
    _previous = owner;
    if (owner != null) {
      final remaining = session!.expiresAt.difference(now);
      _expiry = Timer(remaining.isNegative ? Duration.zero : remaining, () {
        _previous = null;
        unawaited(_notifier.clearDisplayed());
      });
    }
    if (changed) await _notifier.clearDisplayed();
  }

  void dispose() {
    _expiry?.cancel();
    _expiry = null;
  }
}
