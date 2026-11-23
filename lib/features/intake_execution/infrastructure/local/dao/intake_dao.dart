import 'package:drift/drift.dart';

import '../../../../../shared/application/session/session_owner.dart';
import '../../../application/ports/intake_local_store.dart';
import '../../../application/readmodels/pending_confirmation.dart';
import '../../../domain/entities/intake.dart';
import '../intake_database.dart';

/// Drift implementation of the owner-partitioned intake store.
final class IntakeDao implements IntakeLocalStore {
  const IntakeDao(this._db);

  /// Clinical history kept on the device beyond the requested interval.
  static const _retention = Duration(days: 30);

  final IntakeDatabase _db;

  @override
  Future<void> cacheIntake(SessionOwner owner, Intake intake) =>
      _db.into(_db.cachedIntakes).insertOnConflictUpdate(_row(owner, intake));

  @override
  Future<void> replaceAgenda(
    SessionOwner owner,
    DateTime from,
    DateTime to,
    List<Intake> intakes,
  ) => _db.transaction(() async {
    final start = _micros(from);
    final end = _micros(to);
    final cutoff = _micros(from.subtract(_retention));
    await (_db.delete(_db.cachedIntakes)..where(
          (row) =>
              _ownedIntake(row, owner) &
              (row.scheduledAtMicros.isSmallerThanValue(cutoff) |
                  (row.scheduledAtMicros.isBiggerOrEqualValue(start) &
                      row.scheduledAtMicros.isSmallerThanValue(end))),
        ))
        .go();
    await (_db.delete(_db.pendingConfirmations)..where(
          (row) =>
              _ownedPending(row, owner) &
              row.failureCode.isNotNull() &
              row.queuedAtMicros.isSmallerThanValue(cutoff),
        ))
        .go();
    await _db.batch(
      (batch) => batch.insertAllOnConflictUpdate(_db.cachedIntakes, [
        for (final intake in intakes) _row(owner, intake),
      ]),
    );
  });

  @override
  Future<void> clearUpcoming(SessionOwner owner, DateTime from) =>
      (_db.delete(_db.cachedIntakes)..where(
            (row) =>
                _ownedIntake(row, owner) &
                row.status.equalsValue(IntakeStatus.pending) &
                row.scheduledAtMicros.isBiggerOrEqualValue(_micros(from)),
          ))
          .go();

  @override
  Future<Intake?> findIntake(SessionOwner owner, String intakeId) async {
    final row =
        await (_db.select(_db.cachedIntakes)..where(
              (row) => _ownedIntake(row, owner) & row.intakeId.equals(intakeId),
            ))
            .getSingleOrNull();
    return row == null ? null : _intake(row);
  }

  @override
  Future<Intake?> findNext(
    SessionOwner owner,
    DateTime from, {
    Set<String> excluding = const {},
  }) async {
    final row =
        await (_db.select(_db.cachedIntakes)
              ..where(
                (row) =>
                    _ownedIntake(row, owner) &
                    row.status.equalsValue(IntakeStatus.pending) &
                    row.scheduledAtMicros.isBiggerOrEqualValue(_micros(from)) &
                    row.intakeId.isNotIn(excluding),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.scheduledAtMicros)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _intake(row);
  }

  @override
  Future<List<Intake>> findAgenda(
    SessionOwner owner,
    DateTime from,
    DateTime to,
  ) async {
    final rows =
        await (_db.select(_db.cachedIntakes)
              ..where(
                (row) =>
                    _ownedIntake(row, owner) &
                    row.scheduledAtMicros.isBiggerOrEqualValue(_micros(from)) &
                    row.scheduledAtMicros.isSmallerThanValue(_micros(to)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.scheduledAtMicros)]))
            .get();
    return rows.map(_intake).toList();
  }

