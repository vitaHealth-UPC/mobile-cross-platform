import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_confirmation.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/readmodels/confirmation_receipt.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/replay_pending_confirmations.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/local/dao/intake_dao.dart';
import 'package:tata/features/intake_execution/infrastructure/local/intake_database.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/offline_intake_repository.dart';
import 'package:tata/features/intake_execution/infrastructure/sync/intake_sync_coordinator.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/memory_session_store.dart';

const offline = AppFailure<Never>('NETWORK_UNAVAILABLE');
final now = DateTime.utc(2026, 11, 10, 12);

Intake dose(
  String id, {
  String adult = 'adult-A',
  Duration offset = const Duration(hours: 1),
  IntakeStatus status = IntakeStatus.pending,
}) => Intake(
  id: id,
  olderAdultId: adult,
  medicationName: 'Losartán',
  dose: '1 tableta',
  instructions: 'Con agua',
  scheduledAt: now.add(offset),
  status: status,
  confirmedAt: status == IntakeStatus.confirmed || status == IntakeStatus.late
      ? now
      : null,
);

ConfirmationReceipt receipt(String id) => ConfirmationReceipt(
  intake: dose(id, status: IntakeStatus.confirmed),
  alreadyConfirmed: false,
);

StoredSession session(SessionOwner owner) => StoredSession(
  owner: owner,
  accessToken: 'token-${owner.id}',
  expiresAt: DateTime.utc(2030),
);

/// Server double with scripted answers per confirmed intake.
final class FakeServer implements IntakeReader, IntakeConfirmationReplay {
  AppResult<Intake?> nextResult = offline;
  AppResult<List<Intake>> agendaResult = offline;
  AppResult<Intake> detailResult = offline;
  AppResult<ConfirmationReceipt> Function(String id) onConfirm = (_) => offline;
  AppResult<ConfirmationReceipt> Function(String id)? onReplay;
  final sent = <String>[];
  final reportedTimes = <DateTime>[];
  int plainConfirms = 0;
  void Function()? duringConfirm;

  @override
  Future<AppResult<Intake?>> next() async => nextResult;
  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      agendaResult;
  @override
  Future<AppResult<Intake>> detail(String intakeId) async => detailResult;
  @override
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId) async {
    sent.add(intakeId);
    plainConfirms++;
    duringConfirm?.call();
    return onConfirm(intakeId);
  }

  @override
  Future<AppResult<ConfirmationReceipt>> replay(
    String intakeId,
    DateTime confirmedAt,
  ) async {
    sent.add(intakeId);
    reportedTimes.add(confirmedAt);
    duringConfirm?.call();
    return (onReplay ?? onConfirm)(intakeId);
  }
}

