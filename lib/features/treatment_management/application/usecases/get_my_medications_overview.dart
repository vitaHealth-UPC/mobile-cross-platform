import '../../../../shared/common/result/app_result.dart';
import '../ports/my_medications_reader.dart';
import '../readmodels/my_medications_overview.dart';

/// Combines the adult catalog and the next intake while preserving failures.
final class GetMyMedicationsOverview {
  const GetMyMedicationsOverview(this._catalog, this._nextDose);
  final MyMedicationsReader _catalog;
  final Future<AppResult<MedicationNextDose?>> Function() _nextDose;

  Future<AppResult<MyMedicationsOverview>> call() async {
    final catalogRequest = _catalog.list();
    final nextRequest = _nextDose();
    final medications = await catalogRequest;
    final dose = await nextRequest;
    if (dose case AppFailure(:final code)
        when const {
          'ACCESS_DENIED',
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
        }.contains(code)) {
      return AppFailure(code);
    }
    if (medications is AppFailure<List<MyMedication>>) {
      return AppFailure(medications.code);
    }

    return switch (dose) {
      AppFailure<MedicationNextDose?>(:final code)
          when const {
            'ACCESS_DENIED',
            'AUTHENTICATION_REQUIRED',
            'SESSION_CHANGED',
          }.contains(code) =>
        AppFailure(code),
      AppFailure<MedicationNextDose?>(:final code) => AppSuccess(
        MyMedicationsOverview(
          (medications as AppSuccess<List<MyMedication>>).value,
          null,
          scheduleError: code,
        ),
      ),
      AppSuccess<MedicationNextDose?>(:final value) => AppSuccess(
        MyMedicationsOverview(
          (medications as AppSuccess<List<MyMedication>>).value,
          value,
        ),
      ),
    };
  }
}
