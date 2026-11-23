import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/pin/pin_state.dart';
import 'package:tata/features/identity_subscription/presentation/screens/pin_screen.dart';
import 'package:tata/features/intake_execution/application/readmodels/agenda_week.dart';
import 'package:tata/features/intake_execution/application/readmodels/daily_progress.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_state.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_state.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_state.dart';
import 'package:tata/features/intake_execution/presentation/screens/adult_home_screen.dart';
import 'package:tata/features/intake_execution/presentation/screens/agenda_screen.dart';
import 'package:tata/features/intake_execution/presentation/screens/dose_detail_screen.dart';
import 'package:tata/features/intake_execution/presentation/screens/dose_outcome_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

/// Exercises each received clinical variant with normal and enlarged text.
void main() {
  setUpAll(loadTataFonts);
  final now = DateTime(2026, 11, 3, 7, 35);
  Intake dose(IntakeStatus status) => Intake(
    id: 'dose-1',
    olderAdultId: 'adult-1',
    medicationName: 'Losartán 50 mg',
    dose: '1 tableta',
    instructions: 'Con el desayuno',
    scheduledAt: DateTime(2026, 11, 3, 8).toUtc(),
    status: status,
    confirmedAt: status == IntakeStatus.confirmed || status == IntakeStatus.late
        ? DateTime(2026, 11, 3, 8, 2).toUtc()
        : null,
  );
  final screens = <String, Widget Function()>{
    for (final mode in PinMode.values)
      'pin_${mode.name}': () => PinScreen(
        mode: mode,
        adultName: 'Rosa Vargas',
        filled: 4,
        busy: false,
        locked: false,
        canSubmit: true,
        onDigit: (_) {},
        onDelete: () {},
        onSubmit: () {},
      ),
    'home': () => AdultHomeScreen(
      state: HomeState(
        status: HomeStatus.ready,
        next: dose(IntakeStatus.pending),
        progress: const DailyProgress(taken: 2, total: 3),
      ),
      adultName: 'Rosa Vargas',
      clock: () => now,
      onRefresh: () async {},
      onOpenMore: () {},
      onOpenAgenda: () {},
      onOpenDose: (_) {},
    ),
    'agenda': () => AgendaScreen(
      state: AgendaState(
        week: AgendaWeek.containing(now),
        selectedDay: now,
        status: AgendaStatus.ready,
        intakes: [dose(IntakeStatus.confirmed)],
      ),
      today: now,
      onSelectDay: (_) {},
      onMoveWeek: (_) {},
      onRetry: () async {},
      onOpenDose: (_) {},
      onBack: () {},
    ),
    for (final status in IntakeStatus.values)
      'detail_${status.name}': () => DoseDetailScreen(
        intake: dose(status),
        now: now,
        confirming: false,
        canConfirm: status == IntakeStatus.pending,
        onConfirm: () {},
        onBack: () {},
      ),
    for (final outcome in ConfirmationOutcome.values)
      'outcome_${outcome.name}': () => DoseOutcomeScreen(
        outcome: outcome,
        intake: dose(
          outcome == ConfirmationOutcome.omissionPreserved
              ? IntakeStatus.omitted
              : outcome == ConfirmationOutcome.late
              ? IntakeStatus.late
              : outcome == ConfirmationOutcome.pendingSync
              ? IntakeStatus.pending
              : IntakeStatus.confirmed,
        ),
        now: now,
        onBackHome: () {},
      ),
  };
  for (final entry in screens.entries) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('${entry.key} remains usable with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 883)
            : const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: TataTheme.light,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(
                key: const Key('adaptive-capture'),
                child: child!,
              ),
            ),
            home: entry.value(),
          ),
        );
        await tester.runAsync(() async {
          for (final asset in [
            'home_tablet.png',
            'dose_water_plant.png',
            'dose_confetti.png',
          ]) {
            await precacheImage(
              AssetImage('assets/illustrations/$asset'),
              tester.element(find.byType(Scaffold).first),
            );
          }
        });
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow or layout error',
        );
        await captureWidget(
          tester,
          find.byKey(const Key('adaptive-capture')),
          '${entry.key}_${scale == 1 ? "normal" : "large"}',
        );
      });
    }
  }
}
