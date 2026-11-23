import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/alerts/alerts_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/monitoring_widgets.dart';

/// Read-only agenda of the followed adult for the loaded local calendar day.
/// Uses the authorized timeline already owned by the family shell; it does not
/// expose the adult-only confirmation action or filter out overdue/omitted doses.
class FollowedAgendaSheet extends StatelessWidget {
  const FollowedAgendaSheet({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AlertsBloc, AlertsState>(
    builder: (context, state) {
      final text = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final doses = [...state.doses]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.fmTodayAgenda,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (state.olderAdultName.isNotEmpty) Text(state.olderAdultName),
              if (state.day case final day?)
                Text(DateFormat.yMMMMEEEEd(locale).format(day)),
              const SizedBox(height: 16),
              Expanded(
                child: switch (state.status) {
                  AlertsStatus.loading => MonitoringLoading(
                    label: text.fmSummaryLoading,
                  ),
                  AlertsStatus.failure => MonitoringError(
                    message: monitoringErrorText(text, state.errorCode),
                    onRetry: () =>
                        context.read<AlertsBloc>().add(const AlertsRequested()),
                  ),
                  _ => RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<AlertsBloc>();
                      final done = bloc.stream.firstWhere(
                        (value) => value.status != AlertsStatus.loading,
                        orElse: () =>
                            const AlertsState(status: AlertsStatus.failure),
                      );
                      bloc.add(const AlertsRequested());
                      await done;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: doses.isEmpty ? 1 : doses.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        if (doses.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(text.fmAgendaEmpty),
                          );
                        }
                        final dose = doses[index];
                        final status = switch (dose.status) {
                          'CONFIRMED' => text.fmDoseConfirmed,
                          'LATE' => text.fmDoseLate,
                          'OMITTED' => text.fmDoseOmitted,
                          _ => text.fmDosePending,
                        };
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          isThreeLine: true,
                          title: Text(dose.medicationName),
                          subtitle: Text('${dose.dose}\n$status'),
                          leading: Text(
                            DateFormat(
                              'h:mm a',
                              locale,
                            ).format(dose.scheduledAt.toLocal()),
                          ),
                        );
                      },
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
