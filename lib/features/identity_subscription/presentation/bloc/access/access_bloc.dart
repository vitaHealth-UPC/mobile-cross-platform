import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/application/session/session_owner.dart';
import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/restore_session.dart';
import '../../../application/usecases/sign_in.dart';
import '../../../application/usecases/sign_out.dart';
import '../../../domain/entities/account_session.dart';
import 'access_event.dart';
import 'access_state.dart';

/// One authority for access state. A sign-out supersedes any in-flight UI result.
final class AccessBloc extends Bloc<AccessEvent, AccessState> {
  AccessBloc({
    required this._signIn,
    required this._restore,
    required this._signOut,
  }) : super(const AccessState()) {
    on<AccessEvent>(_handle);
  }

  final SignIn _signIn;
  final RestoreSession _restore;
  final SignOut _signOut;
  int _revision = 0;

  Future<void> _handle(AccessEvent event, Emitter<AccessState> emit) async {
    if (state.status == AccessStatus.busy && event is! AccessSignOutRequested) {
      return;
    }
    final revision = ++_revision;
    emit(const AccessState(status: AccessStatus.busy));
    if (event is AccessSignOutRequested) {
      final result = await _signOut();
      if (revision != _revision || emit.isDone) return;
      emit(
        AccessState(
          status: AccessStatus.anonymous,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
      return;
    }
    final AppResult<AccountSession?> result = switch (event) {
      AccessSignInSubmitted() => await _signIn(event.email, event.password),
      AccessRestoreRequested() => await _restore(),
      AccessSignOutRequested() => throw StateError('Handled above'),
    };
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess<AccountSession?>():
        emit(
          AccessState(
            status: result.value == null
                ? AccessStatus.anonymous
                : result.value!.owner.role == SessionRole.linkSetup
                ? AccessStatus.consentRequired
                : AccessStatus.authenticated,
            session: result.value,
          ),
        );
      case AppFailure<AccountSession?>():
        emit(AccessState(status: AccessStatus.failure, errorCode: result.code));
    }
  }
}
