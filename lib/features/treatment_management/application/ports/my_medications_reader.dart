import '../../../../shared/common/result/app_result.dart';
import '../readmodels/my_medications_overview.dart';

/// Catalog owned by the authenticated older adult; no client-supplied owner is accepted.
abstract interface class MyMedicationsReader {
  Future<AppResult<List<MyMedication>>> list();
}
