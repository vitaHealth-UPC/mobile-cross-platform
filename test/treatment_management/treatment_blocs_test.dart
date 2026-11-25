import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/ports/my_medications_reader.dart';
import 'package:tata/features/treatment_management/application/ports/treatment_reader.dart';
import 'package:tata/features/treatment_management/application/readmodels/my_medications_overview.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_detail.dart';
import 'package:tata/features/treatment_management/application/usecases/change_treatment_status.dart';
import 'package:tata/features/treatment_management/application/usecases/configure_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/create_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/deactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/delete_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/get_my_medications_overview.dart';
import 'package:tata/features/treatment_management/application/usecases/get_treatment_detail.dart';
import 'package:tata/features/treatment_management/application/usecases/list_medications.dart';
import 'package:tata/features/treatment_management/application/usecases/reactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/set_dose_frequency.dart';
import 'package:tata/features/treatment_management/application/usecases/set_reminder_policy.dart';
import 'package:tata/features/treatment_management/application/usecases/set_schedule_instructions.dart';
import 'package:tata/features/treatment_management/application/usecases/update_medication.dart';
import 'package:tata/features/treatment_management/domain/value_objects/administration_schedule.dart';
import 'package:tata/features/treatment_management/domain/value_objects/regimen_text.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_state.dart';
import 'package:tata/features/treatment_management/presentation/bloc/my_medications/my_medications_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_management/treatment_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_management/treatment_management_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_management/treatment_management_state.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_state.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/fake_treatment_backend.dart';

final class FakeReader implements TreatmentReader {
  FakeReader(this.backend);
  final FakeBackend backend;
  String? detailFailure;
  int? failOnCall;
  int _detailCalls = 0;

  @override
  Future<AppResult<List<TreatmentDetail>>> list(String olderAdultId) async =>
      AppSuccess(backend.treatments.values.toList());

  @override
  Future<AppResult<TreatmentDetail>> detail(String treatmentId) async {
    _detailCalls++;
    final failure =
        detailFailure != null &&
            (failOnCall == null || _detailCalls >= failOnCall!)
        ? detailFailure
        : backend.failure;
    return failure != null
        ? AppFailure(failure)
        : (backend.treatments[treatmentId] ?? backend.stored) == null
        ? const AppFailure('RESOURCE_NOT_FOUND')
        : AppSuccess(backend.treatments[treatmentId] ?? backend.stored!);
  }
}

TreatmentSetupBloc setupBloc(FakeBackend backend) => TreatmentSetupBloc(
  create: CreateTreatment(backend),
  basics: const SetDoseFrequency(),
  schedule: const SetScheduleInstructions(),
  reminder: const SetReminderPolicy(),
  read: GetTreatmentDetail(FakeReader(backend)),
  configure: ConfigureTreatment(backend),
  changeStatus: ChangeTreatmentStatus(backend),
  olderAdultId: 'adult-A',
  medications: const [SetupMedication('med-1', 'Metformina 500 mg')],
);

TreatmentManagementBloc managementBloc(
  FakeBackend backend, {
  TreatmentReader? reader,
}) => TreatmentManagementBloc(
  detail: GetTreatmentDetail(reader ?? FakeReader(backend)),
  medications: ListMedications(backend),
  configure: ConfigureTreatment(backend),
  changeStatus: ChangeTreatmentStatus(backend),
  reactivate: ReactivateMedication(backend),
  deactivate: DeactivateMedication(backend),
  treatmentId: 'tr-1',
  olderAdultId: 'adult-A',
);

