import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/presentation/widgets/adherence_level_card.dart';
import 'package:tata/features/family_monitoring/application/ports/contact_launcher.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/summary_usecases.dart';
import 'package:tata/features/family_monitoring/domain/entities/notes.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/adherence_counts.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alert_detail/alert_detail_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/summary/family_summary_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import 'package:tata/features/treatment_management/application/usecases/medication_usecases.dart';
import 'package:tata/features/treatment_management/domain/entities/medication.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/widgets/active_medications_card.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
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

final class _NoLauncher implements ContactLauncher {
  @override
  Future<bool> open(ContactChannel channel) async => true;
}

final class _Summary implements FamilyMonitoringRepository {
  _Summary(this.result);
  AppResult<FamilySummary> result;
  int reads = 0;
  final names = <String>[];

  @override
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
    DateTime day,
  ) async {
    reads++;
    names.add(name);
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
  late FakePersonReader personReader;

  FamilyMonitoringNavigation navigation({
    DateTime? birthDate,
    List<FollowUpNote> noteList = const [],
    FakeContact? contact,
  }) {
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
    final people = personReader = FakePersonReader(
      AppSuccess(
        MonitoredPerson(
          id: 'adult-1',
          fullName: 'Rosa Vargas',
          birthDate: birthDate,
        ),
      ),
    );
    final notes = FakeNotes(list: noteList);
    final personal = FakePersonalNotes();
    return FamilyMonitoringNavigation(
      FamilyMonitoringFactories(
        launcher: _NoLauncher(),
        createSummaryBloc: (id, name) => FamilySummaryBloc(
          summary: GetFamilySummary(summaries),
          contact: GetContactOption(contact ?? FakeContact()),
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
    FutureOr<void> Function()? onMore,
    VoidCallback? onInvalidated,
    VoidCallback? onHistory,
    FutureOr<void> Function()? onAddMedication,
    FutureOr<void> Function(StockAttention stock)? onOpenStock,
    LinkedPersonSlots? person,
    double scale = 1,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('linked-person-capture'),
        child: MaterialApp(
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
          home: navigation.caregiverHome(
            olderAdultId: 'adult-1',
            olderAdultName: 'Rosa Vargas',
            onHistory: onHistory ?? () {},
            onAddMedication: onAddMedication ?? () {},
            onPerson: onPerson ?? () {},
            onMore: onMore ?? () {},
            onSessionInvalidated: onInvalidated ?? () {},
            onOpenStock: onOpenStock,
            person: person,
          ),
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

  testWidgets('a low stock line opens its inventory and refreshes on return', (
    tester,
  ) async {
    final home = navigation();
    summaries.result = AppSuccess(
      FamilySummary(
        olderAdultName: 'Rosa Vargas',
        date: DateTime(2026, 11, 13),
        weekly: AdherenceCounts(5, 7),
        today: AdherenceCounts(1, 2),
        nextDose: null,
        stockAttention: const [
          StockAttention(
            medicationId: 'med-1',
            medicationName: 'Losartán',
            remaining: 5,
          ),
        ],
        openAlerts: const [],
        inventoryAvailable: true,
      ),
    );
    final opened = <String>[];
    final inventory = Completer<void>();
    await pumpHome(
      tester,
      home,
      onOpenStock: (stock) {
        opened.add(stock.medicationId);
        return inventory.future;
      },
    );
    await tester.tap(find.text('Quedan 5 unidades de Losartán.'));
    await tester.pump();
    expect(opened, ['med-1']);
    final readsBefore = summaries.reads;

    inventory.complete();
    await tester.pumpAndSettle();
    expect(summaries.reads, readsBefore + 1);
  });

  testWidgets('returning from the medications reads the summary again', (
    tester,
  ) async {
    final home = navigation();
    final medications = Completer<void>();
    await pumpHome(tester, home, onAddMedication: () => medications.future);
    await tester.tap(find.text('Agregar medicamento'));
    await tester.pump();
    final readsBefore = summaries.reads;
    medications.complete();
    await tester.pumpAndSettle();
    expect(summaries.reads, readsBefore + 1);
  });

  testWidgets('returning from the More menu reads the summary again', (
    tester,
  ) async {
    final more = Completer<void>();
    await pumpHome(tester, navigation(), onMore: () => more.future);
    await tester.tap(find.text('Más'));
    await tester.pump();
    final readsBefore = summaries.reads;
    // Still inside a More flow: nothing is read yet.
    expect(summaries.reads, readsBefore);
    more.complete();
    await tester.pumpAndSettle();
    expect(summaries.reads, readsBefore + 1);
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

  group('Person tab (Figma 563:1121)', () {
    LinkedPersonSlots slots() => LinkedPersonSlots(
      linkedSince: DateTime(2025, 11, 2),
      adherence: (_) => const Text('tarjeta de adherencia'),
      treatment: (_) => const Text('tarjeta de tratamiento'),
    );

    testWidgets('call and message only offer their registered channel type', (
      tester,
    ) async {
      final contact = FakeContact(
        channel: AppSuccess(
          ContactChannel(
            type: ContactChannelType.whatsapp,
            value: '+51999888777',
          ),
        ),
        name: const AppSuccess('Rosa Vargas'),
      );
      await pumpHome(tester, navigation(contact: contact), person: slots());
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Llamar'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir WhatsApp'), findsNothing);
      expect(
        find.text('No hay un canal de contacto registrado.'),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mensajes'));
      await tester.pumpAndSettle();
      expect(find.text('Abrir WhatsApp'), findsOneWidget);
      expect(find.text('Abrir teléfono'), findsNothing);
    });

    testWidgets('lost contact permission removes the protected person cards', (
      tester,
    ) async {
      await pumpHome(
        tester,
        navigation(
          contact: FakeContact(channel: const AppFailure('ACCESS_DENIED')),
        ),
        person: slots(),
      );
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();
      expect(find.text('tarjeta de adherencia'), findsOneWidget);
      await tester.tap(find.text('Llamar'));
      await tester.pumpAndSettle();
      expect(find.text('tarjeta de adherencia'), findsNothing);
      expect(find.text('tarjeta de tratamiento'), findsNothing);
      expect(find.text('Vinculada'), findsNothing);
    });

    testWidgets('editing reloads the profile and updates the summary name', (
      tester,
    ) async {
      await pumpHome(
        tester,
        navigation(),
        person: LinkedPersonSlots(
          linkedSince: DateTime(2025, 11, 2),
          onEdit: (_) async {
            personReader.result = AppSuccess(
              MonitoredPerson(
                id: 'adult-1',
                fullName: 'Rosa Actualizada',
                birthDate: DateTime(1958, 5, 12),
              ),
            );
            return 'Rosa Actualizada';
          },
        ),
      );
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      expect(find.text('Rosa Actualizada'), findsOneWidget);
      expect(summaries.names.last, 'Rosa Actualizada');
    });

    testWidgets('a denied profile hides the clinical slots and linked status', (
      tester,
    ) async {
      await pumpHome(tester, navigation(), person: slots());
      personReader.result = const AppFailure('ACCESS_DENIED');
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();
      expect(find.text('tarjeta de adherencia'), findsNothing);
      expect(find.text('tarjeta de tratamiento'), findsNothing);
      expect(find.text('Vinculada'), findsNothing);
    });

    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'profile with production clinical cards renders at scale $scale',
        (tester) async {
          final backend = FakeBackend();
          backend.medications.clear();
          for (final (id, name, strength) in [
            ('m1', 'Losartán', '50 mg'),
            ('m2', 'Metformina', '500 mg'),
            ('m3', 'Levotiroxina', '75 mcg'),
          ]) {
            backend.medications[id] = Medication(
              id: id,
              olderAdultId: 'adult-A',
              name: name,
              presentation: strength,
              active: true,
            );
          }
          await pumpHome(
            tester,
            navigation(
              birthDate: DateTime(1958, 5, 12),
              noteList: [
                FollowUpNote(
                  id: 1,
                  text: 'A veces olvida la toma de la tarde cuando sale a caminar. Le ayudan los recordatorios.',
                  recordedAt: DateTime.utc(2026, 11, 18),
                  familiarId: 'caregiver-A',
                ),
              ],
            ),
            scale: scale,
            person: LinkedPersonSlots(
              linkedSince: DateTime(2024, 3, 1),
              onEdit: (_) async => null,
              adherence: (_) => const AdherenceLevelCard(
                adherencePercent: 92,
                periodDays: 30,
                changePercent: 8,
              ),
              treatment: (_) => ActiveMedicationsCard(
                createBloc: () => MedicationManagementBloc(
                  list: ListMedications(backend),
                  update: UpdateMedication(backend),
                  deactivate: DeactivateMedication(backend),
                  reactivate: ReactivateMedication(backend),
                  olderAdultId: 'adult-A',
                ),
                onSessionInvalidated: () {},
              ),
            ),
          );
          await tester.tap(find.text('Persona'));
          await tester.pumpAndSettle();
          await captureWidget(
            tester,
            find.byKey(const Key('linked-person-capture')),
            'linked_person_$scale',
          );
          await tester.scrollUntilVisible(find.text('Notas del cuidador'), 200);
          expect(find.textContaining('A veces olvida'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('shows who the person is, the link and the latest note', (
      tester,
    ) async {
      var back = 0;
      await pumpHome(
        tester,
        navigation(
          birthDate: DateTime(1950, 5, 12),
          noteList: [
            note(1, DateTime.utc(2026, 11, 1)),
            note(2, DateTime.utc(2026, 11, 12)),
          ],
        ),
        person: slots(),
        onPerson: () => back++,
      );
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();

      expect(find.text('Rosa Vargas'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d+ años$')), findsOneWidget);
      expect(find.text('Cumpleaños: 12 may'), findsOneWidget);
      expect(find.text('Vinculada'), findsOneWidget);
      expect(find.text('Desde nov 2025'), findsOneWidget);
      expect(find.text('tarjeta de adherencia'), findsOneWidget);
      expect(find.text('tarjeta de tratamiento'), findsOneWidget);
      expect(find.text('Notas del cuidador'), findsOneWidget);
      // The most recent note, not the first in the list.
      expect(find.text('nota 2'), findsOneWidget);
      expect(find.text('Resumen familiar'), findsNothing);

      await tester.tap(find.byTooltip('Volver'));
      expect(back, 1);
    });

    testWidgets('quick actions reach contact, medication and history', (
      tester,
    ) async {
      var medications = 0;
      var history = 0;
      await pumpHome(
        tester,
        navigation(),
        person: slots(),
        onAddMedication: () => medications++,
        onHistory: () => history++,
      );
      await tester.tap(find.text('Persona'));
      await tester.pumpAndSettle();
      expect(find.textContaining('años'), findsNothing);
      expect(
        find.text('Aún no hay notas. Toca para escribir la primera.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ver medicación'));
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect((medications, history), (1, 1));

      await tester.tap(find.text('Llamar'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      await tester.tap(find.text('Notas del cuidador'));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay notas'), findsOneWidget);
    });
  });

  testWidgets('closing the contact dialog with back keeps the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 883);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final home = navigation();
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => home.caregiverHome(
                  olderAdultId: 'adult-1',
                  olderAdultName: 'Rosa Vargas',
                  onHistory: () {},
                  onAddMedication: () {},
                  onPerson: () {},
                  onMore: () {},
                  onSessionInvalidated: () {},
                  person: LinkedPersonSlots(linkedSince: DateTime(2025, 11, 2)),
                ),
              ),
            ),
            child: const Text('Lista de familiares'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lista de familiares'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Persona'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Llamar'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    // System back closes the dialog and nothing else (also on the summary).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('Lista de familiares'), findsNothing);
  });
}
