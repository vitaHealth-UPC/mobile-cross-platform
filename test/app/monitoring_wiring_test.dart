import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/adult_entry_route.dart';
import 'package:tata/app/integration/caregiver_care_route.dart';
import 'package:tata/features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'package:tata/features/family_monitoring/application/ports/contact_launcher.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/summary_usecases.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/adherence_counts.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/summary/family_summary_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import 'package:tata/features/identity_subscription/application/readmodels/remembered_adult.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_bloc.dart';
import 'package:tata/features/omission_escalation/application/policies/omission_push_access_policy.dart';
import 'package:tata/features/omission_escalation/application/services/omission_notification_session_cleanup.dart';
import 'package:tata/features/omission_escalation/application/services/omission_push_facade.dart';
import 'package:tata/features/omission_escalation/application/services/push_device_registration_coordinator.dart';
import 'package:tata/features/omission_escalation/application/usecases/omission_usecases.dart';
import 'package:tata/features/treatment_management/presentation/navigation/treatment_navigation.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../family_monitoring/monitoring_application_test.dart'
    show
        FakeContact,
        FakeNotes,
        FakePersonReader,
        FakePersonalNotes,
        FakeTimeline;
import '../intake_execution/adult_home_test.dart' show FakeIntakeReader;
import '../omission_escalation/omission_fakes.dart';
import '../support/memory_session_store.dart';

void main() {
  late MemoryPushTargets targets;
  late OmissionPushFacade push;
  late FakePersonalNotes personal;

  FamilyMonitoringNavigation monitoring() {
    personal = FakePersonalNotes();
    final notes = FakeNotes();
    final people = FakePersonReader(
      const AppSuccess(
        MonitoredPerson(
          id: 'adult-1',
          fullName: 'Rosa Vargas',
          birthDate: null,
        ),
      ),
    );
    return FamilyMonitoringNavigation(
      FamilyMonitoringFactories(
        launcher: _NoLauncher(),
        createSummaryBloc: (id, name) => FamilySummaryBloc(
          summary: GetFamilySummary(_EmptySummary()),
          contact: GetContactOption(FakeContact()),
          olderAdultId: id,
          olderAdultName: name,
        ),
        createAlertsBloc: (id) => AlertsBloc(
          timeline: GetAlertTimeline(
            FakeTimeline(const AppFailure('NOT_FOUND')),
          ),
          olderAdultId: id,
        ),
        createAlertDetailBloc: (id, alertId) => throw UnimplementedError(),
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

  setUp(() {
    targets = MemoryPushTargets();
    final store = MemorySessionStore(
      StoredSession(
        accessToken: 'token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner('caregiver-1', SessionRole.caregiver),
      ),
    );
    final notifier = RecordingNotifier();
    final policy = OmissionPushAccessPolicy(sessions: store, targets: targets);
    push = OmissionPushFacade(
      policy: policy,
      followCaregiver: FollowCaregiverAlerts(targets),
      followReminders: FollowDoseReminders(targets),
      resolve: ResolvePushDestination(targets),
      handle: HandleIncomingOmissionPush(policy, notifier),
      registration: PushDeviceRegistrationCoordinator(
        sessions: store,
        tokens: ScriptedTokenSource([]),
        registry: RecordingRegistry(),
        wait: (_) async {},
      ),
      cleanup: OmissionNotificationSessionCleanup(notifier: notifier),
      registrationEnabled: false,
    );
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view
      ..physicalSize = const Size(1179, 2649)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  const treatments = TreatmentNavigation(
    TreatmentFactories(
      createListBloc: _unavailable,
      createRegistrationBloc: _unavailable,
      createMedicationsBloc: _unavailable,
      createSetupBloc: _unavailable2,
      createManagementBloc: _unavailable2,
      createMyMedicationsBloc: _unavailable0,
    ),
  );

  testWidgets('the caregiver route follows the person and shows the summary', (
    tester,
  ) async {
    var settings = 0;
    await pump(
      tester,
      CaregiverCareRoute(
        profile: CaregiverLinkSummary(
          id: 'link-A',
          olderAdultId: 'adult-1',
          fullName: 'Rosa Vargas',
          confirmedAt: DateTime.utc(2026, 10, 27),
        ),
        caregiverId: 'caregiver-1',
        treatments: treatments,
        monitoring: monitoring(),
        push: push,
        onOpenAdherence: (_) {},
        onOpenSettings: (_) => settings++,
        onSessionInvalidated: () {},
      ),
    );
    expect(find.text('Resumen familiar'), findsOneWidget);
    expect(targets.caregivers, {'adult-1': 'caregiver-1'});

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Tratamientos'), findsOneWidget);
    expect(find.text('Medicamentos'), findsOneWidget);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(settings, 1);
  });

  testWidgets(
    'the adult route remembers the reminders target and opens notes',
    (tester) async {
      final reader = FakeIntakeReader(
        nextResult: const AppSuccess(null),
        agendaResult: const AppSuccess([]),
      );
      await pump(
        tester,
        AdultEntryRoute(
          olderAdultId: 'adult-A',
          readRemembered: () async =>
              RememberedAdult(id: 'adult-A', name: 'Rosa Vargas'),
          remember: (_) async {},
          forget: () async {},
          readAdultName: () async => 'Rosa Vargas',
          createPinSetupBloc: () => throw UnimplementedError(),
          createHomeBloc: () => HomeBloc(
            next: GetNextIntake(reader),
            progress: GetDailyProgress(reader, DateTime.now),
          ),
          createAgendaBloc: () => throw UnimplementedError(),
          createDoseBloc: (_) => throw UnimplementedError(),
          createConsentBloc: () => throw UnimplementedError(),
          onSignOut: () {},
          onSessionChanged: () {},
          monitoring: monitoring(),
          push: push,
        ),
      );
      expect(targets.adults, {'adult-A': 'Rosa Vargas'});

      await tester.tap(find.text('Más'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Notas'));
      await tester.pumpAndSettle();
      expect(find.text('Apuntes para acompañar tu rutina.'), findsOneWidget);
    },
  );
}

Never _unavailable(String _) => throw UnimplementedError();
Never _unavailable2(String a, String b) => throw UnimplementedError();
Never _unavailable0() => throw UnimplementedError();

final class _NoLauncher implements ContactLauncher {
  @override
  Future<bool> open(ContactChannel channel) async => true;
}

final class _EmptySummary implements FamilyMonitoringRepository {
  @override
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
    DateTime day,
  ) async => AppSuccess(
    FamilySummary(
      olderAdultName: name,
      date: day,
      weekly: AdherenceCounts(0, 0),
      today: AdherenceCounts(0, 0),
      nextDose: null,
      stockAttention: const [],
      openAlerts: const [],
      inventoryAvailable: true,
    ),
  );

  @override
  Future<AppResult<List<IntakeHistoryEntry>>> history(String id) async =>
      const AppSuccess([]);
}
