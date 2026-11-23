import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../application/ports/contact_launcher.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/value_objects/contact_channel.dart';

/// Rounded white card shared by the follow-up screens.
class MonitoringCard extends StatelessWidget {
  const MonitoringCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: TataColors.softBorder),
    ),
    child: child,
  );
}

/// Screen title in the serif face with an optional subtitle.
class MonitoringHeader extends StatelessWidget {
  const MonitoringHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: TataTypography.heading),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: TataTypography.subtitle),
      ],
    ],
  );
}

class MonitoringLoading extends StatelessWidget {
  const MonitoringLoading({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Semantics(
      liveRegion: true,
      label: label,
      child: const Center(child: CircularProgressIndicator()),
    ),
  );
}

/// Failure message with a retry action.
class MonitoringError extends StatelessWidget {
  const MonitoringError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return MonitoringCard(
      color: TataColors.errorSurface,
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: TataColors.errorText,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(text.fmRetry)),
          ],
        ),
      ),
    );
  }
}

/// Selectable pill used by the alert and personal-note filters.
class MonitoringFilterChip extends StatelessWidget {
  const MonitoringFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? TataColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? TataColors.primary : TataColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : TataColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// Filled navy button of full width.
class MonitoringPrimaryButton extends StatelessWidget {
  const MonitoringPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: TataColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Contact content: the chosen channel with the action that opens it. Used by the summary
/// dialog and by the alert detail.
class ContactChannelView extends StatelessWidget {
  const ContactChannelView({
    super.key,
    required this.option,
    required this.launcher,
  });

  final ContactOption option;
  final ContactLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final channel = option.channel;
    if (channel == null) return Text(text.fmContactNone);
    final isPhone = channel.type == ContactChannelType.phone;
    final label = isPhone
        ? text.fmContactPhone(channel.value)
        : text.fmContactWhatsapp(channel.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        MonitoringPrimaryButton(
          label: isPhone ? text.fmOpenPhone : text.fmOpenWhatsapp,
          onPressed: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            final opened = await launcher.open(channel);
            if (!opened) {
              messenger?.showSnackBar(
                SnackBar(content: Text(text.fmContactNoApp)),
              );
            }
          },
        ),
      ],
    );
  }
}