/// Lets chained futures of the in-memory backend settle.
Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('domain values', () {
    test('clock times accept one or two digit hours and normalize', () {
      expect('${ClockTime.tryParse('8:05')}', '08:05');
      expect(ClockTime.tryParse('24:00'), isNull);
      expect(ClockTime.tryParse('08:60'), isNull);
      expect('${ClockTime.tryParseServer('20:00:00')}', '20:00');
    });

    test('schedule is sorted, distinct and not empty', () {
      final schedule = AdministrationSchedule.create([
        ClockTime.tryParse('20:00')!,
        ClockTime.tryParse('08:00')!,
        ClockTime.tryParse('08:00')!,
      ]);
      expect(schedule!.times.map((t) => '$t'), ['08:00', '20:00']);
      expect(AdministrationSchedule.create(const []), isNull);
    });

    test('regimen texts enforce the server limits', () {
      expect(Dosage.tryParse(''), isNull);
      expect(Dosage.tryParse('x' * 101), isNull);
      expect(Frequency.tryParse('cada 8 horas'), isNotNull);
      expect(AdministrationInstructions.tryParse('x' * 501), isNull);
      expect(ReminderDelayMinutes.tryParse('1440'), isNotNull);
      expect(ReminderDelayMinutes.tryParse('1441'), isNull);
      expect(ReminderDelayMinutes.tryParse('-1'), isNull);
    });
  });

  group('setup wizard', () {
    test('walks every step and activates the treatment', () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.regimen);
      // Nothing reaches the server before activation.
      expect(bloc.state.treatmentId, isNull);
      expect(backend.createCalls, 0);
      bloc.add(const RegimenBasicsSubmitted('1 tableta', 'cada 12 horas'));
      bloc.add(const ScheduleSubmitted('20:00, 8:00', 'Con comida'));
      bloc.add(const ReminderSubmitted(''));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.review);
      expect(bloc.state.scheduledTimes, ['08:00', '20:00']);
      expect(bloc.state.followUpDelayMinutes, isNull);
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isTrue);
      expect(bloc.state.treatmentId, 'tr-1');
      expect(backend.stored!.status, TreatmentStatus.active);
      expect(backend.configureCalls, 1);
    });

    test('one treatment holds several medications sharing a plan', () async {
      final backend = FakeBackend();
      await backend.registerMedication('adult-A', 'Glibenclamida', '5 mg');
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(
        const TreatmentMedicationsChanged([
          SetupMedication('med-1', 'Metformina 500 mg'),
          SetupMedication('med-2', 'Glibenclamida 5 mg'),
        ]),
      );
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      bloc.add(
        const TreatmentRegimensSubmitted({
          'med-1': RegimenInput(
            '1 tableta',
            'Cada 12 horas',
            '08:00,20:00',
            '',
          ),
          'med-2': RegimenInput(
            '1 tableta',
            'Una vez al día',
            '07:30',
            'Antes del desayuno',
          ),
        }),
      );
      bloc.add(const ReminderSubmitted(''));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.review);
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isTrue);
      expect(backend.createCalls, 2);
      expect(backend.configureCalls, 2);
      final stored = backend.treatments.values.toList();
      expect(stored.map((t) => t.planId).toSet(), {'tr-1'});
      expect(stored.map((t) => t.medicationId), ['med-1', 'med-2']);
      expect(stored.every((t) => t.status == TreatmentStatus.active), isTrue);
    });

    test('a regimen error names the medication that caused it', () async {
      final bloc = setupBloc(FakeBackend());
      addTearDown(bloc.close);
      bloc.add(
        const TreatmentMedicationsChanged([
          SetupMedication('med-1', 'Metformina 500 mg'),
          SetupMedication('med-2', 'Glibenclamida 5 mg'),
        ]),
      );
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      bloc.add(
        const TreatmentRegimensSubmitted({
          'med-1': RegimenInput('1 tableta', 'Cada 8 horas', '08:00,16:00', ''),
          'med-2': RegimenInput('1 tableta', 'Una vez al día', '07:30', ''),
        }),
      );
      await settle();
      expect(bloc.state.errorCode, 'SCHEDULE_FREQUENCY_MISMATCH');
      expect(bloc.state.errorMedicationId, 'med-1');
      expect(bloc.state.step, TreatmentSetupStep.regimen);
    });

    test('a treatment needs at least one medication', () async {
      final bloc = setupBloc(FakeBackend())
        ..add(const TreatmentMedicationsChanged([]));
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      expect(bloc.state.errorCode, 'MEDICATION_REQUIRED');
      expect(bloc.state.step, TreatmentSetupStep.details);
    });

    test('invalid steps stay put and report a stable code', () async {
      final bloc = setupBloc(FakeBackend());
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      bloc.add(const RegimenBasicsSubmitted('', 'x'));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.regimen);
      expect(bloc.state.errorCode, 'INVALID_DOSAGE');
      bloc.add(const RegimenBasicsSubmitted('1', 'x'));
      await settle();
      expect(bloc.state.errorCode, 'INVALID_FREQUENCY');
      bloc.add(const RegimenBasicsSubmitted('1', 'Cada día'));
      bloc.add(const ScheduleSubmitted('99:99', ''));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.schedule);
      expect(bloc.state.errorCode, 'INVALID_SCHEDULE_TIME');
    });

    test('going back and retrying never creates a second draft', () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      bloc.add(const TreatmentSetupBackRequested());
      await settle();
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      expect(backend.createCalls, 0);
      expect(bloc.state.step, TreatmentSetupStep.regimen);
      bloc.add(const RegimenBasicsSubmitted('1', 'Cada día'));
      bloc.add(const ScheduleSubmitted('08:00', ''));
      bloc.add(const ReminderSubmitted(''));
      await settle();
      backend.configureFailure = 'REQUEST_FAILED';
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isFalse);
      backend.configureFailure = null;
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isTrue);
      expect(backend.createCalls, 1);
    });

    test('a rejected activation reports the code and stops loading', () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      bloc.add(const RegimenBasicsSubmitted('1', 'Cada día'));
      bloc.add(const ScheduleSubmitted('08:00', ''));
      bloc.add(const ReminderSubmitted('10'));
      await settle();
      backend.failure = 'REQUEST_VALIDATION_FAILED';
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isFalse);
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.errorCode, 'REQUEST_VALIDATION_FAILED');
    });
  });

  group('treatment management', () {
    Future<(FakeBackend, TreatmentManagementBloc)> active() async {
      final backend = FakeBackend();
      final setup = setupBloc(backend);
      addTearDown(setup.close);
      setup.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      setup.add(const RegimenBasicsSubmitted('1 tableta', 'cada 12 horas'));
      setup.add(const ScheduleSubmitted('08:00,20:00', ''));
      setup.add(const ReminderSubmitted('15'));
      await settle();
      setup.add(const TreatmentActivationRequested());
      await settle();
      final bloc = managementBloc(backend)
        ..add(const TreatmentManagementRequested());
      addTearDown(bloc.close);
      await settle();
      return (backend, bloc);
    }

    test('loads the treatment together with its medication', () async {
      final (_, bloc) = await active();
      expect(bloc.state.status, TreatmentManagementStatus.ready);
      expect(bloc.state.manageable, isTrue);
      expect(bloc.state.medication!.name, 'Metformina');
      expect(bloc.state.activeMedicationCount, 1);
    });

    test('pauses and resumes using the acknowledged status', () async {
      final (_, bloc) = await active();
      bloc.add(const TreatmentPauseRequested());
      await settle();
      expect(bloc.state.detail!.status, TreatmentStatus.paused);
      bloc.add(const TreatmentResumeRequested());
      await settle();
      expect(bloc.state.detail!.status, TreatmentStatus.active);
    });

    test('editing the regimen reloads what the server stored', () async {
      final (backend, bloc) = await active();
      bloc.add(
        const RegimenEdited(
          dose: '2 tabletas',
          frequency: 'cada 8 horas',
          scheduleText: '06:00, 14:00, 22:00',
          instructions: '',
          delayMinutes: '',
        ),
      );
      await settle();
      expect(bloc.state.notice, TreatmentManagementNotice.regimenSaved);
      expect(bloc.state.detail!.scheduledTimes, ['06:00', '14:00', '22:00']);
      expect(backend.stored!.dose, '2 tabletas');
      // Editing never changes the lifecycle state.
      expect(bloc.state.detail!.status, TreatmentStatus.active);
    });

    test('an out-of-range reminder delay is refused locally', () async {
      final (backend, bloc) = await active();
      final calls = backend.configureCalls;
      bloc.add(
        const RegimenEdited(
          dose: 'x',
          frequency: 'x',
          scheduleText: '08:00',
          instructions: '',
          delayMinutes: '5000',
        ),
      );
      await settle();
      expect(bloc.state.errorCode, 'INVALID_REMINDER_DELAY');
      expect(backend.configureCalls, calls);
    });

    test('an invalid reminder lead is refused before any request', () async {
      final (backend, bloc) = await active();
      final calls = backend.configureCalls;
      for (final lead in ['', '-1', '1441', 'not a number']) {
        bloc.add(
          RegimenEdited(
            dose: '1 tableta',
            frequency: 'cada día',
            scheduleText: '08:00',
            instructions: '',
            delayMinutes: '',
            leadMinutes: lead,
          ),
        );
        await settle();
        expect(bloc.state.errorCode, 'INVALID_REMINDER_LEAD');
        expect(backend.configureCalls, calls);
      }
    });

    test(
      'a caller without lead input preserves the latest server value',
      () async {
        final (backend, bloc) = await active();
        final previous = backend.stored!;
        backend.stored = TreatmentDetail(
          id: previous.id,
          olderAdultId: previous.olderAdultId,
          name: previous.name,
          status: previous.status,
          medicationId: previous.medicationId,
          dose: previous.dose,
          frequency: previous.frequency,
          scheduledTimes: previous.scheduledTimes,
          instructions: previous.instructions,
          reminderLeadMinutes: 45,
          followUpDelayMinutes: previous.followUpDelayMinutes,
          recurrenceZone: previous.recurrenceZone,
        );
        bloc.add(
          const RegimenEdited(
            dose: '1 tableta',
            frequency: 'cada día',
            scheduleText: '08:00',
            instructions: '',
            delayMinutes: '15',
          ),
        );
        await settle();
        expect(backend.stored!.reminderLeadMinutes, 45);
        expect(bloc.state.detail!.reminderLeadMinutes, 45);
        expect(bloc.state.notice, TreatmentManagementNotice.regimenSaved);
      },
    );

    test(
      'an inactive medication blocks pause but can be reactivated',
      () async {
        final (backend, bloc) = await active();
        bloc.add(const TreatmentMedicationDeactivated());
        await settle();
        expect(bloc.state.medicationInactive, isTrue);
        expect(bloc.state.activeMedicationCount, 0);
        bloc.add(const TreatmentPauseRequested());
        await settle();
        expect(backend.stored!.status, TreatmentStatus.paused);
        bloc.add(const TreatmentMedicationReactivated());
        await settle();
        expect(bloc.state.medicationInactive, isFalse);
        expect(bloc.state.activeMedicationCount, 1);
        expect(bloc.state.detail!.status, TreatmentStatus.paused);
        expect(
          bloc.state.notice,
          TreatmentManagementNotice.medicationReactivated,
        );
      },
    );

    test(
      'a failed post-availability read hides stale data and retries by reading',
      () async {
        final (backend, _) = await active();
        final reader = FakeReader(backend);
        final bloc = managementBloc(backend, reader: reader)
          ..add(const TreatmentManagementRequested());
        addTearDown(bloc.close);
        await settle();
        reader.detailFailure = 'NETWORK_UNAVAILABLE';
        bloc.add(const TreatmentMedicationDeactivated());
        await settle();
        expect(backend.medications['med-1']!.active, isFalse);
        expect(bloc.state.status, TreatmentManagementStatus.failure);
        expect(bloc.state.detail, isNull);
        expect(bloc.state.notice, isNull);
        reader.detailFailure = null;
        bloc.add(const TreatmentManagementRequested());
        await settle();
        expect(bloc.state.detail!.status, TreatmentStatus.paused);
        expect(bloc.state.medicationInactive, isTrue);
        expect(bloc.state.notice, isNull);
      },
    );

    test('access denied after saving a regimen removes the protected receipt and detail', () async {
      final (backend, _) = await active();
      final reader = FakeReader(backend);
      final bloc = managementBloc(backend, reader: reader)
        ..add(const TreatmentManagementRequested());
      addTearDown(bloc.close);
      await settle();
      reader.detailFailure = 'ACCESS_DENIED';
      reader.failOnCall = 3;
      bloc.add(
        const RegimenEdited(
          dose: '2 tabletas',
          frequency: 'cada día',
          scheduleText: '08:00',
          instructions: '',
          delayMinutes: '15',
        ),
      );
      await settle();
      expect(backend.stored!.dose, '2 tabletas');
      expect(bloc.state.status, TreatmentManagementStatus.failure);
      expect(bloc.state.errorCode, 'ACCESS_DENIED');
      expect(bloc.state.detail, isNull);
      expect(bloc.state.medication, isNull);
      expect(bloc.state.notice, isNull);
    });

    test('an authorization failure leaves no management actions', () async {
      final (backend, bloc) = await active();
      backend.failure = 'ACCESS_DENIED';
      bloc.add(const TreatmentPauseRequested());
      await settle();
      expect(bloc.state.status, TreatmentManagementStatus.failure);
      expect(bloc.state.errorCode, 'ACCESS_DENIED');
    });
  });

  group('medication management', () {
    MedicationManagementBloc build(FakeBackend backend) =>
        MedicationManagementBloc(
          list: ListMedications(backend),
          update: UpdateMedication(backend),
          deactivate: DeactivateMedication(backend),
          delete: DeleteMedication(backend),
          reactivate: ReactivateMedication(backend),
          olderAdultId: 'adult-A',
        );

    test(
      'edit and deactivate replace only their row and announce it',
      () async {
        final subject = build(FakeBackend())..add(const MedicationsRequested());
        addTearDown(subject.close);
        await settle();
        expect(subject.state.status, MedicationManagementStatus.ready);
        subject.add(const MedicationEdited('med-1', 'Metformina XR', '850 mg'));
        await settle();
        expect(subject.state.medications.single.name, 'Metformina XR');
        expect(subject.state.notice, MedicationNotice.updated);
        subject.add(const MedicationDeactivated('med-1'));
        await settle();
        expect(subject.state.medications.single.active, isFalse);
        expect(subject.state.notice, MedicationNotice.deactivated);
      },
    );

    test('a failed change keeps the list and reports the code', () async {
      final backend = FakeBackend();
      final subject = build(backend)..add(const MedicationsRequested());
      addTearDown(subject.close);
      await settle();
      backend.failure = 'CONFLICT';
      subject.add(const MedicationDeactivated('med-1'));
      await settle();
      expect(subject.state.medications.single.active, isTrue);
      expect(subject.state.errorCode, 'CONFLICT');
      expect(subject.state.busy, isFalse);
    });
  });

  group('my medications', () {
    test('a failed lookup is a failure, never an empty agenda', () async {
      final bloc = MyMedicationsBloc(
        overview: GetMyMedicationsOverview(
          _FailingCatalog(),
          () async => const AppSuccess(null),
        ),
      )..add(const MyMedicationsRequested());
      addTearDown(bloc.close);
      await settle();
      expect(bloc.state.status, MyMedicationsStatus.failure);
      expect(bloc.state.errorCode, 'NETWORK_UNAVAILABLE');
    });

    test('history switches without losing the loaded catalog', () async {
      final bloc = MyMedicationsBloc(
        overview: GetMyMedicationsOverview(
          _Catalog(),
          () async => AppSuccess(
            MedicationNextDose(
              intakeId: 'i',
              medicationName: 'Metformina',
              scheduledAt: DateTime.utc(2026, 1, 1, 8),
            ),
          ),
        ),
      )..add(const MyMedicationsRequested());
      addTearDown(bloc.close);
      await settle();
      expect(bloc.state.active.single.name, 'Activa');
      expect(bloc.state.inactive.single.name, 'Pasada');
      expect(bloc.state.nextDose!.medicationName, 'Metformina');
      bloc.add(const MyMedicationsHistorySelected(true));
      await settle();
      expect(bloc.state.history, isTrue);
      expect(bloc.state.medications, hasLength(2));
    });
  });
}

final class _FailingCatalog implements MyMedicationsReader {
  @override
  Future<AppResult<List<MyMedication>>> list() async =>
      const AppFailure('NETWORK_UNAVAILABLE');
}

final class _Catalog implements MyMedicationsReader {
  @override
  Future<AppResult<List<MyMedication>>> list() async => const AppSuccess([
    MyMedication(
      id: 'a',
      name: 'Activa',
      presentation: 'x',
      active: true,
      dose: '1',
      instructions: '',
      scheduledTimes: ['08:00'],
    ),
    MyMedication(
      id: 'b',
      name: 'Pasada',
      presentation: 'x',
      active: false,
      dose: '1',
      instructions: '',
      scheduledTimes: [],
    ),
  ]);
}
