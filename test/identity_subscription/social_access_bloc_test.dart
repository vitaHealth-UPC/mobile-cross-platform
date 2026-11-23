import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in_with_social.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/repositories/social_session_repository.dart';
import 'package:tata/features/identity_subscription/domain/value_objects/social_provider.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_event.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_state.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';

import 'access_bloc_test.dart' show TestSessionRepository;

final class _Social implements SocialSessionRepository {
  _Social(this.answer);
  final Future<AppResult<AccountSession?>> Function() answer;
  int calls = 0;
  @override
  Future<AppResult<AccountSession?>> signIn(SocialProvider provider) {
    calls++;
    return answer();
  }
}

void main() {
  final session = AccountSession(
    owner: SessionOwner('caregiver-A', SessionRole.caregiver),
    expiresAt: DateTime.utc(2030),
  );
  AccessBloc compose(_Social social) {
    final password = TestSessionRepository(
      () async => const AppFailure('UNUSED'),
    );
    final bloc = AccessBloc(
      signIn: SignIn(password),
      restore: RestoreSession(password),
      signOut: SignOut(password),
      signInWithSocial: SignInWithSocial(social),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  for (final provider in SocialProvider.values) {
    test(
      '$provider authenticates only from the acknowledged Tata session',
      () async {
        final bloc = compose(_Social(() async => AppSuccess(session)));
        final completed = bloc.stream.firstWhere(
          (state) => state.status == AccessStatus.authenticated,
        );
        bloc.add(AccessSocialSignInRequested(provider));
        await completed;
        expect(bloc.state.session!.owner.id, 'caregiver-A');
      },
    );
  }
  test('cancellation returns to anonymous access without an error', () async {
    final bloc = compose(_Social(() async => const AppSuccess(null)));
    final cancelled = bloc.stream.firstWhere(
      (state) => state.status == AccessStatus.anonymous,
    );
    bloc.add(const AccessSocialSignInRequested(SocialProvider.google));
    await cancelled;
    expect(bloc.state.errorCode, isNull);
    expect(bloc.state.session, isNull);
  });
  test('logout supersedes a pending social result and repeated taps', () async {
    final pending = Completer<AppResult<AccountSession?>>();
    final social = _Social(() => pending.future);
    final bloc = compose(social);
    final busy = bloc.stream.firstWhere(
      (state) => state.status == AccessStatus.busy,
    );
    bloc.add(const AccessSocialSignInRequested(SocialProvider.google));
    await busy;
    final anonymous = bloc.stream.firstWhere(
      (state) => state.status == AccessStatus.anonymous,
    );
    bloc.add(const AccessSocialSignInRequested(SocialProvider.facebook));
    bloc.add(const AccessSignOutRequested());
    await anonymous;
    pending.complete(AppSuccess(session));
    await Future<void>.delayed(Duration.zero);
    expect(social.calls, 1);
    expect(bloc.state.status, AccessStatus.anonymous);
    expect(bloc.state.session, isNull);
  });
}
