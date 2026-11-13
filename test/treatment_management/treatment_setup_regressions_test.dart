import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_state.dart';

import '../support/fake_treatment_backend.dart';
import 'treatment_blocs_test.dart' show setupBloc, settle;

void main() {
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
      backend.stored = const TreatmentDetail(
        id: 'tr-1',
        olderAdultId: 'adult-A',
        name: 'Control',
        status: TreatmentStatus.paused,
      );
      bloc.add(const TreatmentActivationRequested());
      await settle();
      expect(bloc.state.activated, isFalse);
      expect(bloc.state.errorCode, 'CONFLICT');
      expect(backend.configureCalls, 0);
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
