import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/ports/contact_launcher.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/summary_usecases.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/adherence_counts.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alert_detail/alert_detail_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/summary/family_summary_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';
import 'monitoring_application_test.dart'
    show
        FakeAlerts,
        FakeContact,
        FakeDoseReader,
        FakeEventsReader,
        FakeNotes,
        FakePersonReader,
        FakePersonalNotes,
        FakeTimeline,
        anAlert,
        dose;

final class _NoLauncher implements ContactLauncher {
  @override
  Future<bool> open(ContactChannel channel) async => true;
}

final class _Summary implements FamilyMonitoringRepository {
  _Summary(this.result);
  AppResult<FamilySummary> result;
  int reads = 0;

  @override
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
    DateTime day,
  ) async {
    reads++;
    return result;
  }

  @override
  Future<AppResult<List<IntakeHistoryEntry>>> history(String id) async =>
      const AppSuccess([]);
}

void main() {
  setUpAll(loadTataFonts);

  FamilySummary summary() => FamilySummary(
    olderAdultName: 'Rosa Vargas',
    date: DateTime(2026, 11, 13),
    weekly: AdherenceCounts(5, 7),
    today: AdherenceCounts(1, 2),
    nextDose: null,
    stockAttention: const [],
    openAlerts: const [],
    inventoryAvailable: true,
  );

  late _Summary summaries;
  late FakeAlerts alerts;
  late FakeTimeline timeline;

  FamilyMonitoringNavigation navigation() {
    summaries = _Summary(AppSuccess(summary()));
    alerts = FakeAlerts(alerts: [anAlert()]);
    timeline = FakeTimeline(
      AppSuccess(
        AlertTimeline(
          alerts: [anAlert()],
          doses: [dose('d1', 'CONFIRMED', DateTime(2026, 11, 13, 7))],
          olderAdultName: 'Rosa',
          day: DateTime(2026, 11, 13),
        ),
      ),
    );
    final people = FakePersonReader(
      const AppSuccess(
        MonitoredPerson(
          id: 'adult-1',
          fullName: 'Rosa Vargas',
          birthDate: null,
        ),
      ),
    );
    final notes = FakeNotes();
    final personal = FakePersonalNotes();
    return FamilyMonitoringNavigation(
      FamilyMonitoringFactories(
        launcher: _NoLauncher(),
        createSummaryBloc: (id, name) => FamilySummaryBloc(
          summary: GetFamilySummary(summaries),
          contact: GetContactOption(FakeContact()),
          olderAdultId: id,
          olderAdultName: name,
          clock: () => DateTime(2026, 11, 13, 10),
        ),
        createAlertsBloc: (id) => AlertsBloc(
          timeline: GetAlertTimeline(timeline),
          olderAdultId: id,
          clock: () => DateTime(2026, 11, 13, 10),
        ),
        createAlertDetailBloc: (id, alertId) => AlertDetailBloc(
          detail: GetAlertDetail(alerts),
          update: UpdateAlertStatus(alerts),
          contact: GetContactOption(FakeContact()),
          people: people,
          doses: FakeDoseReader(
            AppSuccess(
              dose('intake-1', 'PENDING', DateTime.utc(2026, 11, 13, 12)),
            ),
          ),
          history: FakeEventsReader(const AppSuccess([])),
          olderAdultId: id,
          alertId: alertId,
        ),
        createNotesBloc: (id) => NotesBloc(
          notes: GetFollowUpNotes(notes),
          people: people,
          olderAdultId: id,
        ),
        createComposerCubit: (id) => NoteComposerCubit(
          register: RegisterFollowUpNote(notes),
          olderAdultId: id,
        ),
        createPersonalNotesBloc: () => PersonalNotesBloc(
          list: GetPersonalNotes(personal),
          create: CreatePersonalNote(personal),
        ),
      ),
    );
  }

  Future<void> pumpHome(
    WidgetTester tester,
    FamilyMonitoringNavigation navigation, {
    VoidCallback? onPerson,
    VoidCallback? onMore,
    VoidCallback? onInvalidated,
    VoidCallback? onHistory,
  }) async {
    tester.view.physicalSize = const Size(393, 883);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: navigation.caregiverHome(
          olderAdultId: 'adult-1',
          olderAdultName: 'Rosa Vargas',
          onHistory: onHistory ?? () {},
          onAddMedication: () {},
          onPerson: onPerson ?? () {},
          onMore: onMore ?? () {},
          onSessionInvalidated: onInvalidated ?? () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('starts on the summary and moves between its tabs', (
    tester,
  ) async {
    await pumpHome(tester, navigation());
    expect(find.text('Resumen familiar'), findsOneWidget);
    expect(summaries.reads, 1);

    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tomas no confirmadas que necesitan tu seguimiento.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Notas'));
    await tester.pumpAndSettle();
    expect(find.text('Notas del cuidador'), findsNothing); // no notes yet
    expect(find.text('Aún no hay notas'), findsOneWidget);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen familiar'), findsOneWidget);
    // Coming back to a tab refreshes it.
    expect(summaries.reads, 2);
  });

  testWidgets('the Person and More tabs belong to the host', (tester) async {
    var person = 0;
    var more = 0;
    await pumpHome(
      tester,
      navigation(),
      onPerson: () => person++,
      onMore: () => more++,
    );
    await tester.tap(find.text('Persona'));
    await tester.tap(find.text('Más'));
    expect((person, more), (1, 1));
    // The shell stays where it was.
    expect(find.text('Resumen familiar'), findsOneWidget);
  });

  testWidgets('opens an alert and refreshes the lists on return', (
    tester,
  ) async {
    await pumpHome(tester, navigation());
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    final readsBefore = timeline.reads;
    await tester.tap(find.text('Alerta pendiente'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de la alerta'), findsOneWidget);
    expect(find.text('Marcar como atendida'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de la alerta'), findsNothing);
    expect(timeline.reads, greaterThan(readsBefore));
  });

  testWidgets(
    'a rejected session reaches the host once and leaves the detail',
    (tester) async {
      var invalidated = 0;
      final nav = navigation();
      await pumpHome(tester, nav, onInvalidated: () => invalidated++);
      await tester.tap(find.text('Alertas'));
      await tester.pumpAndSettle();
      alerts.detail = const AppFailure('AUTHENTICATION_REQUIRED');
      await tester.tap(find.text('Alerta pendiente'));
      await tester.pumpAndSettle();
      expect(invalidated, 1);
      expect(find.text('Detalle de la alerta'), findsNothing);
    },
  );

  testWidgets('the summary reports a rejected session to the host', (
    tester,
  ) async {
    var invalidated = 0;
    final nav = navigation();
    summaries.result = const AppFailure('SESSION_CHANGED');
    await pumpHome(tester, nav, onInvalidated: () => invalidated++);
    expect(invalidated, 1);
  });
}
