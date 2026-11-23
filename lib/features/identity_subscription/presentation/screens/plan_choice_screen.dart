import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/plan_choice/plan_choice_cubit.dart';
import 'plan_subscription_screen.dart' show planPrice;

/// Figma 563:1913 (Plans & Contact) and 563:5425 (External Destination
/// Unavailable): public plans, a contact card and what each plan includes.
class PlanChoiceScreen extends StatelessWidget {
  const PlanChoiceScreen({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onContinue,
    required this.onRetry,
    this.onContact,
  });

  final PlanChoiceState state;
  final ValueChanged<SubscriptionPlan> onChoose;

  /// Registration without a plan, offered only when the catalog failed.
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  /// Null when no valid contact destination exists: the action is shown as
  /// unavailable instead of leading to an invalid resource.
  final VoidCallback? onContact;

  static const muted = Color(0xFF5B6475);

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final plans = state.plans;
    final recommended = plans.isEmpty
        ? null
        : plans.reduce(
            (a, b) => b.capabilities.length > a.capabilities.length ? b : a,
          );
    return Scaffold(
      backgroundColor: TataColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const BackButton(color: TataColors.ink),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          children: [
            Semantics(
              header: true,
              child: Text(
                text.planChoiceTitle,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 32,
                  height: 1.1,
                  color: TataColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text.planChoiceSubtitle,
              style: const TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 20),
            ...switch (state.status) {
              PlanChoiceStatus.loading => [
                _Card(
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(text.planChoiceLoading)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              PlanChoiceStatus.failure => [
                _LoadFailure(
                  errorCode: state.errorCode,
                  onRetry: onRetry,
                  onContinue: onContinue,
                ),
                const SizedBox(height: 18),
              ],
              PlanChoiceStatus.ready => [
                for (final plan in plans) ...[
                  _PlanCard(
                    plan: plan,
                    recommended: identical(plan, recommended),
                    onChoose: () => onChoose(plan),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            },
            _ContactCard(onContact: onContact),
            if (state.status == PlanChoiceStatus.ready) ...[
              const SizedBox(height: 18),
              _Comparison(plans: plans),
            ],
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.gradient});
  final Widget child;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: gradient == null ? Colors.white : null,
      gradient: switch (gradient) {
        final colors? => LinearGradient(colors: colors),
        null => null,
      },
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14173B70),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({
    required this.errorCode,
    required this.onRetry,
    required this.onContinue,
  });

  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return _Card(
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.planChoiceLoadError,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TataColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorCode == 'NETWORK_UNAVAILABLE'
                  ? text.networkUnavailable
                  : text.planChoiceLoadErrorBody,
              style: const TextStyle(
                fontSize: 13,
                color: PlanChoiceScreen.muted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(onPressed: onRetry, child: Text(text.subRetry)),
                TextButton(
                  onPressed: onContinue,
                  child: Text(text.planChoiceContinue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.recommended,
    required this.onChoose,
  });

  final SubscriptionPlan plan;
  final bool recommended;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final description = switch (plan.code) {
      'ESSENTIAL' => text.planChoiceDescEssential,
      'FAMILY' => text.planChoiceDescFamily,
      _ => null,
    };
    final label = text.planChoiceChoose(plan.name);
    return _Card(
      gradient: recommended
          ? const [Color(0xFFEFEAFC), Color(0xFFE4DDF8)]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ),
              Text(
                text.subPerMonth(planPrice(plan)),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TataColors.primary,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: PlanChoiceScreen.muted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Full width so the badge sits at the far edge, as in Figma; with
          // large text it wraps below the button instead of overflowing.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                if (recommended)
                  FilledButton(
                    onPressed: onChoose,
                    style: FilledButton.styleFrom(
                      backgroundColor: TataColors.primary,
                      minimumSize: const Size(150, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(label),
                  )
                else
                  OutlinedButton(
                    onPressed: onChoose,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEBFC),
                      foregroundColor: TataColors.primary,
                      side: const BorderSide(color: Color(0xFFB9AEEA)),
                      minimumSize: const Size(150, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(label),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: recommended ? Colors.white : const Color(0xFFE4F0F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recommended ? text.planChoiceRecommended : plan.name,
                    style: const TextStyle(fontSize: 12, color: TataColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onContact});
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final available = onContact != null;
    return _Card(
      gradient: const [Color(0xFFE5F0FA), Color(0xFFEAEEFA)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text.planChoiceContactTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ),
              const ExcludeSemantics(
                child: Row(
                  children: [
                    Icon(Icons.call_outlined, color: TataColors.primary),
                    SizedBox(width: 12),
                    Icon(Icons.chat_outlined, color: TataColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text.planChoiceContactBody,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: PlanChoiceScreen.muted,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onContact,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFEFEBFC),
              foregroundColor: TataColors.primary,
              disabledBackgroundColor: const Color(0xFFEDEEF2),
              disabledForegroundColor: PlanChoiceScreen.muted,
              side: BorderSide(
                color: available
                    ? const Color(0xFFB9AEEA)
                    : const Color(0xFFD3D7E0),
              ),
              minimumSize: const Size(140, 48),
              shape: const StadiumBorder(),
            ),
            // The hint merges into the button, so it is read with "No disponible".
            child: Semantics(
              hint: available ? null : text.planChoiceContactUnavailableHint,
              child: Text(
                available
                    ? text.planChoiceContact
                    : text.planChoiceContactUnavailable,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.plans});
  final List<SubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final rows = [
      (PlanCapability.reminders, text.planChoiceRowReminders),
      (PlanCapability.familyMonitoring, text.planChoiceRowMonitoring),
      (PlanCapability.adherenceInsights, text.planChoiceRowInsights),
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              text.planChoiceCompareTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TataColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: {
              0: const FlexColumnWidth(),
              for (var i = 0; i < plans.length; i++)
                i + 1: const IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  for (final plan in plans)
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          plan.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TataColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (final (capability, name) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PlanChoiceScreen.muted,
                        ),
                      ),
                    ),
                    for (final plan in plans)
                      _Mark(
                        included: plan.capabilities.contains(capability),
                        label: plan.capabilities.contains(capability)
                            ? text.planChoiceIncluded(plan.name)
                            : text.planChoiceNotIncluded(plan.name),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.included, required this.label});
  final bool included;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    excludeSemantics: true,
    child: Center(
      child: included
          ? const Icon(Icons.check, size: 18, color: Color(0xFF2E7D4F))
          : const Text('-', style: TextStyle(color: PlanChoiceScreen.muted)),
    ),
  );
}
