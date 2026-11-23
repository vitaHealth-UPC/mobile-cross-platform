import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../bloc/my_medications/my_medications_bloc.dart';
import '../texts/treatment_texts.dart';

/// Read-only catalog of the signed-in adult: active medications, next dose and history.
class MyMedicationsScreen extends StatelessWidget {
  const MyMedicationsScreen({super.key, required this.onSessionInvalidated});

  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<MyMedicationsBloc, MyMedicationsState>(
      listenWhen: (_, state) => isSessionFailure(state.errorCode),
      listener: (_, _) => onSessionInvalidated(),
      builder: (context, state) {
        final bloc = context.read<MyMedicationsBloc>();
        final shown = state.history ? state.inactive : state.active;
        final next = state.nextDose;
        return Scaffold(
          appBar: AppBar(title: Text(text.tmMyMedicationsTitle)),
          body: switch (state.status) {
            MyMedicationsStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            MyMedicationsStatus.failure => ErrorRetry(
              message: treatmentErrorText(text, state.errorCode)!,
              retryLabel: text.tmRetry,
              onRetry: () => bloc.add(const MyMedicationsRequested()),
            ),
            MyMedicationsStatus.ready => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(text.tmNextDose),
                    subtitle: Text(
                      next == null
                          ? text.tmNoNextDose
                          : '${next.medicationName} · '
                                '${DateFormat.MMMd(Localizations.localeOf(context).toString()).add_Hm().format(next.scheduledAt.toLocal())}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(text.tmActiveTab)),
                    ButtonSegment(value: true, label: Text(text.tmHistoryTab)),
                  ],
                  selected: {state.history},
                  onSelectionChanged: (value) =>
                      bloc.add(MyMedicationsHistorySelected(value.first)),
                ),
                const SizedBox(height: 8),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.history
                          ? text.tmNoHistory
                          : text.tmNoActiveMedications,
                    ),
                  ),
                for (final medication in shown) _card(medication),
              ],
            ),
          },
        );
      },
    );
  }

  Widget _card(MyMedication medication) => Card(
    child: ListTile(
      title: Text(medication.name),
      subtitle: Text(
        [
          medication.presentation,
          medication.dose,
          medication.scheduleLabel,
        ].where((part) => part.trim().isNotEmpty).join(' · '),
      ),
    ),
  );
}
