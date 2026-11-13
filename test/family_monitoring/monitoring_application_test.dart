import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/failure_codes.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/summary_usecases.dart';
import 'package:tata/features/family_monitoring/domain/entities/caregiver_alert.dart';
import 'package:tata/features/family_monitoring/domain/entities/notes.dart';
import 'package:tata/features/family_monitoring/domain/repositories/monitoring_repositories.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_status.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/note_values.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alert_detail/alert_detail_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/shared/common/result/app_result.dart';

CaregiverAlert anAlert({
  int id = 1,
  AlertStatus status = AlertStatus.open,
  DateTime? scheduledAt,
  String intakeId = 'intake-1',
}) {
  final at = scheduledAt ?? DateTime.utc(2026, 11, 13, 12);
  return CaregiverAlert(
    id: id,
    intakeId: intakeId,
    medicationName: 'Losartán',
    scheduledAt: at,
    reason: 'No respondió',
    status: status,
    openedAt: at.add(const Duration(minutes: 30)),
    closedAt: status == AlertStatus.closed
        ? at.add(const Duration(hours: 1))
        : null,
  );
}

MonitoredDose dose(String id, String status, DateTime at) => MonitoredDose(
  id: id,
  medicationId: 'm-$id',
  medicationName: 'Med $id',
  dose: '1',
  scheduledAt: at,
  status: status,
);

FollowUpNote note(int id, DateTime at) => FollowUpNote(
  id: id,
  text: 'nota $id',
  recordedAt: at,
  familiarId: 'caregiver-1',
);

final class FakeAlerts implements AlertsRepository {
  FakeAlerts({this.alerts = const [], this.updateResult, this.detail});
  List<CaregiverAlert> alerts;
  AppResult<CaregiverAlert>? updateResult;
  AppResult<CaregiverAlert>? detail;
  final updates = <(int, AlertStatus)>[];

  @override
  Future<AppResult<List<CaregiverAlert>>> openAlerts(String id) async =>
      AppSuccess(alerts);

  @override
  Future<AppResult<CaregiverAlert>> alert(String id, int alertId) async =>
      detail ?? AppSuccess(alerts.firstWhere((a) => a.id == alertId));

  @override
  Future<AppResult<CaregiverAlert>> updateStatus(
    String id,
    int alertId,
    AlertStatus status,
  ) async {
    updates.add((alertId, status));
    return updateResult ?? AppSuccess(anAlert(id: alertId, status: status));
  }
}

final class FakeContact implements ContactRepository {
  FakeContact({this.channel, this.name});
  AppResult<ContactChannel>? channel;
  AppResult<String>? name;

  @override
  Future<AppResult<ContactChannel>> contactChannel(String id) async =>
      channel ??
      AppSuccess(
        ContactChannel(type: ContactChannelType.phone, value: '+51 999 111'),
      );

  @override
  Future<AppResult<String>> olderAdultFullName(String id) async =>
      name ?? const AppSuccess('Rosa Vargas Díaz');
}

final class FakeNotes implements NotesRepository {
  FakeNotes({this.list = const []});
  List<FollowUpNote> list;
  AppResult<FollowUpNote>? registerResult;
  final registered = <String>[];

  @override
  Future<AppResult<List<FollowUpNote>>> notes(String id) async =>
      AppSuccess(list);

  @override
  Future<AppResult<FollowUpNote>> register(String id, String text) async {
    registered.add(text);
    return registerResult ?? AppSuccess(note(99, DateTime.utc(2026, 11, 13)));
  }
}

final class FakePersonalNotes implements PersonalNotesRepository {
  AppResult<List<PersonalNote>> listResult = const AppSuccess([]);
  AppResult<PersonalNote>? createResult;
  final created = <(String, String, PersonalNoteCategory)>[];

  @override
  Future<AppResult<List<PersonalNote>>> list() async => listResult;

