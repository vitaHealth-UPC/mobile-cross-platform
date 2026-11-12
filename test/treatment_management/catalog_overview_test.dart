import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/treatment_management/application/ports/treatment_readers.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
import 'package:tata/shared/common/result/app_result.dart';

final class _Catalog implements MyMedicationsReader {
  const _Catalog(this.result);
  final AppResult<List<MyMedication>> result;
  @override
  Future<AppResult<List<MyMedication>>> list() async => result;
}

void main() {
  test(
    'authorized catalog remains distinct from an unavailable next dose',
    () async {
      final usecase = GetMyMedicationsOverview(
        const _Catalog(AppSuccess([])),
        () async => const AppFailure('NETWORK_UNAVAILABLE'),
      );
      final result = await usecase() as AppSuccess<MyMedicationsOverview>;
      expect(result.value.scheduleError, 'NETWORK_UNAVAILABLE');
      expect(result.value.nextDose, isNull);
    },
  );
  test(
    'secondary access failures dominate a catalog transport failure',
    () async {
      for (final code in [
        'ACCESS_DENIED',
        'AUTHENTICATION_REQUIRED',
        'SESSION_CHANGED',
      ]) {
        final usecase = GetMyMedicationsOverview(
          const _Catalog(AppFailure('NETWORK_UNAVAILABLE')),
          () async => AppFailure(code),
        );
        expect((await usecase() as AppFailure).code, code);
      }
    },
  );
  test('successful empty next dose is not a schedule error', () async {
    final usecase = GetMyMedicationsOverview(
      const _Catalog(AppSuccess([])),
      () async => const AppSuccess(null),
    );
    final result = await usecase() as AppSuccess<MyMedicationsOverview>;
    expect(result.value.scheduleError, isNull);
    expect(result.value.nextDose, isNull);
  });
  test(
    'offline confirmation retains remote medication and treatment references',
    () {
      final intake = Intake(
        id: 'i',
        medicationId: 'med',
        treatmentId: 'tr',
        olderAdultId: 'adult',
        medicationName: 'Medication',
        dose: '1',
        scheduledAt: DateTime.utc(2026),
        status: IntakeStatus.pending,
      );
      final queued = intake.withLocalConfirmation(LocalConfirmation.queued);
      expect(queued.medicationId, 'med');
      expect(queued.treatmentId, 'tr');
      expect(queued.confirmable, isFalse);
    },
  );
}
