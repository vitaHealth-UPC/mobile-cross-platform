import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/infrastructure/security/secure_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 27);

  SecureSessionStore store() => SecureSessionStore(
    storage: const FlutterSecureStorage(),
    clock: () => now,
  );

  StoredSession session(String id) => StoredSession(
    accessToken: 'secret-$id',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner(id, SessionRole.caregiver),
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'restricted role and relationship scope survive secure-adapter recreation',
    () async {
      final first = store();
      await first.initialize();
      final owner = SessionOwner(
        'adult-A',
        SessionRole.linkSetup,
        careLinkId: 'link-A',
      );
      await first.replace(
        StoredSession(
          accessToken: 'restricted-secret',
          expiresAt: DateTime.utc(2030),
          owner: owner,
        ),
        expectedGeneration: 0,
      );
      final recreated = store();
      await recreated.initialize();
      expect(recreated.current?.owner, owner);
      expect(recreated.current?.owner.role, SessionRole.linkSetup);
      expect(
        owner,
        isNot(
          SessionOwner('adult-A', SessionRole.linkSetup, careLinkId: 'link-B'),
        ),
      );
      expect(
        () => SessionOwner('adult-A', SessionRole.olderAdult),
        throwsArgumentError,
      );
    },
  );

  test(
    'a fresh adapter restores one coherent credential and identity',
    () async {
      final first = store();
      await first.initialize();
      expect(await first.replace(session('A'), expectedGeneration: 0), isTrue);
      final recreated = store();
      await recreated.initialize();
      expect(recreated.current?.owner.id, 'A');
      expect(recreated.current?.accessToken, 'secret-A');
      expect(recreated.current.toString(), isNot(contains('secret-A')));
    },
  );

  test('serialized writes reject stale generation and clearing survives recreation', () async {
    final first = store();
    await first.initialize();
    final accepted = first.replace(session('A'), expectedGeneration: 0);
    final stale = first.replace(session('B'), expectedGeneration: 0);
    expect(await accepted, isTrue);
    expect(await stale, isFalse);
    expect(first.current?.owner.id, 'A');
    await first.replace(null, expectedGeneration: first.generation);
    final recreated = store();
    await recreated.initialize();
    expect(recreated.current, isNull);
  });

  test('corrupt or exactly expired persisted credentials are erased', () async {
    for (final raw in [
      '{broken',
      jsonEncode({
        'token': 'secret',
        'expiresAt': now.toIso8601String(),
        'ownerId': 'A',
        'role': 'caregiver',
      }),
      jsonEncode({
        'token': 'secret',
        'expiresAt': '2030-01-01T00:00:00Z',
        'ownerId': 'A',
        'role': 'unknown',
      }),
    ]) {
      FlutterSecureStorage.setMockInitialValues({'tata.session.v1': raw});
      final value = store();
      await value.initialize();
      expect(value.current, isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'tata.session.v1'),
        isNull,
      );
    }
  });

  test(
    'expiration during an active process no longer exposes credentials',
    () async {
      var current = now;
      final value = SecureSessionStore(
        storage: const FlutterSecureStorage(),
        clock: () => current,
      );
      await value.initialize();
      await value.replace(session('A'), expectedGeneration: 0);
      current = DateTime.utc(2030);
      expect(value.current, isNull);
    },
  );
}
