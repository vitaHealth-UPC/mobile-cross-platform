import '../../../domain/value_objects/notification_preferences.dart';

enum NotificationPreferencesStatus { loading, ready, failure }

/// Identifies the operation acknowledged by the latest successful request.
enum NotificationPreferenceReceipt { policy, channels, quietHours }

final class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.loading,
    this.preferences = const NotificationPreferences(),
    this.busy = false,
    this.errorCode,
    this.receipt,
  });

  final NotificationPreferencesStatus status;
  final NotificationPreferences preferences;

  /// True while a change is in flight; further changes wait for it.
  final bool busy;

  final String? errorCode;
  final NotificationPreferenceReceipt? receipt;

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferences? preferences,
    bool? busy,
    String? errorCode,
    NotificationPreferenceReceipt? receipt,
  }) => NotificationPreferencesState(
    status: status ?? this.status,
    preferences: preferences ?? this.preferences,
    busy: busy ?? this.busy,
    errorCode: errorCode,
    receipt: receipt,
  );
}
