import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../bloc/treatment_list/treatment_list_bloc.dart';
import '../bloc/treatment_list/treatment_list_event.dart';
import '../bloc/treatment_list/treatment_list_state.dart';
import '../texts/treatment_texts.dart';

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
        appBar: AppBar(title: Text(text.tmTreatmentsTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onNew,
          icon: const Icon(Icons.add),
          label: Text(text.tmNewTreatment),
        ),
        body: switch (state.status) {
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
              child: Text(text.tmNoTreatments, textAlign: TextAlign.center),
            ),
          ),
          _ => RefreshIndicator(
            onRefresh: () async => context.read<TreatmentListBloc>().add(
              const TreatmentListRequested(),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                for (final treatment in state.treatments)
                  Card(
                    child: ListTile(
                      title: Text(treatment.name),
                      subtitle: Text(
                        treatmentStatusText(text, treatment.status),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onOpen(treatment),
                    ),
                  ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
