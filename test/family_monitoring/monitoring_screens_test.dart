import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/ports/contact_launcher.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/summary_usecases.dart';
import 'package:tata/features/family_monitoring/domain/entities/notes.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/adherence_counts.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_status.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/note_values.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alert_detail/alert_detail_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/summary/family_summary_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/screens/alert_detail_screen.dart';
import 'package:tata/features/family_monitoring/presentation/screens/alerts_screen.dart';
import 'package:tata/features/family_monitoring/presentation/screens/family_summary_screen.dart';
import 'package:tata/features/family_monitoring/presentation/screens/notes_screen.dart';
import 'package:tata/features/family_monitoring/presentation/screens/personal_notes_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

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
        dose,
        note;

final class _Launcher implements ContactLauncher {
  _Launcher({this.opens = true});
  final bool opens;
  final opened = <ContactChannel>[];

  @override
  Future<bool> open(ContactChannel channel) async {
    opened.add(channel);
    return opens;
  }
}

final class _FakeSummaryRepository implements FamilyMonitoringRepository {
  _FakeSummaryRepository(this.result);
  final AppResult<FamilySummary> result;

  @override
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
    DateTime day,
  ) async => result;

  @override
  Future<AppResult<List<IntakeHistoryEntry>>> history(
    String olderAdultId,
  ) async => const AppSuccess([]);
}

