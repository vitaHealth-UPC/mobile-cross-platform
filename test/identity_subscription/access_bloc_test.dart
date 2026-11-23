import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/repositories/session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_event.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_state.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';

void main() {
  final session = AccountSession(
    owner: SessionOwner('A', SessionRole.caregiver),
    expiresAt: DateTime.utc(2030),
  );
  AccessBloc create(TestSessionRepository repository) => AccessBloc(
    signIn: SignIn(repository),
    restore: RestoreSession(repository),
    signOut: SignOut(repository),
  );
  TypeMatcher<AccessState> status(AccessStatus value) =>
      isA<AccessState>().having((s) => s.status, 'status', value);

  blocTest<AccessBloc, AccessState>(
    'restored setup credentials require consent instead of authenticating clinical access',
    build: () => create(
      TestSessionRepository(
        () async => const AppFailure('UNUSED'),
        restored: AccountSession(
          owner: SessionOwner(
            'adult-A',
            SessionRole.linkSetup,
            careLinkId: 'link-A',
          ),
          expiresAt: DateTime.utc(2030),
        ),
      ),
    ),
    act: (bloc) => bloc.add(const AccessRestoreRequested()),
    expect: () => [
      status(AccessStatus.busy),
      status(AccessStatus.consentRequired),
    ],
  );

  blocTest<AccessBloc, AccessState>(
    'authentication is emitted only after an acknowledged session',
    build: () => create(TestSessionRepository(() async => AppSuccess(session))),
    act: (bloc) =>
        bloc.add(const AccessSignInSubmitted('a@example.com', 'password')),
    expect: () => [
      status(AccessStatus.busy),
      status(AccessStatus.authenticated),
    ],
  );

  blocTest<AccessBloc, AccessState>(
    'rejection remains a failure rather than restore-style silent access',
    build: () => create(
      TestSessionRepository(
        () async => const AppFailure('AUTHENTICATION_REQUIRED'),
      ),
    ),
    act: (bloc) =>
        bloc.add(const AccessSignInSubmitted('a@example.com', 'password')),
    expect: () => [
      status(AccessStatus.busy),
      status(AccessStatus.failure)
          .having((s) => s.errorCode, 'code', 'AUTHENTICATION_REQUIRED'),
    ],
  );

  test(
    'double submit makes one call and sign-out supersedes the pending result',
    () async {
      final pending = Completer<AppResult<AccountSession>>();
      final started = Completer<void>();
      final repository = TestSessionRepository(() {
        started.complete();
        return pending.future;
      });
      final bloc = create(repository);
      addTearDown(bloc.close);
      bloc.add(const AccessSignInSubmitted('a@example.com', 'password'));
      await started.future;
      bloc.add(const AccessSignInSubmitted('a@example.com', 'password'));
      final anonymous = bloc.stream.firstWhere(
        (state) => state.status == AccessStatus.anonymous,
      );
      bloc.add(const AccessSignOutRequested());
      await anonymous;
      pending.complete(AppSuccess(session));
      await Future<void>.delayed(Duration.zero);
      expect(repository.signIns, 1);
      expect(bloc.state.status, AccessStatus.anonymous);
      expect(bloc.state.session, isNull);
    },
  );

  test('credential events redact their diagnostics', () {
    const event = AccessSignInSubmitted(
      'private@example.com',
      'secret-password',
    );
    expect(event.toString(), isNot(contains('secret-password')));
    expect(event.toString(), isNot(contains('private@example.com')));
  });
}

final class TestSessionRepository implements SessionRepository {
  TestSessionRepository(this.login, {this.restored});
  final Future<AppResult<AccountSession>> Function() login;
  int signIns = 0;
  final AccountSession? restored;

  @override
  Future<AppResult<AccountSession>> signIn(String email, String password) {
    signIns++;
    return login();
  }

  @override
  Future<AppResult<AccountSession?>> restore() async => AppSuccess(restored);

  @override
  Future<AppResult<void>> signOut() async => const AppSuccess(null);
}
