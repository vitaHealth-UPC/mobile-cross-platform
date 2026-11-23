import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/ports/treatment_readers.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/application/usecases/medication_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/regimen_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
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

  @override
  Future<AppResult<List<TreatmentDetail>>> list(String olderAdultId) async =>
      AppSuccess([?backend.stored]);

  @override
  Future<AppResult<TreatmentDetail>> detail(String treatmentId) async =>
      backend.failure != null
      ? AppFailure(backend.failure!)
      : backend.stored == null
      ? const AppFailure('RESOURCE_NOT_FOUND')
      : AppSuccess(backend.stored!);
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
  medicationId: 'med-1',
);

TreatmentManagementBloc managementBloc(FakeBackend backend) =>
    TreatmentManagementBloc(
      detail: GetTreatmentDetail(FakeReader(backend)),
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
      expect(bloc.state.treatmentId, 'tr-1');
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
      expect(backend.stored!.status, TreatmentStatus.active);
      expect(backend.configureCalls, 1);
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
      bloc.add(const ScheduleSubmitted('99:99', ''));
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.schedule);
      expect(bloc.state.errorCode, 'INVALID_SCHEDULE_TIME');
    });

    test('going back keeps the draft and never creates a second one', () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      bloc.add(const TreatmentSetupBackRequested());
      await settle();
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      expect(backend.createCalls, 1);
      expect(bloc.state.step, TreatmentSetupStep.regimen);
    });

    test('a rejected activation reports the code and stops loading', () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Diabetes'));
      await settle();
      bloc.add(const RegimenBasicsSubmitted('1', 'x'));
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
      setup.add(const ScheduleSubmitted('08:00', ''));
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
      expect(bloc.state.regimenSaved, isTrue);
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
        expect(backend.stored!.status, TreatmentStatus.active);
        bloc.add(const TreatmentMedicationReactivated());
        await settle();
        expect(bloc.state.medicationInactive, isFalse);
        expect(bloc.state.activeMedicationCount, 1);
      },
    );

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
