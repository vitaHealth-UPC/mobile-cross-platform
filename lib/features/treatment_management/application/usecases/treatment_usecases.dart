import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repositories.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';
import '../../domain/value_objects/treatment_regimen.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../ports/treatment_readers.dart';
import '../readmodels/treatment_readmodels.dart';

bool _blank(String value) => value.trim().isEmpty;

/// Creates a named draft; the saved treatment must remain a draft until it is configured.
final class CreateTreatment {
  const CreateTreatment(this._repository);
  final TreatmentRepository _repository;

  Future<AppResult<Treatment>> call(String olderAdultId, String name) async {
    if (_blank(olderAdultId) || _blank(name)) {
      return const AppFailure('REQUIRED_FIELDS_MISSING');
    }
    final result = await _repository.createTreatment(
      olderAdultId.trim(),
      name.trim(),
    );
    return switch (result) {
      AppSuccess<Treatment>(:final value)
          when value.status != TreatmentStatus.draft =>
        const AppFailure('INVALID_INITIAL_TREATMENT_STATE'),
      _ => result,
    };
  }
}

/// Regimen text exactly as the caregiver wrote it, before validation.
final class RegimenDraft {
  const RegimenDraft({
    required this.dose,
    required this.frequency,
    required this.scheduleText,
    required this.instructions,
    this.followUpDelayMinutes,
    this.reminderLeadMinutes = 0,
  });

  final String dose;
  final String frequency;

  /// Comma separated `HH:mm` times.
  final String scheduleText;
  final String instructions;

  /// Null selects the system default follow-up.
  final int? followUpDelayMinutes;
  final int reminderLeadMinutes;
}

/// Validates a complete regimen with the same values used by the wizard, then saves it.
final class ConfigureTreatment {
  const ConfigureTreatment(this._repository);
  final TreatmentLifecycleRepository _repository;

  Future<AppResult<Treatment>> call(
    String treatmentId,
    String medicationId,
    RegimenDraft draft,
  ) {
    final dose = Dosage.tryParse(draft.dose);
    final frequency = Frequency.tryParse(draft.frequency);
    final instructions = AdministrationInstructions.tryParse(
      draft.instructions,
    );
    final times = draft.scheduleText
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(ClockTime.tryParse)
        .toList();
    final schedule = times.contains(null)
        ? null
        : AdministrationSchedule.create(times.whereType<ClockTime>());
    final delay = draft.followUpDelayMinutes;
    final lead = draft.reminderLeadMinutes;
    if (_blank(treatmentId) ||
        _blank(medicationId) ||
        dose == null ||
        frequency == null ||
        instructions == null ||
        schedule == null ||
        lead < 0 ||
        lead > 1440 ||
        (delay != null && (delay < 0 || delay > 1440))) {
      return Future.value(const AppFailure('INVALID_TREATMENT_CONFIGURATION'));
    }
    return _repository.configure(
      treatmentId.trim(),
      medicationId.trim(),
      TreatmentRegimen(
        dose: dose,
        frequency: frequency,
        schedule: schedule,
        instructions: instructions,
        reminderLeadMinutes: lead,
        followUpDelay: delay == null
            ? null
            : ReminderDelayMinutes.tryParse('$delay'),
      ),
    );
  }
}

/// Lifecycle transition requested for a treatment.
enum TreatmentLifecycleAction { activate, pause, resume }

/// Validates the treatment reference and dispatches the requested transition.
final class ChangeTreatmentStatus {
  const ChangeTreatmentStatus(this._repository);
  final TreatmentLifecycleRepository _repository;

  Future<AppResult<Treatment>> call(
    String treatmentId,
    TreatmentLifecycleAction action,
  ) {
    if (_blank(treatmentId)) {
      return Future.value(const AppFailure('INVALID_TREATMENT_REFERENCE'));
    }
    final id = treatmentId.trim();
    return switch (action) {
      TreatmentLifecycleAction.activate => _repository.activate(id),
      TreatmentLifecycleAction.pause => _repository.pause(id),
      TreatmentLifecycleAction.resume => _repository.resume(id),
    };
  }
}

/// Reads the treatments of a linked adult.
final class ListTreatments {
  const ListTreatments(this._reader);
  final TreatmentReader _reader;

  Future<AppResult<List<TreatmentDetail>>> call(String olderAdultId) =>
      _blank(olderAdultId)
      ? Future.value(const AppFailure('INVALID_REFERENCE'))
      : _reader.list(olderAdultId.trim());
}

/// Reads one treatment and its configured regimen.
final class GetTreatmentDetail {
  const GetTreatmentDetail(this._reader);
  final TreatmentReader _reader;

  Future<AppResult<TreatmentDetail>> call(String treatmentId) =>
      _blank(treatmentId)
      ? Future.value(const AppFailure('INVALID_TREATMENT_REFERENCE'))
      : _reader.detail(treatmentId.trim());
}

/// Combines the adult catalog and the next intake while preserving failures.
final class GetMyMedicationsOverview {
  const GetMyMedicationsOverview(this._catalog, this._nextDose);
  final MyMedicationsReader _catalog;
  final Future<AppResult<MedicationNextDose?>> Function() _nextDose;

  Future<AppResult<MyMedicationsOverview>> call() async {
    final medications = await _catalog.list();
    if (medications is AppFailure<List<MyMedication>>) {
      return AppFailure(medications.code);
    }
    final dose = await _nextDose();
    return switch (dose) {
      AppFailure<MedicationNextDose?>(:final code) => AppFailure(code),
      AppSuccess<MedicationNextDose?>(:final value) => AppSuccess(
        MyMedicationsOverview(
          (medications as AppSuccess<List<MyMedication>>).value,
          value,
        ),
      ),
    };
  }
}