  @override
  Future<AppResult<PersonalNote>> create(
    String title,
    String text,
    PersonalNoteCategory category,
  ) async {
    created.add((title, text, category));
    return createResult ??
        AppSuccess(
          PersonalNote(
            id: 5,
            title: title,
            text: text,
            category: category,
            recordedAt: DateTime.utc(2026, 11, 13),
          ),
        );
  }
}

final class FakeEventsReader implements AlertHistoryReader {
  FakeEventsReader(this.result);
  AppResult<List<RecordedAlertEvent>> result;
  @override
  Future<AppResult<List<RecordedAlertEvent>>> read(
    String id,
    int alertId,
  ) async => result;
}

final class FakeDoseReader implements MonitoredDoseReader {
  FakeDoseReader(this.result);
  AppResult<MonitoredDose> result;
  @override
  Future<AppResult<MonitoredDose>> read(String id, String intakeId) async =>
      result;
}

final class FakePersonReader implements MonitoredPersonReader {
  FakePersonReader(this.result);
  AppResult<MonitoredPerson> result;
  @override
  Future<AppResult<MonitoredPerson>> read(String id) async => result;
}

final class FakeTimeline implements AlertTimelineReader {
  FakeTimeline(this.result);
  AppResult<AlertTimeline> result;
  int reads = 0;
  @override
  Future<AppResult<AlertTimeline>> read(String id, DateTime day) async {
    reads++;
    return result;
  }
}

