import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/preferences_usecases.dart';
import '../../../domain/value_objects/notification_preferences.dart';
import 'notification_preferences_event.dart';
import 'notification_preferences_state.dart';

/// Edits what the backend uses to deliver notices. Nothing is stored on the device: the
/// screen shows exactly what the server acknowledged.
final class NotificationPreferencesBloc
    extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  NotificationPreferencesBloc({
    required this._get,
    required this._update,
    required this._updatePolicy,
    required this.userId,
  }) : super(const NotificationPreferencesState()) {
    on<NotificationPreferencesRequested>(_load);
    on<ChannelToggled>(_toggleChannel);
    on<QuietHoursToggled>(
      (event, emit) => _replace(
        emit,
        event.enabled
            ? state.preferences.copyWith(quietHours: QuietHours.suggested())
            : state.preferences.copyWith(clearQuietHours: true),
      ),
    );
    on<QuietHoursChanged>(
      (event, emit) => _replace(
        emit,
        state.preferences.copyWith(quietHours: event.quietHours),
      ),
    );
    on<PolicySaved>(_savePolicy);
  }

  final GetNotificationPreferences _get;
  final UpdateNotificationPreferences _update;
  final UpdateNotificationPolicy _updatePolicy;
  final String userId;

  Future<void> _load(
    NotificationPreferencesRequested event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    emit(const NotificationPreferencesState());
    final result = await _get(userId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<NotificationPreferences>(:final value) =>
        NotificationPreferencesState(
          status: NotificationPreferencesStatus.ready,
          preferences: value,
        ),
      AppFailure<NotificationPreferences>(:final code) =>
        NotificationPreferencesState(
          status: NotificationPreferencesStatus.failure,
          errorCode: code,
        ),
    });
  }

  Future<void> _toggleChannel(
    ChannelToggled event,
    Emitter<NotificationPreferencesState> emit,
  ) {
    final current = state.preferences;
    return _replace(
      emit,
      current.copyWith(
        channels: [
          for (final channel in current.channels)
            channel.type == event.type
                ? channel.copyWith(enabled: event.enabled)
                : channel,
        ],
      ),
    );
  }

  /// Sends the candidate and shows it only after the server echoed it; on failure the
  /// previous values stay visible.
  Future<void> _replace(
    Emitter<NotificationPreferencesState> emit,
    NotificationPreferences candidate,
  ) async {
    if (state.busy || state.status != NotificationPreferencesStatus.ready) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await _update(userId, candidate);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<NotificationPreferences>(:final value) => state.copyWith(
        preferences: value,
        busy: false,
      ),
      AppFailure<NotificationPreferences>(:final code) => state.copyWith(
        busy: false,
        errorCode: code,
      ),
    });
  }

  Future<void> _savePolicy(
    PolicySaved event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    if (state.busy || state.status != NotificationPreferencesStatus.ready) {
      return;
    }
    final summary = event.dailySummary.trim();
    final summaryTime = summary.isEmpty ? null : parseHourMinute(summary);
    final reminder = int.tryParse(event.reminder.trim());
    final pending = int.tryParse(event.pending.trim());
    final omitted = int.tryParse(event.omitted.trim());
    final escalation = int.tryParse(event.escalation.trim());
    final policy =
        reminder == null ||
            pending == null ||
            omitted == null ||
            escalation == null ||
            (summary.isNotEmpty && summaryTime == null)
        ? null
        : NotificationPolicy.tryCreate(
            reminderMinutes: reminder,
            pendingAlertMinutes: pending,
            omittedAlertMinutes: omitted,
            escalationMinutes: escalation,
            dailySummaryHour: summaryTime?.$1,
            dailySummaryMinute: summaryTime?.$2,
          );
    if (policy == null) {
      emit(state.copyWith(errorCode: 'INVALID_POLICY'));
      return;
    }
    final contacts = <EmergencyContact>[];
    for (final input in event.contacts) {
      // A completely blank row is an unused form line, not an invalid contact.
      if (input.name.trim().isEmpty && input.phone.trim().isEmpty) continue;
      final contact = EmergencyContact.tryCreate(input.name, input.phone);
      if (contact == null) {
        emit(state.copyWith(errorCode: 'INVALID_CONTACT'));
        return;
      }
      contacts.add(contact);
    }
    emit(state.copyWith(busy: true));
    final result = await _updatePolicy(userId, policy, contacts);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<NotificationPreferences>(:final value) => state.copyWith(
        preferences: value,
        busy: false,
        saved: true,
      ),
      AppFailure<NotificationPreferences>(:final code) => state.copyWith(
        busy: false,
        errorCode: code,
      ),
    });
  }
}
