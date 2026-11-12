import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/ports/preferences_ports.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/value_objects/notification_preferences.dart';
import '../mappers/user_preferences_mapper.dart';
import '../remote/preferences_api.dart';

/// Runs a preferences request only for the owner of the captured session.
/// A caregiver or an older adult may read and change their own preferences, nobody else's.
Future<AppResult<UserPreferences>> _preferencesRequest(
  SessionStore store,
  String userId,
  Future<ApiResponse> Function(StoredSession session) call,
) async {
  try {
    await store.initialize();
  } on Exception {
    return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
  }
  final current = store.current;
  if (current != null && current.owner.id != userId) {
    return const AppFailure('ACCESS_DENIED');
  }
  return authorizedRequest(
    store,
    const {SessionRole.caregiver, SessionRole.olderAdult},
    call,
    (response, owner) {
      if (response.status == 400) {
        return const AppFailure('REQUEST_VALIDATION_FAILED');
      }
      if (response.status != 200) return const AppFailure('REQUEST_FAILED');
      return AppSuccess(
        UserPreferencesMapper.preferences(response.body, userId),
      );
    },
  );
}

/// Adapts accessibility preferences to the validated HTTP boundary.
final class RemoteUserPreferences implements UserPreferencesRemote {
  const RemoteUserPreferences({required this._api, required this._store});
  final PreferencesApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<UserPreferences>> get(String userId) => _preferencesRequest(
    _store,
    userId,
    (session) => _api.get(userId, session.accessToken),
  );

  @override
  Future<AppResult<UserPreferences>> update(
    String userId,
    AccessibilityChange change,
  ) => _preferencesRequest(
    _store,
    userId,
    (session) => _api.update(userId, change, session.accessToken),
  );
}

/// Adapts notification settings, delivery policy and recipients to HTTP, requiring the
/// server to echo exactly what was requested.
final class RemoteNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  const RemoteNotificationPreferencesRepository({
    required this._api,
    required this._store,
  });
  final PreferencesApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<NotificationPreferences>> get(String userId) async =>
      _notifications(
        await _preferencesRequest(
          _store,
          userId,
          (session) => _api.get(userId, session.accessToken),
        ),
        (_) => true,
      );

  @override
  Future<AppResult<NotificationPreferences>> update(
    String userId,
    NotificationPreferences preferences,
  ) async {
    final quiet = preferences.quietHours;
    final body = <String, Object?>{
      'quietHours': quiet == null
          ? null
          : {
              'start': UserPreferencesMapper.formatTime(
                quiet.startHour,
                quiet.startMinute,
              ),
              'end': UserPreferencesMapper.formatTime(
                quiet.endHour,
                quiet.endMinute,
              ),
            },
      'channels': [
        for (final channel in preferences.channels)
          {'type': channel.type.wire, 'enabled': channel.enabled},
      ],
    };
    final result = await _preferencesRequest(
      _store,
      userId,
      (session) => _api.updateNotifications(userId, body, session.accessToken),
    );
    return _notifications(
      result,
      (received) =>
          received.quietHours == preferences.quietHours &&
          _sameChannels(received, preferences),
    );
  }

  @override
  Future<AppResult<NotificationPreferences>> updatePolicy(
    String userId,
    NotificationPolicy policy,
    List<EmergencyContact> contacts,
  ) async {
    final hour = policy.dailySummaryHour;
    final body = <String, Object?>{
      'policy': {
        'reminderMinutes': policy.reminderMinutes,
        'pendingAlertMinutes': policy.pendingAlertMinutes,
        'omittedAlertMinutes': policy.omittedAlertMinutes,
        'escalationMinutes': policy.escalationMinutes,
        'dailySummaryTime': hour == null
            ? null
            : UserPreferencesMapper.formatTime(
                hour,
                policy.dailySummaryMinute!,
              ),
      },
      'contacts': [
        for (final contact in contacts)
          {'name': contact.name, 'phone': contact.phone},
      ],
    };
    final result = await _preferencesRequest(
      _store,
      userId,
      (session) => _api.updatePolicy(userId, body, session.accessToken),
    );
    return _notifications(
      result,
      (received) =>
          received.policy == policy &&
          _samePeople(received.emergencyContacts, contacts),
    );
  }

  /// Every requested channel must come back with the same enabled value. Maps do not
  /// compare by content in Dart, so the entries are checked one by one.
  static bool _sameChannels(
    NotificationPreferences received,
    NotificationPreferences requested,
  ) {
    final echoed = {
      for (final channel in received.channels) channel.type: channel.enabled,
    };
    final wanted = {
      for (final channel in requested.channels) channel.type: channel.enabled,
    };
    return echoed.length == wanted.length &&
        wanted.entries.every((entry) => echoed[entry.key] == entry.value);
  }

  static bool _samePeople(List<EmergencyContact> a, List<EmergencyContact> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

  AppResult<NotificationPreferences> _notifications(
    AppResult<UserPreferences> result,
    bool Function(NotificationPreferences) accepts,
  ) => switch (result) {
    AppSuccess<UserPreferences>(:final value) =>
      accepts(value.notifications)
          ? AppSuccess(value.notifications)
          : const AppFailure('INVALID_PREFERENCES_RESPONSE'),
    AppFailure<UserPreferences>(:final code) => AppFailure(code),
  };
}
