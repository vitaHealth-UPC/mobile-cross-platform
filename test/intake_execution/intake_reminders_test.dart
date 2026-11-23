import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/policies/intake_reminder_policy.dart';
import 'package:tata/features/intake_execution/application/ports/reminder_scheduler.dart';
import 'package:tata/features/intake_execution/application/readmodels/intake_reminder.dart';
import 'package:tata/features/intake_execution/application/services/intake_reminder_sync.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/local/dao/intake_dao.dart';
import 'package:tata/features/intake_execution/infrastructure/local/intake_database.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';

import '../support/memory_session_store.dart';

/// Records what the platform would schedule.
final class FakeScheduler implements ReminderScheduler {
  final batches = <List<IntakeReminder>>[];
  var prepared = 0;
  var cancelled = 0;
  final taps = StreamController<String>.broadcast();
  String? launch;

  List<IntakeReminder> get current => batches.isEmpty ? const [] : batches.last;

  @override
  Future<void> prepare() async => prepared++;

  @override
  Future<void> replaceAll(List<IntakeReminder> reminders) async =>
      batches.add(reminders);

  @override
  Future<void> cancelAll() async {
    cancelled++;
    batches.add(const []);
  }

  @override
  Stream<String> get opened => taps.stream;

  @override
  Future<String?> takeLaunchDose() async => launch;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime.utc(2026, 11, 18, 12);

  Intake dose(
    String id,
    Duration offset, {
    IntakeStatus status = IntakeStatus.pending,
  }) => Intake(
    id: id,
    olderAdultId: 'adult-A',
    medicationName: 'Losartán 50 mg',
    dose: '1 tableta',
    scheduledAt: now.add(offset),
    status: status,
    confirmedAt: status == IntakeStatus.pending ? null : now,
  );

  group('policy', () {
    test('a coming dose gets a reminder and a reinforced one 15 min later', () {
      final plan = IntakeReminderPolicy.plan([
        dose('d1', const Duration(hours: 1)),
      ], now);
      expect(plan.map((r) => (r.kind, r.at)), [
        (ReminderKind.due, now.add(const Duration(hours: 1))),
        (ReminderKind.reinforced, now.add(const Duration(minutes: 75))),
      ]);
      expect(plan.first.notificationId, isNot(plan.last.notificationId));
    });

    test('a dose already due keeps only its reinforced reminder', () {
      final plan = IntakeReminderPolicy.plan([
        dose('d1', const Duration(minutes: -5)),
        dose('d0', const Duration(minutes: -20)),
      ], now);
      expect(plan.single.kind, ReminderKind.reinforced);
      expect(plan.single.intakeId, 'd1');
    });

    test('confirmed, omitted or queued doses are not reminded (AC2)', () {
      final plan = IntakeReminderPolicy.plan([
        dose('a', const Duration(hours: 1), status: IntakeStatus.confirmed),
        dose('b', const Duration(hours: 1), status: IntakeStatus.omitted),
        dose(
          'c',
          const Duration(hours: 1),
        ).withLocalConfirmation(LocalConfirmation.queued),
      ], now);
      expect(plan, isEmpty);
    });

    test('only the coming 48 hours are scheduled, in order', () {
      final plan = IntakeReminderPolicy.plan([
        dose('late', const Duration(hours: 50)),
        dose('soon', const Duration(hours: 2)),
        dose('sooner', const Duration(hours: 1)),
      ], now);
      expect(plan.map((r) => r.intakeId), ['sooner', 'sooner', 'soon', 'soon']);
    });

    test('identifiers are stable for the same dose and kind', () {
      final a = IntakeReminder(
        intakeId: 'intake-1',
        kind: ReminderKind.due,
        at: now,
        medicationName: 'x',
        dose: 'y',
      );
      expect(a.notificationId, a.notificationId);
      expect(a.notificationId, inInclusiveRange(0, 0x7FFFFFFF));
    });
  });

  group('sync with the stored agenda', () {
    late IntakeDatabase database;
    late IntakeDao local;
    late MemorySessionStore sessions;
    late FakeScheduler scheduler;
    late IntakeReminderSync sync;
    final owner = SessionOwner(
      'adult-A',
      SessionRole.olderAdult,
      careLinkId: 'link-A',
    );

    setUp(() {
      database = IntakeDatabase(NativeDatabase.memory());
      local = IntakeDao(database);
      sessions = MemorySessionStore(
        StoredSession(
          accessToken: 'adult-token',
          expiresAt: DateTime.utc(2099),
          owner: owner,
        ),
      );
      scheduler = FakeScheduler();
      sync = IntakeReminderSync(
        local: local,
        sessions: sessions,
        scheduler: scheduler,
        clock: () => now,
      );
    });

    tearDown(() async {
      await sync.stop();
      await database.close();
    });

    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      await sync.refresh();
    }

    test('schedules the stored doses and follows new ones', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-A');
      expect(scheduler.prepared, 1);
      expect(scheduler.current.map((r) => r.intakeId), ['d1', 'd1']);

      await local.cacheIntake(owner, dose('d2', const Duration(minutes: 30)));
      await settle();
      expect(scheduler.current.map((r) => r.intakeId), [
        'd2',
        'd2',
        'd1',
        'd1',
      ]);
    });

    test('a confirmation queued offline removes its reminders', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-A');
      await local.enqueueConfirmation(owner, 'd1', now);
      await settle();
      expect(scheduler.current, isEmpty);
    });

    test('unchanged agenda does not reschedule', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-A');
      final before = scheduler.batches.length;
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await settle();
      expect(scheduler.batches.length, before);
    });

    test('withdrawn consent clears the data and the reminders', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-A');
      await local.clearAdult('adult-A');
      await settle();
      expect(scheduler.current, isEmpty);
    });

    test('stopping cancels everything scheduled', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-A');
      await sync.stop();
      expect(scheduler.cancelled, 1);
      expect(scheduler.current, isEmpty);
      await local.cacheIntake(owner, dose('d2', const Duration(hours: 2)));
      await settle();
      expect(scheduler.current, isEmpty);
    });

    test('another account or a caregiver session schedules nothing', () async {
      await local.cacheIntake(owner, dose('d1', const Duration(hours: 1)));
      await sync.start('adult-B');
      expect(scheduler.batches, isEmpty);

      sessions.value = StoredSession(
        accessToken: 'caregiver-token',
        expiresAt: DateTime.utc(2099),
        owner: SessionOwner('adult-A', SessionRole.caregiver),
      );
      await sync.start('adult-A');
      expect(scheduler.batches, isEmpty);
      expect(scheduler.prepared, 0);
    });
  });
}