void main() {
  setUpAll(loadTataFonts);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
  }) async {
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
          child: child!,
        ),
        home: child,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('alerts screen', () {
    final now = DateTime(2026, 11, 13, 10);

    AlertsBloc bloc(AlertTimeline timeline) => AlertsBloc(
      timeline: GetAlertTimeline(FakeTimeline(AppSuccess(timeline))),
      olderAdultId: 'adult-1',
      clock: () => now,
    )..add(const AlertsRequested());

    final timeline = AlertTimeline(
      alerts: [
        anAlert(id: 1),
        anAlert(id: 2, status: AlertStatus.closed),
      ],
      doses: [dose('next', 'PENDING', DateTime(2026, 11, 13, 12, 30))],
      olderAdultName: 'Rosa',
      day: DateTime(2026, 11, 13),
    );

    for (final scale in [1.0, 1.5]) {
      testWidgets('lists alerts and doses at text scale $scale', (
        tester,
      ) async {
        await pump(
          tester,
          BlocProvider(
            create: (_) => bloc(timeline),
            child: AlertsScreen(
              onTab: (_) {},
              onOpenAlert: (_) {},
              tickEvery: const Duration(days: 1),
            ),
          ),
          scale: scale,
        );
        // Title and tab label.
        expect(find.text('Alertas'), findsNWidgets(2));
        expect(find.text('Alerta pendiente'), findsOneWidget);
        expect(find.text('Alerta cerrada'), findsOneWidget);
        expect(find.text('Recordatorio próximo'), findsOneWidget);
        expect(find.text('1 alerta pendiente'), findsOneWidget);
        expect(find.text('En 2 h 30 min'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'a filter without matches says so, and tapping an alert opens it',
      (tester) async {
        int? opened;
        await pump(
          tester,
          BlocProvider(
            create: (_) => bloc(timeline),
            child: AlertsScreen(
              onTab: (_) {},
              onOpenAlert: (a) => opened = a.id,
              tickEvery: const Duration(days: 1),
            ),
          ),
        );
        await tester.tap(find.text('Alerta pendiente'));
        expect(opened, 1);
        await tester.tap(find.text('Pendientes'));
        await tester.pump();
        expect(find.text('Recordatorio próximo'), findsNothing);
        await tester.tap(find.text('Próximas'));
        await tester.pump();
        expect(find.text('Alerta pendiente'), findsNothing);
        expect(find.text('Recordatorio próximo'), findsOneWidget);
      },
    );

    testWidgets('a failure offers a retry that asks again', (tester) async {
      final reader = FakeTimeline(const AppFailure('NETWORK_UNAVAILABLE'));
      await pump(
        tester,
        BlocProvider(
          create: (_) => AlertsBloc(
            timeline: GetAlertTimeline(reader),
            olderAdultId: 'adult-1',
            clock: () => now,
          )..add(const AlertsRequested()),
          child: AlertsScreen(
            onTab: (_) {},
            onOpenAlert: (_) {},
            tickEvery: const Duration(days: 1),
          ),
        ),
      );
      expect(reader.reads, 1);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();
      expect(reader.reads, 2);
    });

    testWidgets('lost access offers no retry', (tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => AlertsBloc(
            timeline: GetAlertTimeline(
              FakeTimeline(const AppFailure('ACCESS_DENIED')),
            ),
            olderAdultId: 'adult-1',
            clock: () => now,
          )..add(const AlertsRequested()),
          child: AlertsScreen(
            onTab: (_) {},
            onOpenAlert: (_) {},
            tickEvery: const Duration(days: 1),
          ),
        ),
      );
      expect(find.text('Reintentar'), findsNothing);
      expect(find.textContaining('vínculo de cuidado'), findsOneWidget);
    });
  });

  group('alert detail', () {
    Widget screen({
      required FakeAlerts alerts,
      required _Launcher launcher,
      FakeContact? contact,
      FakeNotes? notes,
    }) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AlertDetailBloc(
            detail: GetAlertDetail(alerts),
            update: UpdateAlertStatus(alerts),
            contact: GetContactOption(contact ?? FakeContact()),
            people: FakePersonReader(
              AppSuccess(
                MonitoredPerson(
                  id: 'adult-1',
                  fullName: 'Rosa Vargas',
                  birthDate: DateTime(1950, 1, 1),
                ),
              ),
            ),
            doses: FakeDoseReader(
              AppSuccess(
                dose('intake-1', 'PENDING', DateTime.utc(2026, 11, 13, 12)),
              ),
            ),
            history: FakeEventsReader(
              AppSuccess([
                RecordedAlertEvent(
                  type: RecordedAlertEventType.alertGenerated,
                  occurredAt: DateTime.utc(2026, 11, 13, 12, 30),
                ),
              ]),
            ),
            olderAdultId: 'adult-1',
            alertId: 1,
          )..add(const AlertDetailRequested()),
        ),
        BlocProvider(
          create: (_) => NoteComposerCubit(
            register: RegisterFollowUpNote(notes ?? FakeNotes()),
            olderAdultId: 'adult-1',
          ),
        ),
      ],
      child: AlertDetailScreen(launcher: launcher),
    );

    for (final scale in [1.0, 1.5]) {
      testWidgets('shows the person, the evidence and the actions at $scale', (
        tester,
      ) async {
        await pump(
          tester,
          screen(
            alerts: FakeAlerts(alerts: [anAlert()]),
            launcher: _Launcher(),
          ),
          scale: scale,
        );
        expect(find.text('Rosa Vargas'), findsOneWidget);
        expect(find.text('Alerta generada'), findsOneWidget);
        expect(find.text('Marcar como atendida'), findsOneWidget);
        expect(find.text('Cerrar alerta'), findsOneWidget);
        expect(find.textContaining('Contacta a Rosa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('closing asks for confirmation first', (tester) async {
      final alerts = FakeAlerts(alerts: [anAlert()]);
      await pump(tester, screen(alerts: alerts, launcher: _Launcher()));
      await tester.tap(find.text('Cerrar alerta'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar esta alerta?'), findsOneWidget);
      expect(alerts.updates, isEmpty);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(alerts.updates, isEmpty);

      await tester.tap(find.text('Cerrar alerta'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cerrar alerta'),
        ),
      );
      await tester.pumpAndSettle();
      expect(alerts.updates, [(1, AlertStatus.closed)]);
      expect(find.text('Alerta cerrada.'), findsOneWidget);
      expect(find.text('Cerrar alerta'), findsNothing);
    });

    testWidgets('attending needs no confirmation', (tester) async {
      final alerts = FakeAlerts(alerts: [anAlert()]);
      await pump(tester, screen(alerts: alerts, launcher: _Launcher()));
      await tester.tap(find.text('Marcar como atendida'));
      await tester.pumpAndSettle();
      expect(alerts.updates, [(1, AlertStatus.attended)]);
      expect(find.text('Alerta marcada como atendida.'), findsOneWidget);
    });

    testWidgets('opens the contact app, and says so when none can', (
      tester,
    ) async {
      final launcher = _Launcher(opens: false);
      await pump(
        tester,
        screen(
          alerts: FakeAlerts(alerts: [anAlert()]),
          launcher: launcher,
        ),
      );
      await tester.tap(find.text('Abrir teléfono'));
      await tester.pump();
      await tester.pump();
      expect(launcher.opened.single.digits, '51999111');
      expect(
        find.text('Ninguna app de este dispositivo puede abrir este contacto.'),
        findsOneWidget,
      );
    });

    testWidgets('writes a follow-up note from the detail', (tester) async {
      final notes = FakeNotes();
      await pump(
        tester,
        screen(
          alerts: FakeAlerts(alerts: [anAlert()]),
          launcher: _Launcher(),
          notes: notes,
        ),
      );
      await tester.tap(find.text('Agregar nota de seguimiento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar nota'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe la nota antes de guardarla.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Llamé y está bien');
      await tester.tap(find.text('Guardar nota'));
      await tester.pumpAndSettle();
      expect(notes.registered, ['Llamé y está bien']);
      expect(find.text('Nota guardada'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a missing alert shows its own message', (tester) async {
      final alerts = FakeAlerts()..detail = const AppFailure('NOT_FOUND');
      await pump(tester, screen(alerts: alerts, launcher: _Launcher()));
      expect(
        find.text('Esta alerta no existe o ya no está disponible.'),
        findsOneWidget,
      );
    });
  });

  group('notes screen', () {
    testWidgets('lists notes and adds a new one on top', (tester) async {
      final notes = FakeNotes(list: [note(1, DateTime.utc(2026, 11, 1, 12))]);
      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => NotesBloc(
                notes: GetFollowUpNotes(notes),
                people: FakePersonReader(
                  const AppSuccess(
                    MonitoredPerson(
                      id: 'adult-1',
                      fullName: 'Rosa Vargas',
                      birthDate: null,
                    ),
                  ),
                ),
                olderAdultId: 'adult-1',
              )..add(const NotesRequested()),
            ),
            BlocProvider(
              create: (_) => NoteComposerCubit(
                register: RegisterFollowUpNote(notes),
                olderAdultId: 'adult-1',
              ),
            ),
          ],
          child: NotesScreen(onTab: (_) {}),
        ),
      );
      expect(find.text('nota 1'), findsOneWidget);
      expect(
        find.text('Seguimiento y observaciones sobre Rosa Vargas.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Agregar nota'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nueva');
      await tester.tap(find.text('Guardar nota'));
      await tester.pumpAndSettle();
      expect(notes.registered, ['Nueva']);
      expect(find.text('nota 99'), findsOneWidget);
    });

    testWidgets('no notes shows the empty state', (tester) async {
      await pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => NotesBloc(
                notes: GetFollowUpNotes(FakeNotes()),
                people: FakePersonReader(const AppFailure('NOT_FOUND')),
                olderAdultId: 'adult-1',
              )..add(const NotesRequested()),
            ),
            BlocProvider(
              create: (_) => NoteComposerCubit(
                register: RegisterFollowUpNote(FakeNotes()),
                olderAdultId: 'adult-1',
              ),
            ),
          ],
          child: NotesScreen(onTab: (_) {}),
        ),
      );
      expect(find.text('Aún no hay notas'), findsOneWidget);
    });
  });

  group('personal notes screen', () {
    PersonalNote personal(int id, PersonalNoteCategory category) =>
        PersonalNote(
          id: id,
          title: 'Título $id',
          text: 'texto',
          category: category,
          recordedAt: DateTime.utc(2026, 11, 13, 12),
        );

    testWidgets('filters, creates and keeps the typed text on failure', (
      tester,
    ) async {
      final repository = FakePersonalNotes()
        ..listResult = AppSuccess([
          personal(1, PersonalNoteCategory.medication),
          personal(2, PersonalNoteCategory.routine),
        ]);
      await pump(
        tester,
        BlocProvider(
          create: (_) => PersonalNotesBloc(
            list: GetPersonalNotes(repository),
            create: CreatePersonalNote(repository),
          )..add(const PersonalNotesRequested()),
          child: const PersonalNotesScreen(),
        ),
      );
      expect(find.text('Título 1'), findsOneWidget);
      expect(find.text('Título 2'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'Rutina'));
      await tester.pump();
      expect(find.text('Título 1'), findsNothing);
      expect(find.text('Título 2'), findsOneWidget);

      repository.createResult = const AppFailure('NETWORK_UNAVAILABLE');
      await tester.ensureVisible(find.text('Agregar nota').last);
      await tester.tap(find.text('Agregar nota').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Agua');
      await tester.enterText(
        find.widgetWithText(TextField, 'Nota'),
        'Tomar agua',
      );
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se guardó la nota. Reintenta conservando tu texto.'),
        findsOneWidget,
      );
      expect(find.text('Agua'), findsOneWidget);

      repository.createResult = null;
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(repository.created.last.$1, 'Agua');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Agua'), findsOneWidget);
    });

    testWidgets('without the adult session it offers to sign in again', (
      tester,
    ) async {
      var signIn = 0;
      final repository = FakePersonalNotes()
        ..listResult = const AppFailure('AUTHENTICATION_REQUIRED');
      await pump(
        tester,
        BlocProvider(
          create: (_) => PersonalNotesBloc(
            list: GetPersonalNotes(repository),
            create: CreatePersonalNote(repository),
          )..add(const PersonalNotesRequested()),
          child: PersonalNotesScreen(onSignIn: () => signIn++),
        ),
      );
      await tester.tap(find.text('Reintentar'));
      expect(signIn, 1);
    });
  });

  group('family summary', () {
    FamilySummary summary({
      List<StockAttention> stock = const [],
      bool inventory = true,
      MonitoredDose? next,
      int alerts = 0,
    }) => FamilySummary(
      olderAdultName: 'Rosa Vargas',
      date: DateTime(2026, 11, 13),
      weekly: AdherenceCounts(5, 7),
      today: AdherenceCounts(1, 2),
      nextDose: next,
      stockAttention: stock,
      openAlerts: [
        for (var i = 0; i < alerts; i++)
          OpenAlert(
            id: i + 1,
            medicationName: 'Losartán',
            reason: '',
            scheduledAt: DateTime.utc(2026, 11, 13, 12),
          ),
      ],
      inventoryAvailable: inventory,
    );

    Widget screen(
      FamilySummaryBloc bloc,
      _Launcher launcher, {
      VoidCallback? onHistory,
    }) => BlocProvider.value(
      value: bloc,
      child: FamilySummaryScreen(
        launcher: launcher,
        onTab: (_) {},
        onHistory: onHistory,
      ),
    );

    FamilySummaryBloc bloc(
      AppResult<FamilySummary> result, {
      FakeContact? contact,
    }) => FamilySummaryBloc(
      summary: GetFamilySummary(_FakeSummaryRepository(result)),
      contact: GetContactOption(contact ?? FakeContact()),
      olderAdultId: 'adult-1',
      olderAdultName: 'Rosa Vargas',
      clock: () => DateTime(2026, 11, 13, 10),
    )..add(const FamilySummaryRequested());

    for (final scale in [1.0, 1.5]) {
      testWidgets('shows adherence, today, stock and alerts at $scale', (
        tester,
      ) async {
        await pump(
          tester,
          screen(
            bloc(
              AppSuccess(
                summary(
                  alerts: 2,
                  stock: const [
                    StockAttention(
                      medicationId: 'm',
                      medicationName: 'Metformina',
                      remaining: 3,
                    ),
                  ],
                  next: dose('n', 'PENDING', DateTime(2026, 11, 13, 20)),
                ),
              ),
            ),
            _Launcher(),
          ),
          scale: scale,
        );
        expect(find.text('Resumen familiar'), findsOneWidget);
        expect(find.text('71%'), findsOneWidget);
        expect(find.text('5 de 7 tomas confirmadas'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.text('Quedan 3 unidades de Metformina.'), findsOneWidget);
        expect(find.text('2 alertas pendientes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an unreadable inventory is said, not hidden', (tester) async {
      await pump(
        tester,
        screen(bloc(AppSuccess(summary(inventory: false))), _Launcher()),
      );
      expect(find.text('No pudimos consultar el inventario.'), findsOneWidget);
    });

    testWidgets('contact opens the channel and its app', (tester) async {
      final launcher = _Launcher();
      await pump(tester, screen(bloc(AppSuccess(summary())), launcher));
      await tester.tap(find.text('Contactar'));
      await tester.pumpAndSettle();
      expect(find.text('Contactar a Rosa'), findsOneWidget);
      await tester.tap(find.text('Abrir teléfono'));
      await tester.pump();
      expect(launcher.opened.single.value, '+51 999 111');
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('without access it shows the restriction and no data', (
      tester,
    ) async {
      await pump(
        tester,
        screen(bloc(const AppFailure('ACCESS_DENIED')), _Launcher()),
      );
      expect(find.text('Seguimiento restringido'), findsOneWidget);
      expect(find.text('71%'), findsNothing);
    });

    testWidgets('the history action is handed to the host', (tester) async {
      var history = 0;
      await pump(
        tester,
        screen(
          bloc(AppSuccess(summary())),
          _Launcher(),
          onHistory: () => history++,
        ),
      );
      await tester.tap(find.text('Historial'));
      expect(history, 1);
    });

    testWidgets('the tab bar reports the destination', (tester) async {
      CaregiverTab? tab;
      await pump(
        tester,
        BlocProvider.value(
          value: bloc(AppSuccess(summary())),
          child: FamilySummaryScreen(
            launcher: _Launcher(),
            onTab: (t) => tab = t,
          ),
        ),
      );
      await tester.tap(find.text('Alertas'));
      expect(tab, CaregiverTab.alerts);
    });
  });
}
