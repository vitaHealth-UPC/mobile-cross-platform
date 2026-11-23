import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/local/dao/intake_dao.dart';
import 'package:tata/features/intake_execution/infrastructure/local/intake_database.dart';
import 'package:tata/shared/application/session/session_owner.dart';

/// Schema 1 exactly as the first release created it on devices.
const _schemaOne = [
  'CREATE TABLE "cached_intakes" ("owner_id" TEXT NOT NULL, '
      '"care_link_id" TEXT NOT NULL, "intake_id" TEXT NOT NULL, '
      '"medication_name" TEXT NOT NULL, "dose" TEXT NOT NULL, '
      '"instructions" TEXT NULL, "scheduled_at_micros" INTEGER NOT NULL, '
      '"status" TEXT NOT NULL, "confirmed_at_micros" INTEGER NULL, '
      'PRIMARY KEY ("owner_id", "care_link_id", "intake_id"))',
  'CREATE TABLE "pending_confirmations" ("owner_id" TEXT NOT NULL, '
      '"care_link_id" TEXT NOT NULL, "intake_id" TEXT NOT NULL, '
      '"queued_at_micros" INTEGER NOT NULL, "failure_code" TEXT NULL, '
      'PRIMARY KEY ("owner_id", "care_link_id", "intake_id"))',
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final owner = SessionOwner(
    'adult-A',
    SessionRole.olderAdult,
    careLinkId: 'link-A',
  );
  final scheduled = DateTime.utc(2026, 11, 17, 14);

  Intake dose(String id, {String? medicationId, String? treatmentId}) => Intake(
    id: id,
    medicationId: medicationId,
    treatmentId: treatmentId,
    olderAdultId: owner.id,
    medicationName: 'Losartán',
    dose: '1 tableta',
    scheduledAt: scheduled,
    status: IntakeStatus.pending,
  );

  /// Opens [file] as schema 1 with one cached dose and one queued confirmation.
  IntakeDatabase openFromSchemaOne(File file) => IntakeDatabase(
    NativeDatabase(
      file,
      setup: (raw) {
        if (raw.userVersion != 0) return;
        for (final statement in _schemaOne) {
          raw.execute(statement);
        }
        raw
          ..execute(
            'INSERT INTO cached_intakes VALUES '
            "('adult-A', 'link-A', 'd1', 'Losartán', '1 tableta', NULL, "
            "${scheduled.microsecondsSinceEpoch}, 'pending', NULL)",
          )
          ..execute(
            'INSERT INTO pending_confirmations VALUES '
            "('adult-A', 'link-A', 'd1', "
            '${scheduled.microsecondsSinceEpoch}, NULL)',
          )
          ..userVersion = 1;
      },
    ),
  );

  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tata_migration');
  });
  tearDown(() => directory.delete(recursive: true));

  test('upgrading from schema 1 keeps cached doses and the queue', () async {
    final database = openFromSchemaOne(File('${directory.path}/v1.sqlite'));
    addTearDown(database.close);
    final local = IntakeDao(database);

    final kept = await local.findIntake(owner, 'd1');
    expect(kept?.medicationName, 'Losartán');
    expect(kept?.medicationId, isNull);
    expect(kept?.treatmentId, isNull);
    expect((await local.pendingConfirmations(owner)).single.intakeId, 'd1');
    // The migrated file has the same shape as a fresh schema 2 install.
    await database.validateDatabaseSchema();
  });

  test('the next refresh fills the references of an old row', () async {
    final database = openFromSchemaOne(File('${directory.path}/v1.sqlite'));
    addTearDown(database.close);
    final local = IntakeDao(database);

    await local.replaceAgenda(
      owner,
      scheduled.subtract(const Duration(hours: 1)),
      scheduled.add(const Duration(days: 1)),
      [dose('d1', medicationId: 'med-1', treatmentId: 'tr-1')],
    );

    final next = await local.findNext(
      owner,
      scheduled.subtract(const Duration(hours: 1)),
    );
    expect(next?.medicationId, 'med-1');
    expect(next?.treatmentId, 'tr-1');
  });

  test('offline reads return the medication and treatment of a dose', () async {
    final database = IntakeDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = IntakeDao(database);

    await local.cacheIntake(
      owner,
      dose('d2', medicationId: 'med-2', treatmentId: 'tr-2'),
    );

    final cached = await local.findIntake(owner, 'd2');
    expect(cached?.medicationId, 'med-2');
    expect(cached?.treatmentId, 'tr-2');
    final agenda = await local.findAgenda(
      owner,
      scheduled,
      scheduled.add(const Duration(minutes: 1)),
    );
    expect(agenda.single.medicationId, 'med-2');
  });
}
