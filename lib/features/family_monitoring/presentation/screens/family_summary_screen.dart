import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/ports/contact_launcher.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/value_objects/adherence_counts.dart';
import '../bloc/summary/family_summary_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/monitoring_widgets.dart';

/// Home of the caregiver: weekly adherence, today's doses, next dose and what needs
/// attention for the person being followed.
class FamilySummaryScreen extends StatelessWidget {
  const FamilySummaryScreen({
    super.key,
    required this.launcher,
    required this.onTab,
    this.onHistory,
    this.onAddMedication,
    this.onOpenAlerts,
    this.onLinkAnother,
  });

  final ContactLauncher launcher;
  final ValueChanged<CaregiverTab> onTab;
  final VoidCallback? onHistory;
  final VoidCallback? onAddMedication;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onLinkAnother;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final tight = DefaultTextStyle.merge(
      style: const TextStyle(letterSpacing: 0, height: 1.2),
      child: CaregiverTabBar(selected: CaregiverTab.home, onSelected: onTab),
    );
    return Scaffold(
      backgroundColor: TataColors.background,
      extendBody: true,
      bottomNavigationBar: tight,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<FamilySummaryBloc, FamilySummaryState>(
          listenWhen: (a, b) => a.contact == null && b.contact != null,
          listener: (context, state) => _showContact(context),
          builder: (context, state) {
            final summary = state.summary;
            return RefreshIndicator(
              onRefresh: () async => context.read<FamilySummaryBloc>().add(
                const FamilySummaryRequested(),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  MediaQuery.paddingOf(context).bottom + 110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonitoringHeader(
                      title: text.fmSummaryTitle,
                      subtitle: summary?.olderAdultName,
                    ),
                    const SizedBox(height: 20),
                    if (state.status == FamilySummaryStatus.failure)
                      _Failure(state: state)
                    else if (summary == null)
                      MonitoringLoading(label: text.fmSummaryLoading)
                    else
                      _Content(
                        summary: summary,
                        onHistory: onHistory,
                        onAddMedication: onAddMedication,
                        onOpenAlerts: onOpenAlerts,
                        onLinkAnother: onLinkAnother,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showContact(BuildContext context) async {
    final bloc = context.read<FamilySummaryBloc>();
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _ContactDialog(launcher: launcher),
      ),
    );
    bloc.add(const FamilyContactDismissed());
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.state});
  final FamilySummaryState state;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final code = state.errorCode;
    if (isAccessFailure(code)) {
      return MonitoringCard(
        color: TataColors.lavender,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.fmRestrictedTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              text.fmErrorAccess,
              style: const TextStyle(color: TataColors.muted),
            ),
          ],
        ),
      );
    }
    return MonitoringError(
      message: monitoringErrorText(text, code),
      onRetry: () =>
          context.read<FamilySummaryBloc>().add(const FamilySummaryRequested()),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.summary,
    this.onHistory,
    this.onAddMedication,
    this.onOpenAlerts,
    this.onLinkAnother,
  });

  final FamilySummary summary;
  final VoidCallback? onHistory;
  final VoidCallback? onAddMedication;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onLinkAnother;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final weekly = summary.weekly;
    final today = summary.today;
    final next = summary.nextDose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.openAlerts.isNotEmpty) ...[
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onOpenAlerts,
            child: MonitoringCard(
              color: TataColors.errorSurface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text.fmPendingSummary(summary.openAlerts.length),
                      style: const TextStyle(
                        color: TataColors.errorText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    text.fmSeeAlerts,
                    style: const TextStyle(color: TataColors.errorText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        MonitoringCard(
          color: TataColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.fmWeeklyAdherence,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _percent(weekly, text),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: TataColors.primary,
                ),
              ),
              Text(
                weekly.total == 0
                    ? text.fmNoResolved
                    : text.fmWeeklyConfirmed(weekly.confirmed, weekly.total),
                style: const TextStyle(color: TataColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MonitoringCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.fmToday,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      text.fmDosesCompleted,
                      style: const TextStyle(color: TataColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                text.fmTodayProgress(today.confirmed, today.total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: TataColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MonitoringCard(
          color: TataColors.mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.fmNextDose,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (next == null)
                Text(text.fmNoNextDose)
              else ...[
                Text(
                  next.medicationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                Text(
                  '${next.dose} · ${DateFormat.jm(locale).format(next.scheduledAt.toLocal())}',
                  style: const TextStyle(color: TataColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        MonitoringCard(
          color: TataColors.infoSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.fmAttention,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (!summary.inventoryAvailable)
                Text(text.fmInventoryUnavailable)
              else if (summary.stockAttention.isEmpty)
                Text(text.fmNoRestock)
              else
                for (final stock in summary.stockAttention)
                  Text(text.fmLowStock(stock.remaining, stock.medicationName)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          text.fmQuickMonitoring,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(label: text.fmQuickHistory, onTap: onHistory),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                label: text.fmQuickContact,
                onTap: () => context.read<FamilySummaryBloc>().add(
                  const FamilyContactRequested(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MonitoringPrimaryButton(
          label: text.fmAddMedication,
          onPressed: onAddMedication,
        ),
        if (onLinkAnother != null)
          TextButton(
            onPressed: onLinkAnother,
            child: Text(text.fmMoreLinkPerson),
          ),
      ],
    );
  }

  String _percent(AdherenceCounts counts, AppLocalizations text) {
    final value = counts.percentage;
    return value == null ? text.fmNoData : '${value.round()}%';
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TataColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: onTap == null ? TataColors.muted : TataColors.primary,
          ),
        ),
      ),
    ),
  );
}

class _ContactDialog extends StatelessWidget {
  const _ContactDialog({required this.launcher});
  final ContactLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<FamilySummaryBloc, FamilySummaryState>(
      listenWhen: (a, b) => a.contact != null && b.contact == null,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final dialog = state.contact;
        final bloc = context.read<FamilySummaryBloc>();
        final Widget body;
        if (dialog == null || dialog.loading) {
          body = Text(text.fmContactLoading);
        } else if (dialog.errorCode != null) {
          body = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monitoringErrorText(text, dialog.errorCode)),
              TextButton(
                onPressed: () => bloc.add(const FamilyContactRequested()),
                child: Text(text.fmContactRetry),
              ),
            ],
          );
        } else {
          body = ContactChannelView(option: dialog.option!, launcher: launcher);
        }
        return AlertDialog(
          title: Text(
            dialog?.option?.firstName == null
                ? text.fmContactAction
                : text.fmContactActionNamed(dialog!.option!.firstName!),
          ),
          content: body,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(text.fmClose),
            ),
          ],
        );
      },
    );
  }
}
