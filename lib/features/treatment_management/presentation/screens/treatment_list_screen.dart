import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/treatment_detail.dart';
import '../bloc/treatment_list/treatment_list_bloc.dart';
import '../bloc/treatment_list/treatment_list_event.dart';
import '../bloc/treatment_list/treatment_list_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/treatment_visuals.dart';

/// Treatments of the selected adult. Opening one and creating a new one are delegated to
/// the route so this screen stays a pure view.
class TreatmentListScreen extends StatelessWidget {
  const TreatmentListScreen({
    super.key,
    required this.onOpen,
    required this.onNew,
    required this.onSessionInvalidated,
  });

  final void Function(TreatmentDetail treatment) onOpen;
  final VoidCallback onNew;
  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<TreatmentListBloc, TreatmentListState>(
      listenWhen: (_, state) => isSessionFailure(state.errorCode),
      listener: (_, _) => onSessionInvalidated(),
      builder: (context, state) => Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
            child: ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: Text(text.tmNewTreatment),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TreatmentHeader(
                  title: text.tmTreatmentsTitle,
                  backLabel: text.back,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: switch (state.status) {
                    TreatmentListStatus.loading when state.treatments.isEmpty =>
                      const Center(child: CircularProgressIndicator()),
                    TreatmentListStatus.failure => ErrorRetry(
                      message: treatmentErrorText(text, state.errorCode)!,
                      retryLabel: text.tmRetry,
                      onRetry: () => context.read<TreatmentListBloc>().add(
                        const TreatmentListRequested(),
                      ),
                    ),
                    _ when state.treatments.isEmpty => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          text.tmNoTreatments,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _ => RefreshIndicator(
                      onRefresh: () async => context
                          .read<TreatmentListBloc>()
                          .add(const TreatmentListRequested()),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                        children: [
                          if (state.activated) ...[
                            TreatmentNotice(message: text.tmActivated),
                            const SizedBox(height: 16),
                          ],
                          for (final treatment in state.treatments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TreatmentSurface(
                                padding: EdgeInsets.zero,
                                child: Material(
                                  type: MaterialType.transparency,
                                  borderRadius: BorderRadius.circular(18),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    title: Text(
                                      treatment.name,
                                      style: treatmentSectionStyle(context),
                                    ),
                                    subtitle: Text(
                                      treatmentStatusText(
                                        text,
                                        treatment.status,
                                      ),
                                      style: treatmentSupportingStyle(context),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => onOpen(treatment),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
