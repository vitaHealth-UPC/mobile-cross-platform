import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/value_objects/notification_preferences.dart';
import '../bloc/notifications/notification_preferences_bloc.dart';
import '../bloc/notifications/notification_preferences_event.dart';
import '../bloc/notifications/notification_preferences_state.dart';

/// Channels, quiet hours, delivery policy and emergency contacts. Everything shown is what
/// the server acknowledged; nothing is cached on the device.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({
    super.key,
    required this.onSessionInvalidated,
  });

  final VoidCallback onSessionInvalidated;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _ContactRow {
  _ContactRow(String name, String phone)
    : name = TextEditingController(text: name),
      phone = TextEditingController(text: phone);
  final TextEditingController name;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _reminder = TextEditingController();
  final _pending = TextEditingController();
  final _omitted = TextEditingController();
  final _escalation = TextEditingController();
  final _summary = TextEditingController();
  final _contacts = <_ContactRow>[];
  NotificationPreferences? _loaded;

  @override
  void dispose() {
    for (final controller in [
      _reminder,
      _pending,
      _omitted,
      _escalation,
      _summary,
    ]) {
      controller.dispose();
    }
    for (final row in _contacts) {
      row.dispose();
    }
    super.dispose();
  }

  /// Copies the acknowledged policy and contacts into the form, once per snapshot.
  void _fill(NotificationPreferences preferences) {
    if (identical(_loaded?.policy, preferences.policy) &&
        identical(_loaded?.emergencyContacts, preferences.emergencyContacts)) {
      return;
    }
    _loaded = preferences;
    final policy = preferences.policy;
    if (policy == null) return;
    _reminder.text = '${policy.reminderMinutes}';
    _pending.text = '${policy.pendingAlertMinutes}';
    _omitted.text = '${policy.omittedAlertMinutes}';
    _escalation.text = '${policy.escalationMinutes}';
    final hour = policy.dailySummaryHour;
    _summary.text = hour == null
        ? ''
        : '${hour.toString().padLeft(2, '0')}:'
              '${policy.dailySummaryMinute!.toString().padLeft(2, '0')}';
    for (final row in _contacts) {
      row.dispose();
    }
    _contacts
      ..clear()
      ..addAll(
        preferences.emergencyContacts.map((c) => _ContactRow(c.name, c.phone)),
      );
  }

  String _channelLabel(AppLocalizations text, ChannelType type) =>
      switch (type) {
        ChannelType.push => text.pfChannelPush,
        ChannelType.sms => text.pfChannelSms,
        ChannelType.email => text.pfChannelEmail,
        ChannelType.call => text.pfChannelCall,
      };

  String? _errorText(AppLocalizations text, String? code) => switch (code) {
    null => null,
    'INVALID_POLICY' => text.pfErrInvalidPolicy,
    'INVALID_CONTACT' => text.pfErrInvalidContact,
    'NETWORK_UNAVAILABLE' => text.networkUnavailable,
    'ACCESS_DENIED' => text.accessDenied,
    'RATE_LIMITED' => text.rateLimited,
    'INVALID_PREFERENCES_RESPONSE' ||
    'INVALID_RESPONSE' => text.tmErrInvalidResponse,
    _ => text.pfErrGeneric,
  };

  Future<void> _pickTime(
    BuildContext context,
    int hour,
    int minute,
    void Function(TimeOfDay) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<
      NotificationPreferencesBloc,
      NotificationPreferencesState
    >(
      listener: (context, state) {
        if (state.errorCode == 'AUTHENTICATION_REQUIRED' ||
            state.errorCode == 'SESSION_CHANGED') {
          widget.onSessionInvalidated();
        } else if (state.saved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(text.pfPolicySaved)));
        }
      },
      builder: (context, state) {
        final bloc = context.read<NotificationPreferencesBloc>();
        if (state.status == NotificationPreferencesStatus.ready) {
          _fill(state.preferences);
        }
        final preferences = state.preferences;
        final quiet = preferences.quietHours;
        final error = _errorText(text, state.errorCode);
        return Scaffold(
          appBar: AppBar(title: Text(text.pfNotificationsTitle)),
          body: switch (state.status) {
            NotificationPreferencesStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            NotificationPreferencesStatus.failure => ErrorRetry(
              message: error ?? text.pfErrGeneric,
              retryLabel: text.tmRetry,
              onRetry: () => bloc.add(const NotificationPreferencesRequested()),
            ),
            NotificationPreferencesStatus.ready => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(text.pfNotificationsOnlineNote),
                const SizedBox(height: 12),
                Text(
                  text.pfChannels,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final channel in preferences.channels)
                  SwitchListTile(
                    title: Text(_channelLabel(text, channel.type)),
                    value: channel.enabled,
                    onChanged: state.busy
                        ? null
                        : (value) =>
                              bloc.add(ChannelToggled(channel.type, value)),
                  ),
                SwitchListTile(
                  title: Text(text.pfQuietHours),
                  value: quiet != null,
                  onChanged: state.busy
                      ? null
                      : (value) => bloc.add(QuietHoursToggled(value)),
                ),
                if (quiet != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => _pickTime(
                                  context,
                                  quiet.startHour,
                                  quiet.startMinute,
                                  (time) {
                                    final next = QuietHours.tryCreate(
                                      time.hour,
                                      time.minute,
                                      quiet.endHour,
                                      quiet.endMinute,
                                    );
                                    if (next != null) {
                                      bloc.add(QuietHoursChanged(next));
                                    }
                                  },
                                ),
                          child: Text(
                            '${text.pfQuietStart}: '
                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: quiet.startHour, minute: quiet.startMinute))}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.busy
                              ? null
                              : () => _pickTime(
                                  context,
                                  quiet.endHour,
                                  quiet.endMinute,
                                  (time) {
                                    final next = QuietHours.tryCreate(
                                      quiet.startHour,
                                      quiet.startMinute,
                                      time.hour,
                                      time.minute,
                                    );
                                    if (next != null) {
                                      bloc.add(QuietHoursChanged(next));
                                    }
                                  },
                                ),
                          child: Text(
                            '${text.pfQuietEnd}: '
                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: quiet.endHour, minute: quiet.endMinute))}',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (preferences.policy != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    text.pfPolicyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final (label, controller, key) in [
                    (text.pfReminderMinutes, _reminder, 'policy-reminder'),
                    (text.pfPendingMinutes, _pending, 'policy-pending'),
                    (text.pfOmittedMinutes, _omitted, 'policy-omitted'),
                    (
                      text.pfEscalationMinutes,
                      _escalation,
                      'policy-escalation',
                    ),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        key: Key(key),
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: label),
                      ),
                    ),
                  TextField(
                    key: const Key('policy-summary'),
                    controller: _summary,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(labelText: text.pfDailySummary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    text.pfContactsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (var i = 0; i < _contacts.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _contacts[i].name,
                              decoration: InputDecoration(
                                labelText: text.pfContactName,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _contacts[i].phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: text.pfContactPhone,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: text.pfRemoveContact,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() {
                              _contacts.removeAt(i).dispose();
                            }),
                          ),
                        ],
                      ),
                    ),
                  if (_contacts.length < 5)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _contacts.add(_ContactRow('', ''))),
                      icon: const Icon(Icons.add),
                      label: Text(text.pfAddContact),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.busy
                        ? null
                        : () => bloc.add(
                            PolicySaved(
                              reminder: _reminder.text,
                              pending: _pending.text,
                              omitted: _omitted.text,
                              escalation: _escalation.text,
                              dailySummary: _summary.text,
                              contacts: [
                                for (final row in _contacts)
                                  ContactInput(row.name.text, row.phone.text),
                              ],
                            ),
                          ),
                    child: Text(
                      state.busy ? text.processing : text.pfSavePolicy,
                    ),
                  ),
                ],
                if (error != null) InlineError(error),
              ],
            ),
          },
        );
      },
    );
  }
}
