import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/repositories/session_repository.dart';
import 'package:tata/shared/common/result/app_result.dart';

class _Repository implements SessionRepository {
  final events = <String>[];
  @override
  Future<AppResult<void>> signOut() async {
    events.add('session-revoked');
    return const AppSuccess(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'device cleanup finishes before the session credential is revoked',
    () async {
      final repository = _Repository();
      final cleanup = Completer<void>();
      final operation = SignOut(
        repository,
        beforeSignOut: () async {
          repository.events.add('device-removal');
          await cleanup.future;
        },
      )();
      await Future<void>.delayed(Duration.zero);
      expect(repository.events, ['device-removal']);
      cleanup.complete();
      expect(await operation, isA<AppSuccess<void>>());
      expect(repository.events, ['device-removal', 'session-revoked']);
    },
  );

  test('failed device transport never traps account sign-out', () async {
    final repository = _Repository();
    final result = await SignOut(
      repository,
      beforeSignOut: () async => throw Exception('device unavailable'),
    )();
    expect(result, isA<AppSuccess<void>>());
    expect(repository.events, ['session-revoked']);
  });
}
