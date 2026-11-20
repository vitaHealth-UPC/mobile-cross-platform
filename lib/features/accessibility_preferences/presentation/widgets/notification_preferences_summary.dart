import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/value_objects/notification_preferences.dart';

/// Acknowledged settings grouped as in Figma 563:1219, with native controls.
/// The owning screen handles editing, session invalidation and persistence.
class NotificationPreferencesSummary extends StatelessWidget {
  const NotificationPreferencesSummary({
    super.key,
    required this.preferences,
    required this.busy,
    required this.onEditPolicy,
    required this.onToggleChannel,
    required this.onToggleQuiet,
    required this.onEditQuiet,
  });
  final NotificationPreferences preferences;
  final bool busy;
  final VoidCallback? onEditPolicy;
  final void Function(ChannelType, bool) onToggleChannel;
  final ValueChanged<bool> onToggleQuiet;
  final VoidCallback onEditQuiet;

  Widget _icon(String name, {double size = 22}) => SvgPicture.asset(
    'assets/icons/notification_$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _heading(AppLocalizations text, String title, String icon) => Row(
    children: [
      _icon(icon),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TataColors.ink,
          ),
        ),
      ),
      TextButton(
        onPressed: busy ? null : onEditPolicy,
        child: Text(text.pfEdit, style: const TextStyle(fontSize: 11)),
      ),
    ],
  );

  Widget _row(String label, String value) => InkWell(
    onTap: busy ? null : onEditPolicy,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: TataColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(fontSize: 10, color: TataColors.muted),
            ),
          ),
          const Icon(Icons.chevron_right, size: 15, color: TataColors.muted),
        ],
      ),
    ),
  );

  Widget get _divider => const Divider(
    height: 1,
    indent: 12,
    endIndent: 12,
    color: Color(0xFFE5E8F0),
  );
  String _after(AppLocalizations text, int minutes) => minutes % 60 == 0
      ? text.pfAfterHours(minutes ~/ 60)
      : text.pfAfterMinutes(minutes);
  String _time(BuildContext context, int hour, int minute) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final policy = preferences.policy;
    final quiet = preferences.quietHours;
    final unavailable = text.pfNotConfigured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          Column(
            children: [
              _heading(text, text.pfMedicationReminders, 'reminder'),
              _row(
                text.pfCadence,
                policy == null
                    ? unavailable
                    : text.pfReminderAfter(policy.reminderMinutes),
              ),
            ],
          ),
        ),
        _card(
          Column(
            children: [
              _heading(text, text.pfCaregiverAlerts, 'caregiver'),
              _row(
                text.pfPendingDoses,
                policy == null
                    ? unavailable
                    : _after(text, policy.pendingAlertMinutes),
              ),
              _divider,
              _row(
                text.pfOmittedDoses,
                policy == null
                    ? unavailable
                    : _after(text, policy.omittedAlertMinutes),
              ),
              _divider,
              _row(
                text.pfSummaryLabel,
                policy?.dailySummaryHour == null
                    ? unavailable
                    : _time(
                        context,
                        policy!.dailySummaryHour!,
                        policy.dailySummaryMinute!,
                      ),
              ),
            ],
          ),
        ),
        _card(
          Column(
            children: [
              _heading(text, text.pfEmergencyEscalation, 'emergency'),
              _row(
                text.pfContactsTitle,
                text.pfConfiguredContacts(preferences.emergencyContacts.length),
              ),
              _divider,
              _row(
                text.pfEscalateNoResponse,
                policy == null
                    ? unavailable
                    : _after(text, policy.escalationMinutes),
              ),
            ],
          ),
        ),
        _card(
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: busy || quiet == null ? null : onEditQuiet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _icon('quiet'),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                text.pfQuietHours,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          quiet == null
                              ? text.pfDisabled
                              : '${_time(context, quiet.startHour, quiet.startMinute)} - ${_time(context, quiet.endHour, quiet.endMinute)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TataColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Switch(
                key: const Key('notification-quiet-switch'),
                value: quiet != null,
                activeTrackColor: const Color(0xFF6DA885),
                activeThumbColor: Colors.white,
                onChanged: busy ? null : onToggleQuiet,
              ),
            ],
          ),
        ),
        _card(
          Column(
            children: [
              _heading(text, text.pfNotificationChannels, 'channels'),
              const SizedBox(height: 14),
              if (MediaQuery.textScalerOf(context).scale(9) > 12)
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      for (final type in ChannelType.values)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _channel(text, type),
                        ),
                    ],
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final type in ChannelType.values)
                      Expanded(child: _channel(text, type)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _channel(AppLocalizations text, ChannelType type) {
    final enabled = preferences.isEnabled(type);
    final (label, icon, color) = switch (type) {
      ChannelType.push => (text.pfChannelPush, 'push', const Color(0xFFE6F0FF)),
      ChannelType.sms => (text.pfChannelSms, 'sms', const Color(0xFFE8F7EF)),
      ChannelType.email => (
        text.pfChannelEmail,
        'email',
        const Color(0xFFF0ECFF),
      ),
      ChannelType.call => (
        text.pfChannelCall,
        'phone',
        const Color(0xFFE6F6FF),
      ),
    };
    return Semantics(
      toggled: enabled,
      label: label,
      button: true,
      excludeSemantics: true,
      onTap: busy ? null : () => onToggleChannel(type, !enabled),
      child: Tooltip(
        message: label,
        child: InkWell(
          key: Key('notification-channel-${type.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: busy ? null : () => onToggleChannel(type, !enabled),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: enabled
                        ? Border.all(color: TataColors.primary, width: 1.5)
                        : null,
                  ),
                  child: _icon(icon, size: 24),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: TataColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