  @override
  Future<void> enqueueConfirmation(
    SessionOwner owner,
    String intakeId,
    DateTime queuedAt,
  ) => _db
      .into(_db.pendingConfirmations)
      .insert(
        PendingConfirmationsCompanion.insert(
          ownerId: owner.id,
          careLinkId: owner.careLinkId!,
          intakeId: intakeId,
          queuedAtMicros: _micros(queuedAt),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  @override
  Future<List<PendingConfirmation>> pendingConfirmations(
    SessionOwner owner,
  ) async {
    final rows =
        await (_db.select(_db.pendingConfirmations)
              ..where(
                (row) => _ownedPending(row, owner) & row.failureCode.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.queuedAtMicros)]))
            .get();
    return [
      for (final row in rows)
        PendingConfirmation(
          intakeId: row.intakeId,
          queuedAt: _instant(row.queuedAtMicros),
        ),
    ];
  }

  @override
  Future<Map<String, LocalConfirmation>> localConfirmations(
    SessionOwner owner,
  ) async {
    final rows = await (_db.select(
      _db.pendingConfirmations,
    )..where((row) => _ownedPending(row, owner))).get();
    return {
      for (final row in rows)
        row.intakeId: row.failureCode == null
            ? LocalConfirmation.queued
            : LocalConfirmation.rejected,
    };
  }

  @override
  Future<void> acknowledgeConfirmation(SessionOwner owner, Intake intake) =>
      _db.transaction(() async {
        await cacheIntake(owner, intake);
        await (_db.delete(_db.pendingConfirmations)..where(
              (row) =>
                  _ownedPending(row, owner) & row.intakeId.equals(intake.id),
            ))
            .go();
      });

  @override
  Future<void> rejectConfirmation(
    SessionOwner owner,
    String intakeId,
    String code,
  ) =>
      (_db.update(_db.pendingConfirmations)..where(
            (row) => _ownedPending(row, owner) & row.intakeId.equals(intakeId),
          ))
          .write(PendingConfirmationsCompanion(failureCode: Value(code)));

  @override
  Future<void> clearAdult(String olderAdultId) => _db.transaction(() async {
    await (_db.delete(
      _db.cachedIntakes,
    )..where((row) => row.ownerId.equals(olderAdultId))).go();
    await (_db.delete(
      _db.pendingConfirmations,
    )..where((row) => row.ownerId.equals(olderAdultId))).go();
  });

  Expression<bool> _ownedIntake($CachedIntakesTable row, SessionOwner owner) =>
      row.ownerId.equals(owner.id) & row.careLinkId.equals(owner.careLinkId!);

  Expression<bool> _ownedPending(
    $PendingConfirmationsTable row,
    SessionOwner owner,
  ) => row.ownerId.equals(owner.id) & row.careLinkId.equals(owner.careLinkId!);

  CachedIntakesCompanion _row(SessionOwner owner, Intake intake) =>
      CachedIntakesCompanion.insert(
        ownerId: owner.id,
        careLinkId: owner.careLinkId!,
        intakeId: intake.id,
        medicationName: intake.medicationName,
        dose: intake.dose,
        instructions: Value(intake.instructions),
        scheduledAtMicros: _micros(intake.scheduledAt),
        status: intake.status,
        confirmedAtMicros: Value(switch (intake.confirmedAt) {
          final instant? => _micros(instant),
          null => null,
        }),
      );

  Intake _intake(CachedIntakeRow row) => Intake(
    id: row.intakeId,
    olderAdultId: row.ownerId,
    medicationName: row.medicationName,
    dose: row.dose,
    instructions: row.instructions,
    scheduledAt: _instant(row.scheduledAtMicros),
    status: row.status,
    confirmedAt: switch (row.confirmedAtMicros) {
      final micros? => _instant(micros),
      null => null,
    },
  );

  static int _micros(DateTime instant) =>
      instant.toUtc().microsecondsSinceEpoch;

  static DateTime _instant(int micros) =>
      DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
}
