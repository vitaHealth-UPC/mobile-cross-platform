import 'package:drift/drift.dart';

import '../../../domain/entities/intake.dart';

/// Last server representation of each intake, partitioned by adult and link.
/// Instants are UTC microseconds, the precision of server evidence.
@DataClassName('CachedIntakeRow')
class CachedIntakes extends Table {
  TextColumn get ownerId => text()();
  TextColumn get careLinkId => text()();
  TextColumn get intakeId => text()();
  TextColumn get medicationName => text()();
  TextColumn get dose => text()();
  TextColumn get instructions => text().nullable()();
  IntColumn get scheduledAtMicros => integer()();
  TextColumn get status => textEnum<IntakeStatus>()();
  IntColumn get confirmedAtMicros => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, careLinkId, intakeId};
}
