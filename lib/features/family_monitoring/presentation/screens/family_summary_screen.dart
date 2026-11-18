import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../application/ports/contact_launcher.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../bloc/summary/family_summary_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/family_summary_cards.dart';
import '../widgets/monitoring_widgets.dart';

/// Home of the caregiver: weekly adherence, today's doses, next dose and what needs
/// attention for the person being followed.
class FamilySummaryScreen extends StatelessWidget {
  const FamilySummaryScreen({
    super.key,
    required this.launcher,
    required this.onTab,
    this.onHistory,
    this.onOpenAgenda,
    this.onChoosePerson,
    this.onAddMedication,
    this.onOpenAlerts,
    this.onLinkAnother,
    this.onOpenStock,
  });

  final ContactLauncher launcher;
  final ValueChanged<CaregiverTab> onTab;
  final VoidCallback? onHistory;

  /// Read-only agenda and selection of the followed person, supplied by the shell.
  final VoidCallback? onOpenAgenda;
  final VoidCallback? onChoosePerson;
  final VoidCallback? onAddMedication;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onLinkAnother;

  /// Opens the stock of a medication that needs restocking; owned by the host.
  final ValueChanged<StockAttention>? onOpenStock;

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
            return Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          TataColors.background,
                          Color(0xFFFCFBFF),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -12,
                  right: 0,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/illustrations/summary_glow.png',
                      width: 316,
                      height: 386,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<FamilySummaryBloc>();
                    final done = bloc.stream.firstWhere(
                      (state) => state.status != FamilySummaryStatus.loading,
                      orElse: () => const FamilySummaryState(
                        status: FamilySummaryStatus.failure,
                      ),
                    );
                    bloc.add(const FamilySummaryRequested());
                    await done;
                  },
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: onChoosePerson,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Semantics(
                                        header: true,
                                        child: Text(
                                          text.fmSummaryTitle,
                                          style: TataTypography.heading
                                              .copyWith(fontSize: 29),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              summary?.olderAdultName ??
                                                  context
                                                      .read<FamilySummaryBloc>()
                                                      .olderAdultName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: TataColors.primary,
                                              ),
                                            ),
                                          ),
                                          if (onChoosePerson != null)
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InitialsAvatar(
                              name:
                                  summary?.olderAdultName ??
                                  context
                                      .read<FamilySummaryBloc>()
                                      .olderAdultName,
                              size: 40,
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              onPressed: onOpenAlerts,
                              tooltip: text.fmSeeAlerts,
                              icon: SvgPicture.asset(
                                'assets/icons/summary_bell.svg',
                                width: 22,
                                height: 22,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (state.status == FamilySummaryStatus.failure)
                          _Failure(state: state)
                        else if (summary == null)
                          MonitoringLoading(label: text.fmSummaryLoading)
                        else
                          FamilySummaryCards(
                            summary: summary,
                            onAgenda: onOpenAgenda,
                            onHistory: onHistory,
                            onContact: () => context
                                .read<FamilySummaryBloc>()
                                .add(const FamilyContactRequested()),
                            onAlerts: onOpenAlerts,
                            onStock: onOpenStock,
                            onAddMedication: onAddMedication,
                            onLinkAnother: onLinkAnother,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showContact(BuildContext context) =>
      showFamilyContact(context, launcher);
}

/// Contact dialog of the followed person (Figma 563:727 and 563:4145), shared
/// by the summary and the person profile; the [FamilySummaryBloc] resolves it.
Future<void> showFamilyContact(
  BuildContext context,
  ContactLauncher launcher,
) async {
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

class _Failure extends StatelessWidget {
  const _Failure({required this.state});
  final FamilySummaryState state;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final code = state.errorCode;
    if (isAccessFailure(code)) {
      // Figma 563:2308: a warm, centred card that names the person.
      final name = context.read<FamilySummaryBloc>().olderAdultName;
      return Semantics(
        liveRegion: true,
        container: true,
        child: MonitoringCard(
          color: const Color(0xFFFFF4E2),
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 64),
          child: Column(
            children: [
              Text(
                text.fmRestrictedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text.fmRestrictedBody(name),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4F5B70)),
              ),
            ],
          ),
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

class _ContactDialog extends StatelessWidget {
  const _ContactDialog({required this.launcher});
  final ContactLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<FamilySummaryBloc, FamilySummaryState>(
      listenWhen: (a, b) => a.contact != null && b.contact == null,
      // Closes this dialog only while it is still on top: after the back
      // button already closed it, popping again would leave the screen too.
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop();
        }
      },
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
                onPressed: () => bloc.add(
                  FamilyContactRequested(channelType: dialog.channelType),
                ),
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
