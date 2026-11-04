import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_confirmation.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/readmodels/confirmation_receipt.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_week_agenda.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_state.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_state.dart';
import 'package:tata/features/intake_execution/presentation/navigation/agenda_route.dart';
import 'package:tata/features/intake_execution/presentation/navigation/dose_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

Intake dose(
  String id,
  IntakeStatus status,
  DateTime localTime, {
  String name = 'Losartán',
}) => Intake(
  id: id,
  olderAdultId: 'adult-A',
  medicationName: name,
  dose: '1 tableta',
  instructions: 'Con el desayuno',
  scheduledAt: localTime.toUtc(),
  status: status,
  confirmedAt: status == IntakeStatus.confirmed || status == IntakeStatus.late
      ? localTime.toUtc()
      : null,
);

/// Reader and confirmation double with scripted, mutable answers.
final class FakeIntakes implements IntakeReader, IntakeConfirmation {
  FakeIntakes({
    required this.detailResults,
    this.confirmResult,
    this.agendaResult = const AppSuccess([]),
    this.nextResult = const AppSuccess(null),
  });

  /// Consumed in order; the last answer repeats.
  final List<AppResult<Intake>> detailResults;
  AppResult<ConfirmationReceipt>? confirmResult;
  AppResult<List<Intake>> agendaResult;
  AppResult<Intake?> nextResult;
  final confirmed = <String>[];
  final agendaRanges = <(DateTime, DateTime)>[];

  @override
  Future<AppResult<Intake>> detail(String intakeId) async =>
      detailResults.length > 1
      ? detailResults.removeAt(0)
      : detailResults.single;

  @override
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId) async {
    confirmed.add(intakeId);
    return confirmResult!;
  }

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async {
    agendaRanges.add((from, to));
    return agendaResult;
  }

  @override
  Future<AppResult<Intake?>> next() async => nextResult;
}

