import '../../../domain/value_objects/notification_preferences.dart';

enum NotificationPreferencesStatus { loading, ready, failure }

final class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.loading,
    this.preferences = const NotificationPreferences(),
    this.busy = false,
    this.saved = false,
    this.errorCode,
  });

  final NotificationPreferencesStatus status;
  final NotificationPreferences preferences;

  /// True while a change is in flight; further changes wait for it.
  final bool busy;

  /// True right after a policy save was acknowledged.
  final bool saved;
  final String? errorCode;

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferences? preferences,
    bool? busy,
    bool saved = false,
    String? errorCode,
  }) => NotificationPreferencesState(
    status: status ?? this.status,
    preferences: preferences ?? this.preferences,
    busy: busy ?? this.busy,
    saved: saved,
    errorCode: errorCode,
  );
}
