import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/domain/entities/medication.dart';
import 'package:tata/features/treatment_management/domain/entities/treatment.dart';
import 'package:tata/features/treatment_management/domain/repositories/treatment_repositories.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_regimen.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/shared/common/result/app_result.dart';

/// In-memory backend: the server is the source of truth for status and regimen.
final class FakeBackend
    implements
        TreatmentRepository,
        MedicationManagementRepository,
        TreatmentLifecycleRepository {
  final medications = <String, Medication>{
    'med-1': Medication(
      id: 'med-1',
      olderAdultId: 'adult-A',
      name: 'Metformina',
      presentation: '500 mg',
      active: true,
    ),
  };
  TreatmentDetail? stored;
  String? failure;
  String? configureFailure;
  int configureCalls = 0;
  int createCalls = 0;

  AppResult<T> _fail<T>() => AppFailure<T>(failure!);

  @override
  Future<AppResult<Medication>> registerMedication(
    String olderAdultId,
    String name,
    String presentation,
  ) async {
    if (failure != null) return _fail();
    final medication = Medication(
      id: 'med-${medications.length + 1}',
      olderAdultId: olderAdultId,
      name: name,
      presentation: presentation,
      active: true,
    );
    medications[medication.id] = medication;
    return AppSuccess(medication);
  }

  @override
  Future<AppResult<Treatment>> createTreatment(
    String olderAdultId,
    String name,
  ) async {
    createCalls++;
    if (failure != null) return _fail();
    stored = TreatmentDetail(
      id: 'tr-1',
      olderAdultId: olderAdultId,
      name: name,
      status: TreatmentStatus.draft,
    );
    return AppSuccess(
      Treatment(
        id: 'tr-1',
        olderAdultId: olderAdultId,
        name: name,
        status: TreatmentStatus.draft,
      ),
    );
  }

  @override
  Future<AppResult<List<Medication>>> list(String olderAdultId) async =>
      failure != null ? _fail() : AppSuccess(medications.values.toList());

  @override
  Future<AppResult<Medication>> update(
    String medicationId,
    String name,
    String presentation,
  ) async {
    if (failure != null) return _fail();
    final old = medications[medicationId]!;
    return AppSuccess(
      medications[medicationId] = Medication(
        id: old.id,
        olderAdultId: old.olderAdultId,
        name: name,
        presentation: presentation,
        active: old.active,
      ),
    );
  }

  Medication _availability(String id, bool active) {
    final old = medications[id]!;
    return medications[id] = Medication(
      id: old.id,
      olderAdultId: old.olderAdultId,
      name: old.name,
      presentation: old.presentation,
      active: active,
    );
  }

  @override
  Future<AppResult<Medication>> deactivate(String medicationId) async =>
      failure != null
      ? _fail()
      : AppSuccess(_availability(medicationId, false));

  @override
  Future<AppResult<Medication>> reactivate(String medicationId) async =>
      failure != null ? _fail() : AppSuccess(_availability(medicationId, true));

  Treatment _treatment(TreatmentStatus status) {
    final old = stored!;
    stored = TreatmentDetail(
      id: old.id,
      olderAdultId: old.olderAdultId,
      name: old.name,
      status: status,
      medicationId: old.medicationId,
      dose: old.dose,
      frequency: old.frequency,
      scheduledTimes: old.scheduledTimes,
      instructions: old.instructions,
      reminderLeadMinutes: old.reminderLeadMinutes,
      followUpDelayMinutes: old.followUpDelayMinutes,
      recurrenceZone: old.recurrenceZone,
    );
    return Treatment(
      id: old.id,
      olderAdultId: old.olderAdultId,
      name: old.name,
      status: status,
    );
  }

  @override
  Future<AppResult<Treatment>> configure(
    String treatmentId,
    String medicationId,
    TreatmentRegimen regimen,
  ) async {
    configureCalls++;
    if (configureFailure != null) return AppFailure(configureFailure!);
    if (failure != null) return _fail();
    final old = stored!;
    stored = TreatmentDetail(
      id: old.id,
      olderAdultId: old.olderAdultId,
      name: old.name,
      status: old.status,
      medicationId: medicationId,
      dose: regimen.dose.value,
      frequency: regimen.frequency.value,
      scheduledTimes: regimen.schedule.times.map((t) => '$t').toList(),
      instructions: regimen.instructions.value,
      reminderLeadMinutes: regimen.reminderLeadMinutes,
      followUpDelayMinutes: regimen.followUpDelay?.value,
      recurrenceZone: old.recurrenceZone,
    );
    return AppSuccess(_treatment(old.status));
  }

  @override
  Future<AppResult<Treatment>> activate(String treatmentId) async =>
      failure != null
      ? _fail()
      : AppSuccess(_treatment(TreatmentStatus.active));

  @override
  Future<AppResult<Treatment>> pause(String treatmentId) async =>
      failure != null
      ? _fail()
      : AppSuccess(_treatment(TreatmentStatus.paused));

  @override
  Future<AppResult<Treatment>> resume(String treatmentId) async =>
      failure != null
      ? _fail()
      : AppSuccess(_treatment(TreatmentStatus.active));
}