void main() {
  // The restart test deliberately opens the same file twice.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final ownerA = SessionOwner(
    'adult-A',
    SessionRole.olderAdult,
    careLinkId: 'link-A',
  );
  final ownerB = SessionOwner(
    'adult-B',
    SessionRole.olderAdult,
    careLinkId: 'link-B',
  );

  late IntakeDatabase database;
  late IntakeDao local;
  late MemorySessionStore store;
  late FakeServer server;
  late OfflineIntakeRepository repository;
  late ReplayPendingConfirmations replay;

  OfflineIntakeRepository buildRepository() => OfflineIntakeRepository(
    remoteReader: server,
    remoteConfirmation: server,
    local: local,
    store: store,
    clock: () => now,
  );

  void signIn(SessionOwner owner) {
    store.generation++;
    store.value = session(owner);
  }

  setUp(() {
    database = IntakeDatabase(NativeDatabase.memory());
    local = IntakeDao(database);
    store = MemorySessionStore(session(ownerA));
    server = FakeServer();
    repository = buildRepository();
    replay = ReplayPendingConfirmations(
      server,
      local,
      (owner) => store.current?.owner == owner,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  group('confirming without connection', () {
    test('queues a dose already seen and reports no server receipt', () async {
      await local.cacheIntake(ownerA, dose('d1'));

      final result = await repository.confirm('d1');

      expect(result, isA<AppFailure<ConfirmationReceipt>>());
      expect((result as AppFailure).code, 'PENDING_SYNC');
      expect(await local.pendingConfirmations(ownerA), hasLength(1));
      expect(repository.status.queued, 1);
      expect(repository.status.offline, isTrue);
    });

    test('saves the moment of the tap, not when the request failed', () async {
      var time = now;
      repository = OfflineIntakeRepository(
        remoteReader: server,
        remoteConfirmation: server,
        local: local,
        store: store,
        clock: () => time,
      );
      addTearDown(repository.dispose);
      await local.cacheIntake(ownerA, dose('d1'));
      server.duringConfirm = () => time = now.add(const Duration(seconds: 30));

      await repository.confirm('d1');

      expect((await local.pendingConfirmations(ownerA)).single.queuedAt, now);
    });

    test('does not queue a dose this device never stored', () async {
      final result = await repository.confirm('unknown');

      expect((result as AppFailure).code, 'NETWORK_UNAVAILABLE');
      expect(await local.pendingConfirmations(ownerA), isEmpty);
    });

    test('a server rejection is never queued', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      server.onConfirm = (_) => const AppFailure('INTAKE_NOT_CONFIRMABLE');

      final result = await repository.confirm('d1');

      expect((result as AppFailure).code, 'INTAKE_NOT_CONFIRMABLE');
      expect(await local.pendingConfirmations(ownerA), isEmpty);
    });

    test('a second attempt keeps one entry and the first time', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await local.enqueueConfirmation(ownerA, 'd1', now);
      await local.enqueueConfirmation(
        ownerA,
        'd1',
        now.add(const Duration(hours: 2)),
      );

      final pending = await local.pendingConfirmations(ownerA);
      expect(pending.single.queuedAt, now);
    });

    test('a receipt online is stored as the evidence', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      server.onConfirm = (id) => AppSuccess(receipt(id));

      await repository.confirm('d1');

      expect((await local.findIntake(ownerA, 'd1'))!.taken, isTrue);
      expect(await local.pendingConfirmations(ownerA), isEmpty);
    });
  });

  group('reading without connection', () {
    test('uses stored data and marks that it may be stale', () async {
      await local.cacheIntake(ownerA, dose('d1'));

      final next = await repository.next();

      expect((next as AppSuccess<Intake?>).value!.id, 'd1');
      expect(repository.status.offline, isTrue);
    });

    test('nothing stored is unknown, not an empty schedule', () async {
      expect((await repository.next()) as AppFailure, isA<AppFailure>());
      final agenda = await repository.agenda(
        now,
        now.add(const Duration(days: 1)),
      );
      expect((agenda as AppFailure).code, 'NETWORK_UNAVAILABLE');
    });

    test('a queued dose is not offered as the next one', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await local.cacheIntake(
        ownerA,
        dose('d2', offset: const Duration(hours: 5)),
      );
      await repository.confirm('d1');

      final next = await repository.next();

      expect((next as AppSuccess<Intake?>).value!.id, 'd2');
    });

    test('the last queued dose leaves a legitimate empty next', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await repository.confirm('d1');

      final next = await repository.next();

      expect((next as AppSuccess<Intake?>).value, isNull);
    });

    test('a queued dose cannot be confirmed again from detail', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await repository.confirm('d1');

      final detail = await repository.detail('d1');
      final intake = (detail as AppSuccess<Intake>).value;

      expect(intake.queued, isTrue);
      expect(intake.confirmable, isFalse);
      expect(intake.taken, isFalse);
    });

    test('a server answer replaces the queued mark', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await repository.confirm('d1');
      server.detailResult = AppSuccess(dose('d1', status: IntakeStatus.late));

      final detail = await repository.detail('d1');

      expect((detail as AppSuccess<Intake>).value.queued, isFalse);
    });

    test(
      'the server still next while queued moves to the stored one',
      () async {
        await local.cacheIntake(
          ownerA,
          dose('d2', offset: const Duration(hours: 5)),
        );
        await local.cacheIntake(ownerA, dose('d1'));
        await local.enqueueConfirmation(ownerA, 'd1', now);
        server.nextResult = AppSuccess(dose('d1'));

        final next = await repository.next();

        expect((next as AppSuccess<Intake?>).value!.id, 'd2');
      },
    );

    test('daily progress counts a dose confirmed offline', () async {
      final today = DateTime(2026, 11, 10, 8).toUtc();
      final from = DateTime(2026, 11, 10).toUtc();
      final to = DateTime(2026, 11, 11).toUtc();
      final base = Intake(
        id: 'd1',
        olderAdultId: 'adult-A',
        medicationName: 'Losartán',
        dose: '1 tableta',
        scheduledAt: today,
        status: IntakeStatus.pending,
      );
      await local.replaceAgenda(ownerA, from, to, [base]);
      await repository.confirm('d1');

      final progress = await GetDailyProgress(
        repository,
        () => DateTime(2026, 11, 10, 9),
      )();

      expect((progress as AppSuccess).value.taken, 1);
    });

    test('a 204 from the server clears stored upcoming doses', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      server.nextResult = const AppSuccess(null);

      await repository.next();

      expect(await local.findIntake(ownerA, 'd1'), isNull);
    });

    test('a fresh agenda drops doses the server no longer lists', () async {
      await local.cacheIntake(ownerA, dose('removed'));
      final from = now;
      final to = now.add(const Duration(days: 1));
      server.agendaResult = AppSuccess([
        dose('kept', offset: const Duration(hours: 3)),
      ]);

      await repository.agenda(from, to);

      expect(await local.findIntake(ownerA, 'removed'), isNull);
      expect(await local.findIntake(ownerA, 'kept'), isNotNull);
    });

    test('stored instants keep server precision in UTC', () async {
      final precise = DateTime.utc(2026, 11, 10, 13, 0, 0, 0, 123);
      await local.cacheIntake(
        ownerA,
        Intake(
          id: 'd1',
          olderAdultId: 'adult-A',
          medicationName: 'Losartán',
          dose: '1',
          scheduledAt: precise,
          status: IntakeStatus.pending,
        ),
      );

      final stored = await local.findIntake(ownerA, 'd1');

      expect(stored!.scheduledAt, precise);
      expect(stored.scheduledAt.isUtc, isTrue);
    });
  });

  group('replay', () {
    setUp(() async {
      await local.cacheIntake(ownerA, dose('d1'));
      await local.cacheIntake(ownerA, dose('d2'));
      await local.enqueueConfirmation(ownerA, 'd1', now);
      await local.enqueueConfirmation(
        ownerA,
        'd2',
        now.add(const Duration(minutes: 1)),
      );
    });

    test('delivers oldest first and clears the queue atomically', () async {
      server.onConfirm = (id) => AppSuccess(receipt(id));

      final result = await replay(ownerA);

      expect(result.outcome, ReplayOutcome.complete);
      expect(result.resolved, 2);
      expect(server.sent, ['d1', 'd2']);
      expect(await local.pendingConfirmations(ownerA), isEmpty);
      expect((await local.findIntake(ownerA, 'd1'))!.taken, isTrue);
    });

    test('reports the original tap time, never the arrival time', () async {
      server.onConfirm = (id) => AppSuccess(receipt(id));

      await replay(ownerA);

      expect(server.reportedTimes, [now, now.add(const Duration(minutes: 1))]);
      expect(server.plainConfirms, 0);
    });

    test('a rejected device time falls back to server time', () async {
      server.onReplay = (_) => const AppFailure('INVALID_CONFIRMATION_TIME');
      server.onConfirm = (id) => AppSuccess(receipt(id));

      final result = await replay(ownerA);

      expect(result.outcome, ReplayOutcome.complete);
      expect(result.resolved, 2);
      expect(server.plainConfirms, 2);
      expect(await local.pendingConfirmations(ownerA), isEmpty);
    });

    test('a transient failure keeps the remaining queue intact', () async {
      server.onConfirm = (id) => id == 'd1' ? AppSuccess(receipt(id)) : offline;

      final result = await replay(ownerA);

      expect(result.outcome, ReplayOutcome.retry);
      expect(result.resolved, 1);
      final left = await local.pendingConfirmations(ownerA);
      expect(left.single.intakeId, 'd2');
    });

    test('an omitted dose is kept as rejected and not resent', () async {
      server.onConfirm = (id) => id == 'd1'
          ? const AppFailure('INTAKE_NOT_CONFIRMABLE')
          : AppSuccess(receipt(id));

      final first = await replay(ownerA);
      server.sent.clear();
      await replay(ownerA);

      expect(first.outcome, ReplayOutcome.complete);
      expect(server.sent, isEmpty);
      final marks = await local.localConfirmations(ownerA);
      expect(marks['d1'], LocalConfirmation.rejected);
      server.detailResult = AppSuccess(
        dose('d1', status: IntakeStatus.omitted),
      );
      final detail = await repository.detail('d1');
      expect(
        (detail as AppSuccess<Intake>).value.localConfirmation,
        LocalConfirmation.rejected,
      );
    });

    for (final code in const [
      'AUTHENTICATION_REQUIRED',
      'ACCESS_DENIED',
      'SESSION_CHANGED',
    ]) {
      test('$code stops without losing the queue', () async {
        server.onConfirm = (_) => AppFailure(code);

        final result = await replay(ownerA);

        expect(result.outcome, ReplayOutcome.stopped);
        expect(server.sent, ['d1']);
        expect(await local.pendingConfirmations(ownerA), hasLength(2));
      });
    }

    test('a session change mid-replay sends nothing more', () async {
      server.onConfirm = (id) => AppSuccess(receipt(id));
      server.duringConfirm = () => signIn(ownerB);

      final result = await replay(ownerA);

      expect(result.outcome, ReplayOutcome.stopped);
      expect(server.sent, ['d1']);
      expect(await local.pendingConfirmations(ownerA), hasLength(2));
    });
  });

  group('owner partition', () {
    test('another adult neither reads nor sends the queue', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await repository.confirm('d1');

      signIn(ownerB);

      expect(await local.findIntake(ownerB, 'd1'), isNull);
      expect(await local.pendingConfirmations(ownerB), isEmpty);
      final next = await repository.next();
      expect((next as AppFailure).code, 'NETWORK_UNAVAILABLE');
      server.onConfirm = (id) => AppSuccess(receipt(id));
      await replay(ownerB);
      expect(server.sent, ['d1']); // only the original attempt
      expect(await local.pendingConfirmations(ownerA), hasLength(1));
    });

    test('a new care link starts a separate partition', () async {
      final relinked = SessionOwner(
        'adult-A',
        SessionRole.olderAdult,
        careLinkId: 'link-new',
      );
      await local.cacheIntake(ownerA, dose('d1'));

      expect(await local.findIntake(relinked, 'd1'), isNull);
    });

    test('forgetting an adult deletes every partition of theirs', () async {
      await local.cacheIntake(ownerA, dose('d1'));
      await local.enqueueConfirmation(ownerA, 'd1', now);
      await local.cacheIntake(ownerB, dose('d9', adult: 'adult-B'));

      await local.clearAdult('adult-A');

      expect(await local.findIntake(ownerA, 'd1'), isNull);
      expect(await local.pendingConfirmations(ownerA), isEmpty);
      expect(await local.findIntake(ownerB, 'd9'), isNotNull);
    });

    test('a caregiver session bypasses the adult store', () async {
      signIn(SessionOwner('caregiver-1', SessionRole.caregiver));

      final next = await repository.next();

      expect((next as AppFailure).code, 'NETWORK_UNAVAILABLE');
    });
  });

  test('the queue survives closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp('tata_intakes');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/intakes.sqlite');

    final first = IntakeDatabase(NativeDatabase(file));
    await IntakeDao(first).cacheIntake(ownerA, dose('d1'));
    await IntakeDao(first).enqueueConfirmation(ownerA, 'd1', now);
    await first.close();

    final reopened = IntakeDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final pending = await IntakeDao(reopened).pendingConfirmations(ownerA);

    expect(pending.single.intakeId, 'd1');
    expect(pending.single.queuedAt, now);
  });

  group('coordinator', () {
    late IntakeSyncCoordinator coordinator;

    setUp(() {
      coordinator = IntakeSyncCoordinator(
        store: store,
        repository: repository,
        replay: replay,
        clock: () => now,
        retryDelay: const Duration(milliseconds: 10),
      );
    });

    tearDown(() => coordinator.dispose());

    Future<void> queue() async {
      await local.cacheIntake(ownerA, dose('d1'));
      await repository.confirm('d1');
    }

    test('delivers, counts the answer and stores the coming week', () async {
      await queue();
      server.onConfirm = (id) => AppSuccess(receipt(id));
      server.agendaResult = AppSuccess([
        dose('tomorrow', offset: const Duration(days: 1)),
      ]);

      await coordinator.request();

      expect(coordinator.status.queued, 0);
      expect(coordinator.status.resolved, 1);
      expect(await local.findIntake(ownerA, 'tomorrow'), isNotNull);
    });

    test('retries by itself once the connection returns', () async {
      await queue();

      await coordinator.request();
      expect(coordinator.status.queued, 1);

      server.onConfirm = (id) => AppSuccess(receipt(id));
      await pumpUntil(() => coordinator.status.queued == 0);

      expect(coordinator.status.resolved, 1);
    });

    test(
      'a queued confirmation schedules delivery without a request',
      () async {
        await local.cacheIntake(ownerA, dose('d1'));
        await repository.confirm('d1');
        server.onConfirm = (id) => AppSuccess(receipt(id));

        await pumpUntil(() => coordinator.status.queued == 0);

        expect(server.sent.toSet(), {'d1'});
      },
    );

    test('suspending stops retries until the next request', () async {
      await queue();
      await coordinator.request();
      coordinator.suspend();
      server.sent.clear();
      server.onConfirm = (id) => AppSuccess(receipt(id));

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(server.sent, isEmpty);

      await coordinator.request();
      expect(coordinator.status.queued, 0);
    });

    test('concurrent requests never send the same queue twice', () async {
      await queue();
      server.sent.clear();
      server.onConfirm = (id) => AppSuccess(receipt(id));

      await Future.wait([coordinator.request(), coordinator.request()]);

      expect(server.sent, ['d1']);
    });

    test('lost access stops retrying', () async {
      await queue();
      server.sent.clear();
      server.onConfirm = (_) => const AppFailure('ACCESS_DENIED');

      await coordinator.request();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(server.sent, ['d1']);
      expect(coordinator.status.queued, 1);
    });
  });
}

Future<void> pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}
