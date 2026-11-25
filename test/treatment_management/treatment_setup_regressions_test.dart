import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_detail.dart';
import 'package:tata/features/treatment_management/domain/value_objects/regimen_text.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_state.dart';

import '../support/fake_treatment_backend.dart';
import 'treatment_blocs_test.dart' show setupBloc, settle;

void main() {
  test('backend labels and complete daily interval cycles agree', () {
    final f = Frequency.tryParse('Cada 8 horas')!;
    expect(f.matchesMinutes([650]), isFalse);
    expect(f.matchesMinutes([170, 650, 1130]), isTrue);
    expect(f.matchesMinutes([170, 650, 1140]), isFalse);
    expect(Frequency.tryParse('Every 12 hours')!.backendValue, 'Cada 12 horas');
    expect(
      Frequency.tryParse('Once a day')!.matchesMinutes([480, 1200]),
      isFalse,
    );
    expect(Frequency.tryParse('Según indicación médica'), isNotNull);
    // Any whole-hour interval that completes the day is accepted, as the
    // server does; other intervals are not.
    expect(Frequency.tryParse('cada 6 horas')!.expectedCount, 4);
    expect(Frequency.tryParse('Every 6 hours')!.backendValue, 'Cada 6 horas');
    expect(Frequency.tryParse('cada 7 horas'), isNull);
    expect(Frequency.tryParse('Cada 6 horas')!.minutesFrom(480), [
      120,
      480,
      840,
      1200,
    ]);
  });
  test(
    'tester schedule is rejected before sending configure and can be corrected',
    () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Test'));
      await settle();
      bloc.add(
        const TreatmentRegimenSubmitted(
          '1 tableta',
          'Cada 8 horas',
          '10:50',
          'Con el desayuno',
        ),
      );
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.regimen);
      expect(bloc.state.errorCode, 'SCHEDULE_FREQUENCY_MISMATCH');
      expect(backend.configureCalls, 0);
      bloc.add(
        const TreatmentRegimenSubmitted(
          '1 tableta',
          'Cada 8 horas',
          '02:50,10:50,18:50',
          'Con el desayuno',
        ),
      );
      await settle();
      expect(bloc.state.step, TreatmentSetupStep.reminders);
      bloc.add(const ReminderSubmitted('10'));
      await settle();
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isTrue);
      expect(backend.configureCalls, 1);
      expect(backend.stored!.scheduledTimes, ['02:50', '10:50', '18:50']);
    },
  );

  test(
    'a stale wizard never announces a paused treatment as activated',
    () async {
      final backend = FakeBackend();
      final bloc = setupBloc(backend);
      addTearDown(bloc.close);
      bloc.add(const TreatmentDraftSubmitted('Control'));
      await settle();
      bloc.add(const RegimenBasicsSubmitted('1 tableta', 'Cada día'));
      await settle();
      bloc.add(const ScheduleSubmitted('08:00', ''));
      await settle();
      bloc.add(const ReminderSubmitted(''));
      await settle();
      // The first attempt leaves a draft behind (the network failed while
      // saving its regimen); meanwhile the treatment changed elsewhere.
      backend.configureFailure = 'NETWORK_UNAVAILABLE';
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.treatmentId, 'tr-1');
      backend.configureFailure = null;
      backend.stored = const TreatmentDetail(
        id: 'tr-1',
        olderAdultId: 'adult-A',
        name: 'Control',
        status: TreatmentStatus.paused,
      );
      final configured = backend.configureCalls;
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isFalse);
      expect(bloc.state.errorCode, 'CONFLICT');
      expect(backend.configureCalls, configured);
    },
  );
  test('rejected configuration returns to the regimen without recreating the draft', () async {
    final backend = FakeBackend();
    final bloc = setupBloc(backend);
    addTearDown(bloc.close);
    bloc.add(const TreatmentDraftSubmitted('Control'));
    await settle();
    bloc.add(const RegimenBasicsSubmitted('1 tableta', 'Cada día'));
    await settle();
    bloc.add(const ScheduleSubmitted('08:00', 'Con agua'));
    await settle();
    bloc.add(const ReminderSubmitted('10'));
    await settle();
    backend.configureFailure = 'INVALID_TREATMENT_CONFIGURATION';
    bloc.add(const TreatmentActivationRequested());
    await settle();
    expect(bloc.state.configurationIncomplete, isTrue);
    final id = bloc.state.treatmentId;
    bloc.add(const TreatmentConfigurationCorrectionRequested());
    await settle();
    expect(bloc.state.step, TreatmentSetupStep.regimen);
    expect(bloc.state.treatmentId, id);
    expect(bloc.state.dose, '1 tableta');
    expect(bloc.state.scheduleText, '08:00');
    expect(bloc.state.configurationIncomplete, isFalse);
    expect(backend.createCalls, 1);
  });
}