void main() {
  setUpAll(loadTataFonts);
  final now = DateTime(2026, 11, 3, 7, 50);
  final pending = dose('d1', IntakeStatus.pending, DateTime(2026, 11, 3, 8));

  DoseBloc bloc(FakeIntakes fake) => DoseBloc(
    intakeId: 'd1',
    detail: GetIntakeDetail(fake),
    confirm: ConfirmIntake(fake),
    next: GetNextIntake(fake),
  );

  Future<DoseState> confirmWith(FakeIntakes fake) async {
    final subject = bloc(fake)..add(const DoseRequested());
    await subject.stream.firstWhere((s) => s.status == DoseStatus.ready);
    subject.add(const DoseConfirmRequested());
    final done = await subject.stream.firstWhere(
      (s) => s.outcome != null || (s.errorCode != null && !s.confirming),
    );
    await subject.close();
    return done;
  }

  group('DoseBloc outcomes come from the server', () {
    for (final (status, replay, expected) in [
      (IntakeStatus.confirmed, false, ConfirmationOutcome.confirmed),
      (IntakeStatus.late, false, ConfirmationOutcome.late),
      (IntakeStatus.confirmed, true, ConfirmationOutcome.alreadyConfirmed),
    ]) {
      test('$status replay=$replay -> $expected', () async {
        final fake = FakeIntakes(
          detailResults: [AppSuccess(pending)],
          confirmResult: AppSuccess(
            ConfirmationReceipt(
              intake: dose('d1', status, DateTime(2026, 11, 3, 8)),
              alreadyConfirmed: replay,
            ),
          ),
          nextResult: AppSuccess(
            dose('d2', IntakeStatus.pending, DateTime(2026, 11, 3, 20)),
          ),
        );
        final state = await confirmWith(fake);
        expect(state.outcome, expected);
        expect(state.next?.id, 'd2');
        expect(fake.confirmed, ['d1']);
      });
    }

    test('409 is reread: an omission is preserved, not assumed', () async {
      final fake = FakeIntakes(
        detailResults: [
          AppSuccess(pending),
          AppSuccess(
            dose('d1', IntakeStatus.omitted, DateTime(2026, 11, 3, 8)),
          ),
        ],
        confirmResult: const AppFailure('INTAKE_NOT_CONFIRMABLE'),
      );
      expect(
        (await confirmWith(fake)).outcome,
        ConfirmationOutcome.omissionPreserved,
      );
    });

    test('409 reread as taken means another device confirmed it', () async {
      final fake = FakeIntakes(
        detailResults: [
          AppSuccess(pending),
          AppSuccess(
            dose('d1', IntakeStatus.confirmed, DateTime(2026, 11, 3, 8)),
          ),
        ],
        confirmResult: const AppFailure('INTAKE_NOT_CONFIRMABLE'),
      );
      expect(
        (await confirmWith(fake)).outcome,
        ConfirmationOutcome.alreadyConfirmed,
      );
    });

    test('a failed reread after 409 never claims an omission', () async {
      final fake = FakeIntakes(
        detailResults: [
          AppSuccess(pending),
          const AppFailure('NETWORK_UNAVAILABLE'),
        ],
        confirmResult: const AppFailure('INTAKE_NOT_CONFIRMABLE'),
      );
      final state = await confirmWith(fake);
      expect(state.outcome, isNull);
      expect(state.errorCode, 'INTAKE_NOT_CONFIRMABLE');
    });

    test('a network failure keeps the dose pending and confirmable', () async {
      final fake = FakeIntakes(
        detailResults: [AppSuccess(pending)],
        confirmResult: const AppFailure('NETWORK_UNAVAILABLE'),
      );
      final state = await confirmWith(fake);
      expect(state.outcome, isNull);
      expect(state.errorCode, 'NETWORK_UNAVAILABLE');
      expect(state.canConfirm, isTrue);
    });
  });

  group('AgendaBloc', () {
    test('selects days locally and requests a new range per week', () async {
      final fake = FakeIntakes(detailResults: [AppSuccess(pending)]);
      final subject = AgendaBloc(agenda: GetWeekAgenda(fake), clock: () => now)
        ..add(const AgendaRequested());
      await subject.stream.firstWhere((s) => s.status == AgendaStatus.ready);
      expect(fake.agendaRanges.single.$1, DateTime(2026, 11, 2).toUtc());

      subject.add(AgendaDaySelected(DateTime(2026, 11, 6)));
      await subject.stream.first;
      expect(subject.state.selectedDay, DateTime(2026, 11, 6));
      expect(fake.agendaRanges, hasLength(1));

      subject.add(AgendaDaySelected(DateTime(2026, 11, 20)));
      await Future<void>.delayed(Duration.zero);
      expect(subject.state.selectedDay, DateTime(2026, 11, 6));

      subject.add(const AgendaWeekMoved(1));
      await subject.stream.firstWhere(
        (s) => s.status == AgendaStatus.ready && s.week.start.day == 9,
      );
      expect(fake.agendaRanges.last.$1, DateTime(2026, 11, 9).toUtc());
      expect(subject.state.selectedDay, DateTime(2026, 11, 13));
      await subject.close();
    });
  });

  group('screens', () {
    void phone(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(1179, 2649)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Widget host(Widget child) => RepaintBoundary(
      key: const Key('capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

    Future<void> precache(WidgetTester tester, Type type) => tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/illustrations/home_tablet.png'),
        tester.element(find.byType(type)),
      ),
    );

    testWidgets('pending dose confirms by touch and shows the outcome', (
      tester,
    ) async {
      phone(tester);
      var home = 0;
      final fake = FakeIntakes(
        detailResults: [AppSuccess(pending)],
        confirmResult: AppSuccess(
          ConfirmationReceipt(
            intake: dose(
              'd1',
              IntakeStatus.confirmed,
              DateTime(2026, 11, 3, 7, 52),
            ),
            alreadyConfirmed: false,
          ),
        ),
        nextResult: AppSuccess(
          dose(
            'd2',
            IntakeStatus.pending,
            DateTime(2026, 11, 3, 20),
            name: 'Metformina',
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          DoseRoute(
            createBloc: () => bloc(fake),
            clock: () => now,
            onBack: () {},
            onBackHome: () => home++,
            onSessionInvalidated: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await precache(tester, DoseRoute);
      await tester.pumpAndSettle();

      expect(find.text('Detalle de toma'), findsOneWidget);
      expect(find.text('Losartán'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Con el desayuno'), findsOneWidget);
      await captureWidget(
        tester,
        find.byKey(const Key('capture')),
        'dose_pending',
      );

      await tester.ensureVisible(find.text('Confirmar toma'));
      await tester.tap(find.text('Confirmar toma'));
      await tester.pumpAndSettle();

      expect(fake.confirmed, ['d1']);
      expect(find.text('¡Bien hecho!'), findsOneWidget);
      expect(find.text('Toma confirmada ♡'), findsOneWidget);
      expect(find.text('Metformina'), findsOneWidget);
      await captureWidget(
        tester,
        find.byKey(const Key('capture')),
        'dose_confirmed',
      );

      await tester.tap(find.text('Volver al inicio'));
      expect(home, 1);
    });

    testWidgets('omitted dose explains the status and offers no confirm', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          DoseRoute(
            createBloc: () => bloc(
              FakeIntakes(
                detailResults: [
                  AppSuccess(
                    dose('d1', IntakeStatus.omitted, DateTime(2026, 11, 3, 6)),
                  ),
                ],
              ),
            ),
            clock: () => now,
            onBack: () {},
            onBackHome: () {},
            onSessionInvalidated: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Omitida'), findsOneWidget);
      expect(
        find.text('El periodo permitido terminó sin confirmación.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar toma'), findsNothing);
    });

    testWidgets(
      'agenda lists the selected day with statuses and opens a dose',
      (tester) async {
        phone(tester);
        final opened = <String>[];
        final fake = FakeIntakes(
          detailResults: [AppSuccess(pending)],
          agendaResult: AppSuccess([
            dose('a', IntakeStatus.confirmed, DateTime(2026, 11, 3, 8)),
            dose(
              'b',
              IntakeStatus.pending,
              DateTime(2026, 11, 3, 13),
              name: 'Vitamina D3',
            ),
            dose(
              'c',
              IntakeStatus.late,
              DateTime(2026, 11, 3, 20),
              name: 'Amlodipino',
            ),
            dose(
              'z',
              IntakeStatus.pending,
              DateTime(2026, 11, 4, 8),
              name: 'Mañana',
            ),
          ]),
        );
        await tester.pumpWidget(
          host(
            AgendaRoute(
              createBloc: () =>
                  AgendaBloc(agenda: GetWeekAgenda(fake), clock: () => now),
              clock: () => now,
              onOpenDose: (id) async => opened.add(id),
              onSessionInvalidated: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Agenda semanal'), findsOneWidget);
        expect(find.text('2 – 8 de noviembre'), findsOneWidget);
        expect(find.text('Vitamina D3'), findsOneWidget);
        expect(find.text('Amlodipino'), findsOneWidget);
        expect(find.text('Mañana'), findsNothing, reason: 'another day');
        await captureWidget(tester, find.byKey(const Key('capture')), 'agenda');

        await tester.tap(find.text('Vitamina D3'));
        await tester.pumpAndSettle();
        expect(opened, ['b']);
        expect(fake.agendaRanges, hasLength(2), reason: 'reloads on return');

        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();
        expect(find.text('Mañana'), findsOneWidget);
        expect(find.text('Vitamina D3'), findsNothing);
      },
    );
  });
}
