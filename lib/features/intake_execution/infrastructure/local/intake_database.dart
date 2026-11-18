import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/intake.dart';
import 'tables/cached_intakes.dart';
import 'tables/pending_confirmations.dart';

part 'intake_database.g.dart';

/// Local intake evidence and unsent confirmations. Credentials never enter it.
@DriftDatabase(tables: [CachedIntakes, PendingConfirmations])
final class IntakeDatabase extends _$IntakeDatabase {
  IntakeDatabase(super.executor);

  /// Opens the application-private database file of this device.
  factory IntakeDatabase.onDevice() =>
      IntakeDatabase(driftDatabase(name: 'tata_intakes'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2: cached intakes keep the medication and treatment they belong to.
      if (from < 2) {
        await m.addColumn(cachedIntakes, cachedIntakes.medicationId);
        await m.addColumn(cachedIntakes, cachedIntakes.treatmentId);
      }
    },
  );
}