void main() {
  group('use cases', () {
    test('open alerts come pending first, newest intake first', () async {
      final repository = FakeAlerts(
        alerts: [
          anAlert(id: 1, status: AlertStatus.closed),
          anAlert(id: 2, scheduledAt: DateTime.utc(2026, 11, 12, 12)),
          anAlert(id: 3),
          anAlert(id: 4, status: AlertStatus.attended),
        ],
      );
      final result = await GetOpenAlerts(repository)('adult-1');
      expect(
        [
          for (final a in (result as AppSuccess<List<CaregiverAlert>>).value)
            a.id,
        ],
        [3, 2, 4, 1],
      );
    });

    test('an alert is never moved back to open', () async {
      final repository = FakeAlerts();
      final result = await UpdateAlertStatus(repository)(
        'adult-1',
        1,
        AlertStatus.open,
      );
      expect(
        (result as AppFailure).code,
        MonitoringFailureCodes.statusNotAccepted,
      );
      expect(repository.updates, isEmpty);
    });

    test('blank references never reach the repository', () async {
      expect(
        ((await GetAlertDetail(FakeAlerts())(' ', 1)) as AppFailure).code,
        MonitoringFailureCodes.invalidReference,
      );
      expect(
        ((await GetAlertDetail(FakeAlerts())('adult-1', 0)) as AppFailure).code,
        MonitoringFailureCodes.invalidReference,
      );
    });

    test('a note is checked and trimmed before it is sent', () async {
      final repository = FakeNotes();
      final register = RegisterFollowUpNote(repository);
      expect(
        ((await register('adult-1', '   ')) as AppFailure).code,
        MonitoringFailureCodes.noteBlank,
      );
      expect(
        ((await register('adult-1', 'x' * 1001)) as AppFailure).code,
        MonitoringFailureCodes.noteTooLong,
      );
      await register('adult-1', '  llamé  ');
      expect(repository.registered, ['llamé']);
    });

    test('notes come newest first', () async {
      final repository = FakeNotes(
        list: [
          note(1, DateTime.utc(2026, 11, 1)),
          note(2, DateTime.utc(2026, 11, 3)),
          note(3, DateTime.utc(2026, 11, 2)),
        ],
      );
      final result = await GetFollowUpNotes(repository)('adult-1');
      expect(
        [
          for (final n in (result as AppSuccess<List<FollowUpNote>>).value)
            n.id,
        ],
        [2, 3, 1],
      );
    });

    test('a personal note with a blank title is rejected locally', () async {
      final repository = FakePersonalNotes();
      final result = await CreatePersonalNote(repository)(
        '  ',
        'texto',
        PersonalNoteCategory.routine,
      );
      expect((result as AppFailure).code, MonitoringFailureCodes.noteRejected);
      expect(repository.created, isEmpty);
    });

    test(
      'contact: a missing channel and a missing name still answer',
      () async {
        final result = await GetContactOption(
          FakeContact(
            channel: const AppFailure(MonitoringFailureCodes.notFound),
            name: const AppFailure('NETWORK_UNAVAILABLE'),
          ),
        )('adult-1');
        final option = (result as AppSuccess<ContactOption>).value;
        expect(option.channel, isNull);
        expect(option.firstName, isNull);
      },
    );

    test('contact: the name is only the first word of the full name', () async {
      final result = await GetContactOption(FakeContact())('adult-1');
      expect((result as AppSuccess<ContactOption>).value.firstName, 'Rosa');
    });

    test('contact: lost access is propagated, not hidden', () async {
      final result = await GetContactOption(
        FakeContact(channel: const AppFailure('ACCESS_DENIED')),
      )('adult-1');
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      final nameDenied = await GetContactOption(
        FakeContact(name: const AppFailure('ACCESS_DENIED')),
      )('adult-1');
      expect((nameDenied as AppFailure).code, 'ACCESS_DENIED');
    });
  });

  group('AlertsBloc', () {
    final now = DateTime.utc(2026, 11, 13, 10);
    AlertTimeline timeline() => AlertTimeline(
      alerts: [
        anAlert(id: 1),
        anAlert(id: 2, status: AlertStatus.closed),
      ],
      doses: [
        dose('past', 'CONFIRMED', DateTime.utc(2026, 11, 13, 8)),
        dose('next', 'PENDING', DateTime.utc(2026, 11, 13, 14)),
        dose('missed', 'PENDING', DateTime.utc(2026, 11, 13, 9)),
      ],
      olderAdultName: 'Rosa',
      day: DateTime(2026, 11, 13),
    );

    AlertsBloc bloc(FakeTimeline reader) => AlertsBloc(
      timeline: GetAlertTimeline(reader),
      olderAdultId: 'adult-1',
      clock: () => now,
    );

    test('filters keep alerts and doses apart', () async {
      final b = bloc(FakeTimeline(AppSuccess(timeline())))
        ..add(const AlertsRequested());
      await b.stream.firstWhere((s) => s.status == AlertsStatus.ready);
      expect([for (final a in b.state.visibleAlerts) a.id], [1, 2]);
      expect([for (final d in b.state.visibleDoses) d.id], ['past', 'next']);

      b.add(const AlertsFilterSelected(AlertFilter.pending));
      await b.stream.first;
      expect([for (final a in b.state.visibleAlerts) a.id], [1]);
      expect(b.state.visibleDoses, isEmpty);

      b.add(const AlertsFilterSelected(AlertFilter.upcoming));
      await b.stream.first;
      expect(b.state.visibleAlerts, isEmpty);
      expect([for (final d in b.state.visibleDoses) d.id], ['next']);

      b.add(const AlertsFilterSelected(AlertFilter.completed));
      await b.stream.first;
      expect([for (final a in b.state.visibleAlerts) a.id], [2]);
      expect([for (final d in b.state.visibleDoses) d.id], ['past']);
      expect(b.state.pendingCount, 1);
      await b.close();
    });

    test('nothing at all is the empty state, a failure is a failure', () async {
      final empty = bloc(
        FakeTimeline(
          AppSuccess(
            AlertTimeline(
              alerts: const [],
              doses: const [],
              olderAdultName: 'Rosa',
              day: DateTime(2026, 11, 13),
            ),
          ),
        ),
      )..add(const AlertsRequested());
      await empty.stream.firstWhere((s) => s.status == AlertsStatus.empty);
      await empty.close();

      final failing = bloc(FakeTimeline(const AppFailure('NOT_FOUND')))
        ..add(const AlertsRequested());
      final state = await failing.stream.firstWhere(
        (s) => s.status == AlertsStatus.failure,
      );
      expect(state.errorCode, 'NOT_FOUND');
      await failing.close();
    });

    test('a new minute does not hit the backend, a new day does', () async {
      final reader = FakeTimeline(AppSuccess(timeline()));
      final b = bloc(reader)..add(const AlertsRequested());
      await b.stream.firstWhere((s) => s.status == AlertsStatus.ready);
      b.add(AlertsClockTicked(now.add(const Duration(minutes: 5))));
      await b.stream.first;
      expect(reader.reads, 1);
      expect(b.state.asOf, now.add(const Duration(minutes: 5)));

      b.add(AlertsClockTicked(DateTime(2026, 11, 14, 1)));
      await pumpEventQueue();
      expect(reader.reads, 2);
      await b.close();
    });
  });

  group('AlertDetailBloc', () {
    AlertDetailBloc build({
      required FakeAlerts alerts,
      FakeContact? contact,
      FakePersonReader? person,
      FakeDoseReader? doses,
      FakeEventsReader? events,
    }) => AlertDetailBloc(
      detail: GetAlertDetail(alerts),
      update: UpdateAlertStatus(alerts),
      contact: GetContactOption(contact ?? FakeContact()),
      people:
          person ??
          FakePersonReader(
            const AppSuccess(
              MonitoredPerson(id: 'adult-1', fullName: 'Rosa', birthDate: null),
            ),
          ),
      doses:
          doses ??
          FakeDoseReader(
            AppSuccess(
              dose('intake-1', 'PENDING', DateTime.utc(2026, 11, 13, 12)),
            ),
          ),
      history: events ?? FakeEventsReader(const AppSuccess([])),
      olderAdultId: 'adult-1',
      alertId: 1,
    );

    test('loads the alert with contact, person and dose', () async {
      final b = build(alerts: FakeAlerts(alerts: [anAlert()]))
        ..add(const AlertDetailRequested());
      await pumpEventQueue();
      expect(b.state.status, AlertDetailStatus.ready);
      expect(b.state.alert?.id, 1);
      expect(b.state.dose?.id, 'intake-1');
      expect(b.state.person?.fullName, 'Rosa');
      expect(b.state.contact.option?.firstName, 'Rosa');
      expect(b.state.history, isEmpty);
      await b.close();
    });

    test('attending moves the alert and reports it', () async {
      final repository = FakeAlerts(alerts: [anAlert()]);
      final b = build(alerts: repository)..add(const AlertDetailRequested());
      await pumpEventQueue();
      b.add(const AlertStatusChangeRequested(AlertStatus.attended));
      await pumpEventQueue();
      expect(repository.updates, [(1, AlertStatus.attended)]);
      expect(b.state.alert?.status, AlertStatus.attended);
      expect(b.state.updating, isNull);
      expect(
        (b.state.feedback as AlertStatusChanged).status,
        AlertStatus.attended,
      );
      await b.close();
    });

    test('a closed alert cannot be changed again', () async {
      final repository = FakeAlerts(
        alerts: [anAlert(status: AlertStatus.closed)],
      );
      final b = build(alerts: repository)..add(const AlertDetailRequested());
      await pumpEventQueue();
      b.add(const AlertStatusChangeRequested(AlertStatus.attended));
      await pumpEventQueue();
      expect(repository.updates, isEmpty);
      await b.close();
    });

    test('a conflict shows the alert as it is now', () async {
      final repository = FakeAlerts(
        alerts: [anAlert()],
      )..updateResult = const AppFailure(MonitoringFailureCodes.statusConflict);
      final b = build(alerts: repository)..add(const AlertDetailRequested());
      await pumpEventQueue();
      repository.detail = AppSuccess(anAlert(status: AlertStatus.closed));
      b.add(const AlertStatusChangeRequested(AlertStatus.attended));
      await pumpEventQueue();
      expect(b.state.alert?.status, AlertStatus.closed);
      expect(
        (b.state.feedback as AlertUpdateFailed).code,
        MonitoringFailureCodes.statusConflict,
      );
      expect(b.state.updating, isNull);
      await b.close();
    });

    test('losing access clears everything protected', () async {
      final repository = FakeAlerts(alerts: [anAlert()]);
      final b = build(alerts: repository)..add(const AlertDetailRequested());
      await pumpEventQueue();
      repository.updateResult = const AppFailure('ACCESS_DENIED');
      b.add(const AlertStatusChangeRequested(AlertStatus.closed));
      await pumpEventQueue();
      expect(b.state.status, AlertDetailStatus.failure);
      expect(b.state.alert, isNull);
      expect(b.state.person, isNull);
      expect(b.state.history, isNull);
      expect(b.state.contact.option, isNull);
      await b.close();
    });

    test('access lost on the person read denies the whole detail', () async {
      final b = build(
        alerts: FakeAlerts(alerts: [anAlert()]),
        person: FakePersonReader(const AppFailure('ACCESS_DENIED')),
      )..add(const AlertDetailRequested());
      await pumpEventQueue();
      expect(b.state.status, AlertDetailStatus.failure);
      expect(b.state.alert, isNull);
      await b.close();
    });
  });

  group('NoteComposerCubit', () {
    NoteComposerCubit cubit(FakeNotes notes) => NoteComposerCubit(
      register: RegisterFollowUpNote(notes),
      olderAdultId: 'adult-1',
    );

    test(
      'a blank note explains itself and does not call the backend',
      () async {
        final repository = FakeNotes();
        final c = cubit(repository)..open();
        await c.save('   ');
        expect(c.state.error, NoteProblem.blank);
        expect(c.state.open, isTrue);
        expect(repository.registered, isEmpty);
        await c.close();
      },
    );

    test('a saved note closes the composer and is handed over', () async {
      final repository = FakeNotes();
      final c = cubit(repository)..open();
      await c.save('Llamé');
      expect(c.state.open, isFalse);
      expect(c.state.saved, isTrue);
      expect(c.state.note?.id, 99);
      await c.close();
    });

    test('a rejected note stays open with the reason', () async {
      final repository = FakeNotes()
        ..registerResult = const AppFailure(
          MonitoringFailureCodes.noteRejected,
        );
      final c = cubit(repository)..open();
      await c.save('Llamé');
      expect(c.state.open, isTrue);
      expect(c.state.error, NoteProblem.rejected);
      await c.close();
    });

    test('clear discards a save that is still in flight', () async {
      final repository = FakeNotes();
      final c = cubit(repository)..open();
      final saving = c.save('Llamé');
      c.clear();
      await saving;
      expect(c.state.open, isFalse);
      expect(c.state.saved, isFalse);
      await c.close();
    });
  });

  group('NotesBloc', () {
    NotesBloc build(FakeNotes notes, FakePersonReader person) => NotesBloc(
      notes: GetFollowUpNotes(notes),
      people: person,
      olderAdultId: 'adult-1',
    );

    final rosa = FakePersonReader(
      const AppSuccess(
        MonitoredPerson(id: 'adult-1', fullName: 'Rosa', birthDate: null),
      ),
    );

    blocTest<NotesBloc, NotesState>(
      'no notes is the empty state',
      build: () => build(FakeNotes(), rosa),
      act: (b) => b.add(const NotesRequested()),
      verify: (b) {
        expect(b.state.status, NotesStatus.empty);
        expect(b.state.person?.fullName, 'Rosa');
      },
    );

    test('an acknowledged note goes on top without a reload', () async {
      final b = build(
        FakeNotes(list: [note(1, DateTime.utc(2026, 11, 1))]),
        rosa,
      )..add(const NotesRequested());
      await pumpEventQueue();
      b.add(NoteAdded(note(2, DateTime.utc(2026, 11, 2))));
      await pumpEventQueue();
      expect([for (final n in b.state.notes) n.id], [2, 1]);
      await b.close();
    });

    test('lost access removes the notes it had', () async {
      final repository = FakeNotes(list: [note(1, DateTime.utc(2026, 11, 1))]);
      final b = build(repository, rosa)..add(const NotesRequested());
      await pumpEventQueue();
      b.add(const NotesAccessLost('ACCESS_DENIED'));
      await pumpEventQueue();
      expect(b.state.status, NotesStatus.failure);
      expect(b.state.notes, isEmpty);
      await b.close();
    });
  });

  group('PersonalNotesBloc', () {
    PersonalNotesBloc build(FakePersonalNotes repository) => PersonalNotesBloc(
      list: GetPersonalNotes(repository),
      create: CreatePersonalNote(repository),
    );

    PersonalNote personal(int id, PersonalNoteCategory category) =>
        PersonalNote(
          id: id,
          title: 't$id',
          text: 'x',
          category: category,
          recordedAt: DateTime.utc(2026, 11, 13),
        );

    test('filters by category without touching the backend', () async {
      final repository = FakePersonalNotes()
        ..listResult = AppSuccess([
          personal(1, PersonalNoteCategory.medication),
          personal(2, PersonalNoteCategory.routine),
        ]);
      final b = build(repository)..add(const PersonalNotesRequested());
      await pumpEventQueue();
      b.add(const PersonalNotesFiltered(PersonalNoteCategory.routine));
      await pumpEventQueue();
      expect([for (final n in b.state.visibleNotes) n.id], [2]);
      b.add(const PersonalNotesFiltered(null));
      await pumpEventQueue();
      expect(b.state.visibleNotes, hasLength(2));
      await b.close();
    });

    test('a saved note joins the list and closes the composer', () async {
      final repository = FakePersonalNotes();
      final b = build(repository)
        ..add(const PersonalNotesRequested())
        ..add(const PersonalNoteComposerToggled(open: true));
      await pumpEventQueue();
      expect(b.state.composing, isTrue);
      b.add(
        const PersonalNoteSubmitted(
          title: 'Agua',
          text: 'Tomar agua',
          category: PersonalNoteCategory.routine,
        ),
      );
      await pumpEventQueue();
      expect(b.state.notes.single.title, 'Agua');
      expect(b.state.composing, isFalse);
      expect(b.state.saving, isFalse);
      await b.close();
    });

    test('a failed save keeps the composer for another try', () async {
      final repository = FakePersonalNotes()
        ..createResult = const AppFailure('NETWORK_UNAVAILABLE');
      final b = build(repository)
        ..add(const PersonalNotesRequested())
        ..add(const PersonalNoteComposerToggled(open: true));
      await pumpEventQueue();
      b.add(
        const PersonalNoteSubmitted(
          title: 'Agua',
          text: 'Tomar agua',
          category: PersonalNoteCategory.routine,
        ),
      );
      await pumpEventQueue();
      expect(b.state.composing, isTrue);
      expect(b.state.saveError, isTrue);
      expect(b.state.saving, isFalse);
      await b.close();
    });

    test('without the adult session nothing stays on screen', () async {
      final repository = FakePersonalNotes()
        ..listResult = const AppFailure('AUTHENTICATION_REQUIRED');
      final b = build(repository)..add(const PersonalNotesRequested());
      await pumpEventQueue();
      expect(b.state.requiresSignIn, isTrue);
      expect(b.state.notes, isEmpty);
      b.add(const PersonalNoteComposerToggled(open: true));
      await pumpEventQueue();
      expect(b.state.composing, isFalse);
      await b.close();
    });
  });
}
