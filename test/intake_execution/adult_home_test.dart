import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_bloc.dart';
import 'package:tata/features/intake_execution/presentation/navigation/adult_home_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

/// Configurable reader double; production reads through the adult session.
final class FakeIntakeReader implements IntakeReader {
  FakeIntakeReader({required this.nextResult, required this.agendaResult});

  AppResult<Intake?> nextResult;
  AppResult<List<Intake>> agendaResult;
  int reads = 0;

  @override
  Future<AppResult<Intake?>> next() async {
    reads++;
    return nextResult;
  }

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      agendaResult;

  @override
  Future<AppResult<Intake>> detail(String intakeId) async =>
      const AppFailure('INTAKE_NOT_FOUND');
}

void main() {
  setUpAll(loadTataFonts);
  final now = DateTime(2026, 11, 3, 7, 35);
  Intake intake(String id, IntakeStatus status, DateTime at) => Intake(
    id: id,
    olderAdultId: 'adult-A',
    medicationName: 'Losartán 50 mg',
    dose: '1 tableta',
    scheduledAt: at.toUtc(),
    status: status,
  );

  Future<void> pumpHome(
    WidgetTester tester,
    FakeIntakeReader reader, {
    VoidCallback? onInvalidated,
    VoidCallback? onMore,
    Future<void> Function()? onAgenda,
    Future<void> Function(String)? onDose,
  }) async {
    tester.view
      ..physicalSize = const Size(1179, 2649)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('home-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdultHomeRoute(
            createBloc: () => HomeBloc(
              next: GetNextIntake(reader),
              progress: GetDailyProgress(reader, () => now),
            ),
            adultName: 'Rosa Vargas',
            clock: () => now,
            onOpenMore: onMore ?? () {},
            onSessionInvalidated: onInvalidated ?? () {},
            onOpenAgenda: onAgenda,
            onOpenDose: onDose,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/illustrations/home_tablet.png'),
        tester.element(find.byType(AdultHomeRoute)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the next intake, time remaining and today progress', (
    tester,
  ) async {
    final reader = FakeIntakeReader(
      nextResult: AppSuccess(
        intake('next', IntakeStatus.pending, DateTime(2026, 11, 3, 8)),
      ),
      agendaResult: AppSuccess([
        intake('a', IntakeStatus.confirmed, DateTime(2026, 11, 3, 6)),
        intake('b', IntakeStatus.late, DateTime(2026, 11, 3, 7)),
        intake('next', IntakeStatus.pending, DateTime(2026, 11, 3, 8)),
      ]),
    );
    await pumpHome(tester, reader);

    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Martes, 3 de noviembre'), findsOneWidget);
    expect(find.text('RV'), findsOneWidget);
    expect(find.text('Próxima toma'), findsOneWidget);
    // intl separates the period with non-breaking spaces.
    expect(find.textContaining(RegExp(r'^8:00\sa\.\sm\.$')), findsOneWidget);
    expect(find.text('Losartán 50 mg'), findsOneWidget);
    expect(find.text('En 25 min'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('¡Vas muy bien!'), findsOneWidget);
    // Voice and agenda flows are not in Flutter yet, so no dead shortcuts.
    expect(find.text('Confirmar con voz'), findsNothing);
    await captureWidget(tester, find.byKey(const Key('home-capture')), 'home');
  });

  testWidgets('no pending intake is an empty state, not an error', (
    tester,
  ) async {
    await pumpHome(
      tester,
      FakeIntakeReader(
        nextResult: const AppSuccess(null),
        agendaResult: const AppSuccess([]),
      ),
    );
    expect(find.text('Sin próxima toma'), findsOneWidget);
    expect(find.text('Sin tomas programadas'), findsOneWidget);
  });

  testWidgets('a failure can be retried and lost access is reported', (
    tester,
  ) async {
    final reader = FakeIntakeReader(
      nextResult: const AppFailure('NETWORK_UNAVAILABLE'),
      agendaResult: const AppFailure('NETWORK_UNAVAILABLE'),
    );
    var invalidated = 0;
    await pumpHome(tester, reader, onInvalidated: () => invalidated++);
    expect(find.text('No pudimos cargar tu próxima toma'), findsOneWidget);
    expect(find.text('No hay conexión. Inténtalo nuevamente.'), findsOneWidget);

    reader.nextResult = const AppFailure('AUTHENTICATION_REQUIRED');
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(reader.reads, 2);
    expect(invalidated, 1);
  });

  testWidgets('the tip can be dismissed and More opens account actions', (
    tester,
  ) async {
    var more = 0;
    await pumpHome(
      tester,
      FakeIntakeReader(
        nextResult: const AppSuccess(null),
        agendaResult: const AppSuccess([]),
      ),
      onMore: () => more++,
    );
    expect(find.text('Consejo del día'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar consejo del día'));
    await tester.pump();
    expect(find.text('Consejo del día'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Más'));
    expect(more, 1);
  });

  testWidgets(
    'next dose, shortcut and tab open the flows and reload on return',
    (tester) async {
      final reader = FakeIntakeReader(
        nextResult: AppSuccess(
          intake('next', IntakeStatus.pending, DateTime(2026, 11, 3, 8)),
        ),
        agendaResult: const AppSuccess([]),
      );
      final opened = <String>[];
      await pumpHome(
        tester,
        reader,
        onAgenda: () async => opened.add('agenda'),
        onDose: (id) async => opened.add(id),
      );
      expect(find.text('Ver todas mis tomas'), findsOneWidget);
      expect(find.bySemanticsLabel('Agenda'), findsOneWidget);
      expect(find.text('Confirmar con voz'), findsNothing);

      await tester.tap(find.text('Losartán 50 mg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todas mis tomas'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Agenda'));
      await tester.pumpAndSettle();

      expect(opened, ['next', 'agenda', 'agenda']);
      expect(reader.reads, 4, reason: 'initial load plus one per return');
    },
  );
}
