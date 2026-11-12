import 'package:drift/drift.dart';

/// Durable confirmation intent. One entry per intake keeps delivery idempotent;
/// a [failureCode] marks a definitive rejection that is never sent again.
@DataClassName('PendingConfirmationRow')
class PendingConfirmations extends Table {
  TextColumn get ownerId => text()();
  TextColumn get careLinkId => text()();
  TextColumn get intakeId => text()();
  IntColumn get queuedAtMicros => integer()();
  TextColumn get failureCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, careLinkId, intakeId};
}
