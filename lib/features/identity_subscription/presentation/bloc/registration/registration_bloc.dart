import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/register_caregiver.dart';
import '../../../application/usecases/request_verification.dart';
import '../../../application/usecases/verify_email.dart';
import '../../../domain/entities/account_session.dart';
import '../../../domain/value_objects/email_address.dart';
import 'registration_event.dart';
import 'registration_state.dart';

/// Sequences account creation, verification and resend through application use cases.
/// A pending account does not grant access, and concurrent submissions are ignored.
final class RegistrationBloc
    extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    required this._register,
    required this._verify,
    required this._resend,
  }) : super(const RegistrationState()) {
    on<RegistrationEvent>(_handle);
  }
  final RegisterCaregiver _register;
  final VerifyEmail _verify;
  final RequestVerification _resend;

  Future<void> _handle(
    RegistrationEvent event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state.busy || state.status == RegistrationStatus.verified) return;
    if (event is RegistrationSubmitted) {
      if (state.hasAccount) return;
      emit(const RegistrationState(status: RegistrationStatus.submitting));
      final result = await _register(event.name, event.email, event.password);
      if (emit.isDone) return;
      switch (result) {
        case AppSuccess<String>():
          emit(
            RegistrationState(
              status: RegistrationStatus.pending,
              accountId: result.value,
              email: EmailAddress(event.email).value,
            ),
          );
        case AppFailure<String>():
          emit(RegistrationState(errorCode: result.code));
      }
      return;
    }
    final accountId = state.accountId;
    final email = state.email;
    if (accountId == null || email == null) return;
    emit(
      RegistrationState(
        accountId: accountId,
        email: email,
        status: event is VerificationSubmitted
            ? RegistrationStatus.verifying
            : RegistrationStatus.resending,
      ),
    );
    if (event is VerificationSubmitted) {
      final result = await _verify(accountId, email, event.code);
      if (emit.isDone) return;
      emit(
        RegistrationState(
          accountId: accountId,
          email: email,
          status: result is AppSuccess<AccountSession>
              ? RegistrationStatus.verified
              : RegistrationStatus.pending,
          errorCode: result is AppFailure<AccountSession> ? result.code : null,
        ),
      );
    } else if (event is VerificationRequested) {
      final result = await _resend(accountId, email);
      if (emit.isDone) return;
      emit(
        RegistrationState(
          accountId: accountId,
          email: email,
          status: RegistrationStatus.pending,
          resent: result is AppSuccess<void>,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
    }
  }
}
