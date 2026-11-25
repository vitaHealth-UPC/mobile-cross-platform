import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/entities/subscription_plan.dart';
import '../bloc/subscription/subscription_bloc.dart';
import '../bloc/subscription/subscription_event.dart';
import '../bloc/subscription/subscription_state.dart';

const _success = Color(0xFF3A7B56);

/// Renewal cycle the server applies when a plan is activated; it only drives
/// the progress bar of the current plan.
const _cycle = Duration(days: 30);

/// Plan and subscription of the caregiver (Figma 563:1701; updated 563:5354).
class PlanSubscriptionScreen extends StatelessWidget {
  const PlanSubscriptionScreen({
    super.key,
    required this.onSessionInvalidated,
    required this.clock,
  });

  final VoidCallback onSessionInvalidated;
  final DateTime Function() clock;

  static bool _sessionEnded(String? code) =>
      code == 'AUTHENTICATION_REQUIRED' || code == 'SESSION_CHANGED';

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listenWhen: (before, after) => before.errorCode != after.errorCode,
      listener: (context, state) {
        if (_sessionEnded(state.errorCode)) onSessionInvalidated();
      },
      builder: (context, state) {
        final bloc = context.read<SubscriptionBloc>();
        return Scaffold(
          backgroundColor: TataColors.background,
          body: SafeArea(
            child: switch (state.phase) {
              SubscriptionPhase.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              SubscriptionPhase.failure => ErrorRetry(
                message: _errorText(text, state.errorCode),
                retryLabel: text.subRetry,
                onRetry: () => bloc.add(const SubscriptionRequested()),
              ),
              SubscriptionPhase.ready => ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: text.back,
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      text.subTitle,
                      style: const TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 30,
                        height: 1.25,
                        color: TataColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text.subSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TataColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CurrentPlanCard(
                    subscription: state.subscription!,
                    now: clock(),
                  ),
                  const SizedBox(height: 14),
                  for (final (index, plan) in state.plans.indexed) ...[
                    _PlanCard(
                      plan: plan,
                      added: _addedCapabilities(state.plans, index),
                      current: state.subscription!.isOn(plan),
                      selected: plan.code == state.selectedCode,
                      onTap: state.changing
                          ? null
                          : () => bloc.add(SubscriptionPlanSelected(plan.code)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 6),
                  ElevatedButton(
                    key: const Key('change-plan'),
                    onPressed: state.selected == null || state.changing
                        ? null
                        : () => _confirm(context, state.selected!),
                    child: Text(
                      state.changing ? text.subChanging : text.subChange,
                    ),
                  ),
                  if (state.selected == null && !state.updated) ...[
                    const SizedBox(height: 8),
                    Text(
                      text.subSelectHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TataColors.muted,
                      ),
                    ),
                  ],
                  if (state.subscription!.renewsAt case final renews?) ...[
                    const SizedBox(height: 18),
                    _RenewalCard(
                      renewsAt: renews,
                      plan: state.subscription!.plan,
                    ),
                  ],
                  if (state.updated) ...[
                    const SizedBox(height: 14),
                    _Notice(
                      title: text.subUpdatedTitle,
                      body: text.subUpdatedBody,
                      background: TataColors.mint,
                      ink: _success,
                    ),
                  ],
                  if (state.errorCode case final code?
                      when !_sessionEnded(code)) ...[
                    const SizedBox(height: 14),
                    _Notice(
                      title: _errorText(text, code),
                      background: TataColors.errorSurface,
                      ink: TataColors.errorText,
                    ),
                  ],
                ],
              ),
            },
          ),
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context, SubscriptionPlan plan) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<SubscriptionBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(text.subConfirmTitle(plan.name)),
        content: Text(text.subConfirmBody(planPrice(plan))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(text.subCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(text.subConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const SubscriptionChangeConfirmed());
  }

  static String _errorText(AppLocalizations text, String? code) =>
      switch (code) {
        'PLAN_NOT_FOUND' => text.subErrPlan,
        'INVALID_RESPONSE' => text.subErrInvalidResponse,
        'NETWORK_UNAVAILABLE' => text.networkUnavailable,
        'ACCESS_DENIED' => text.accessDenied,
        'RATE_LIMITED' => text.rateLimited,
        _ => text.subErrGeneric,
      };

  /// What a plan adds over the plans listed before it, as Figma shows them.
  static Set<PlanCapability> _addedCapabilities(
    List<SubscriptionPlan> plans,
    int index,
  ) => {
    for (final capability in plans[index].capabilities)
      if (!plans
          .take(index)
          .any((plan) => plan.capabilities.contains(capability)))
        capability,
  };
}

/// Price as Figma writes it, for example `S/ 19.90`.
String planPrice(SubscriptionPlan plan) {
  final symbol = plan.currency == 'PEN' ? 'S/' : plan.currency;
  return '$symbol ${plan.monthlyPrice.toStringAsFixed(2)}';
}

String _capability(AppLocalizations text, PlanCapability capability) =>
    switch (capability) {
      PlanCapability.reminders => text.subCapReminders,
      PlanCapability.agenda => text.subCapAgenda,
      PlanCapability.intakeConfirmation => text.subCapConfirmation,
      PlanCapability.familyAlerts => text.subCapAlerts,
      PlanCapability.familyMonitoring => text.subCapMonitoring,
      PlanCapability.adherenceInsights => text.subCapInsights,
    };

String? _description(AppLocalizations text, SubscriptionPlan plan) =>
    switch (plan.code) {
      'ESSENTIAL' => text.subDescEssential,
      'FAMILY' => text.subDescFamily,
      _ => null,
    };

BoxDecoration _card(List<Color> colors, {Color? border}) => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: LinearGradient(colors: colors),
  border: border == null ? null : Border.all(color: border, width: 2),
  boxShadow: const [
    BoxShadow(color: Color(0x14173B70), blurRadius: 16, offset: Offset(0, 6)),
  ],
);

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.subscription, required this.now});
  final AccountSubscription subscription;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final renews = subscription.renewsAt;
    final progress = renews == null
        ? null
        : (1 - renews.difference(now).inMinutes / _cycle.inMinutes).clamp(
            0.0,
            1.0,
          );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: _card(const [Color(0xFFE8F5EB), Color(0xFFDDEFE3)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  text.subCurrentPlan(subscription.plan.name),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ),
              Text(
                text.subPerMonth(planPrice(subscription.plan)),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TataColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !subscription.active
                ? text.subInactive
                : renews == null
                ? text.subActive
                : text.subActiveRenews(
                    DateFormat('d MMM', locale).format(renews.toLocal()),
                  ),
            style: const TextStyle(fontSize: 13, color: TataColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: progress == null
                    ? const SizedBox.shrink()
                    : ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: const Color(0xFF2F6B45),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  subscription.active ? text.subActive : text.subInactive,
                  style: const TextStyle(fontSize: 12, color: _success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.added,
    required this.current,
    required this.selected,
    this.onTap,
  });

  final SubscriptionPlan plan;
  final Set<PlanCapability> added;
  final bool current;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final description = _description(text, plan);
    final colors = current
        ? const [Color(0xFFF1ECFF), Color(0xFFE7DFFB)]
        : const [Colors.white, Colors.white];
    return Semantics(
      button: !current,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: current ? null : onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: _card(
              colors,
              border: selected ? TataColors.primary : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: TataColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      current
                          ? text.subCurrentBadge
                          : selected
                          ? text.subSelectedBadge
                          : planPrice(plan),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TataColors.primary,
                      ),
                    ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TataColors.muted,
                    ),
                  ),
                ],
                if (added.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      // The server returns a set; Figma lists them in product order.
                      for (final capability in PlanCapability.values.where(
                        added.contains,
                      ))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: TataColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _capability(text, capability),
                              style: const TextStyle(
                                fontSize: 12,
                                color: TataColors.ink,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({required this.renewsAt, required this.plan});
  final DateTime renewsAt;
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
      decoration: _card(const [Color(0xFFECF5FC), Color(0xFFE0EDF7)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.subNextRenewal,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TataColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('d MMM y', locale).format(renewsAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  planPrice(plan),
                  style: const TextStyle(fontSize: 12, color: TataColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text.subKeepsHistory,
            style: const TextStyle(fontSize: 12, color: TataColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.background,
    required this.ink,
    this.body,
  });

  final String title;
  final String? body;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          if (body case final message?) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
          ],
        ],
      ),
    ),
  );
}
