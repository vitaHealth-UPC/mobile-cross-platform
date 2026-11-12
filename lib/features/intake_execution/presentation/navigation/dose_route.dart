import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../bloc/dose/dose_bloc.dart';
import '../bloc/dose/dose_event.dart';
import '../bloc/dose/dose_state.dart';
import '../screens/dose_detail_screen.dart';
import '../screens/dose_outcome_screen.dart';

/// Owns one [DoseBloc]: shows the dose, then the server-decided outcome.
class DoseRoute extends StatelessWidget {
  const DoseRoute({
    super.key,
    required this.createBloc,
    required this.onBack,
    required this.onBackHome,
    required this.onSessionInvalidated,
    this.clock = DateTime.now,
    this.onMore,
    this.onMedications,
    this.onAgenda,
  });

  final DoseBloc Function() createBloc;
  final VoidCallback onBack;

  /// Leaves the confirmation flow for the adult home.
  final VoidCallback onBackHome;
  final VoidCallback onSessionInvalidated;
  final Clock clock;
  final VoidCallback? onMore;
  final VoidCallback? onMedications;
  final VoidCallback? onAgenda;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()..add(const DoseRequested()),
    child: BlocConsumer<DoseBloc, DoseState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (const {
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
          'ACCESS_DENIED',
        }.contains(state.errorCode)) {
          onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final bloc = context.read<DoseBloc>();
        final error = switch (state.errorCode) {
          null => null,
          'NETWORK_UNAVAILABLE' => text.networkUnavailable,
          'RATE_LIMITED' => text.rateLimited,
          'INTAKE_NOT_CONFIRMABLE' => text.doseNotConfirmable,
          _ => text.homeErrorBody,
        };
        final now = clock();
        return switch ((state.status, state.intake, state.outcome)) {
          (DoseStatus.ready, final intake?, final outcome?) =>
            DoseOutcomeScreen(
              outcome: outcome,
              intake: intake,
              next: state.next,
              now: now,
              onBackHome: onBackHome,
              onMore: onMore,
              onMedications: onMedications,
              onAgenda: onAgenda,
            ),
          (DoseStatus.ready, final intake?, null) => DoseDetailScreen(
            intake: intake,
            now: now,
            confirming: state.confirming,
            canConfirm: state.canConfirm,
            errorText: error,
            onConfirm: () => bloc.add(const DoseConfirmRequested()),
            onBack: onBack,
            onBackHome: onBackHome,
            onMore: onMore,
            onMedications: onMedications,
            onAgenda: onAgenda,
          ),
          (DoseStatus.failure, _, _) => _Failure(
            title: text.doseErrorTitle,
            body: error,
            retry: text.homeRetry,
            onRetry: () => bloc.add(const DoseRequested()),
            onBack: onBack,
          ),
          _ => Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: text.doseLoading,
              ),
            ),
          ),
        };
      },
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.title,
    required this.retry,
    required this.onRetry,
    required this.onBack,
    this.body,
  });

  final String title;
  final String? body;
  final String retry;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (body case final message?) ...[
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onRetry, child: Text(retry)),
              TextButton(onPressed: onBack, child: Text(text.back)),
            ],
          ),
        ),
      ),
    );
  }
}
