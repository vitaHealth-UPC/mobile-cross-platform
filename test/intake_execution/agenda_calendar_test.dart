import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/readmodels/agenda_week.dart';
import 'package:tata/features/intake_execution/application/usecases/get_week_agenda.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/agenda/agenda_state.dart';
import 'package:tata/features/intake_execution/presentation/screens/agenda_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';
import 'dose_flow_test.dart' show dose;

/// Holds each week request independently to exercise out-of-order responses.
final class _DeferredAgenda implements IntakeReader {
  final requests = <Completer<AppResult<List<Intake>>>>[];

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) {
    final response = Completer<AppResult<List<Intake>>>();
    requests.add(response);
    return response.future;
  }

  @override
  Future<AppResult<Intake>> detail(String id) => throw UnimplementedError();

  @override
  Future<AppResult<Intake?>> next() => throw UnimplementedError();
}

void main() {
  setUpAll(loadTataFonts);
  final selected = DateTime(2026, 7, 22);
  final data = [
    for (final (hour, name, instructions, status) in [
      (8, 'Losartán 50 mg', 'Con el desayuno', IntakeStatus.confirmed),
      (
        13,
        'Vitamina D3 1,000 UI',
        'Después del almuerzo',
        IntakeStatus.pending,
      ),
      (20, 'Amlodipino 5 mg', 'Cada noche', IntakeStatus.pending),
      (21, 'Atorvastatina 20 mg', 'Por la noche', IntakeStatus.pending),
    ])
      Intake(
        id: 'dose-$hour',
        olderAdultId: 'adult-A',
        medicationName: name,
        dose: '1 comprimido',
        instructions: instructions,
        scheduledAt: DateTime(2026, 7, 22, hour).toUtc(),
        status: status,
        confirmedAt: status == IntakeStatus.confirmed
            ? DateTime(2026, 7, 22, hour).toUtc()
            : null,
      ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    ValueChanged<DateTime>? onSelect,
    VoidCallback? onNotes,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const Key('agenda-capture'),
          child: AgendaScreen(
            state: AgendaState(
              week: AgendaWeek.containing(selected),
              selectedDay: selected,
              status: AgendaStatus.ready,
              intakes: data,
            ),
            today: selected,
            onSelectDay: onSelect ?? (_) {},
            onRetry: () async {},
            onOpenDose: (_) {},
            onNotes: onNotes,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'an older week response cannot replace a more recent calendar choice',
    () async {
      final reader = _DeferredAgenda();
      final bloc = AgendaBloc(
        agenda: GetWeekAgenda(reader),
        clock: () => selected,
      );
      bloc.add(AgendaDaySelected(DateTime(2026, 8, 5)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(AgendaDaySelected(DateTime(2026, 8, 12)));
      await Future<void>.delayed(Duration.zero);
      expect(reader.requests, hasLength(2));
      reader.requests.last.complete(
        AppSuccess([
          dose('new', IntakeStatus.pending, DateTime(2026, 8, 12, 8)),
        ]),
      );
      await bloc.stream.firstWhere((s) => s.status == AgendaStatus.ready);
      reader.requests.first.complete(
        AppSuccess([
          dose('old', IntakeStatus.pending, DateTime(2026, 8, 5, 8)),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.selectedDay, DateTime(2026, 8, 12));
      expect(bloc.state.selectedIntakes.single.id, 'new');
      await bloc.close();
    },
  );

  testWidgets(
    'calendar cancellation keeps the date and confirmation selects another month',
    (tester) async {
      DateTime? picked;
      await pump(tester, onSelect: (date) => picked = date);
      await tester.tap(find.byTooltip('Elegir fecha'));
      await tester.pumpAndSettle();
      var localization = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.text(localization.cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(picked, isNull);
      await tester.tap(find.byTooltip('Elegir fecha'));
      await tester.pumpAndSettle();
      localization = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.byTooltip(localization.nextMonthTooltip));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('5'),
        ),
      );
      await tester.tap(find.text(localization.okButtonLabel));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 8, 5));
    },
  );

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'weekly agenda renders the native calendar and dose timeline at $scale',
      (tester) async {
        var notes = 0;
        await pump(tester, scale: scale, onNotes: () => notes++);
        expect(find.text('Losartán 50 mg'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await captureWidget(
          tester,
          find.byKey(const Key('agenda-capture')),
          'weekly_agenda_$scale',
        );
        await tester.tap(find.text('Notas'));
        expect(notes, 1);
        await tester.scrollUntilVisible(
          find.text('Consejo del día'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
