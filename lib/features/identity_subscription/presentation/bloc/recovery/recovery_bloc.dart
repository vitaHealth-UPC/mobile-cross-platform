import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/complete_password_recovery.dart';
import '../../../application/usecases/request_password_recovery.dart';
import '../../../domain/value_objects/email_address.dart';
import 'recovery_event.dart';
import 'recovery_state.dart';

/// Coordinates anonymous recovery receipts and rejects overlapping submissions.
/// Codes and passwords remain in transient events, never in emitted state.
final class RecoveryBloc extends Bloc<RecoveryEvent, RecoveryState> {
  RecoveryBloc({required this._request, required this._complete})
    : super(const RecoveryState()) {
    on<RecoveryEvent>(_handle);
  }
  final RequestPasswordRecovery _request;
  final CompletePasswordRecovery _complete;

  Future<void> _handle(RecoveryEvent event, Emitter<RecoveryState> emit) async {
    if (state.busy || state.status == RecoveryStatus.completed) return;
    if (event is RecoveryRequested) {
      final previousEmail = state.email;
      final recipient = previousEmail ?? event.email;
      emit(
        RecoveryState(status: RecoveryStatus.requesting, email: previousEmail),
      );
      final result = await _request(recipient);
      if (emit.isDone) return;
      emit(
        result is AppSuccess<void>
            ? RecoveryState(
                status: RecoveryStatus.codeRequested,
                email: EmailAddress(recipient).value,
              )
            : RecoveryState(
                status: previousEmail == null
                    ? RecoveryStatus.editing
                    : RecoveryStatus.codeRequested,
                email: previousEmail,
                errorCode: (result as AppFailure<void>).code,
              ),
      );
    } else if (event is RecoveryCompleted) {
      final email = state.email;
      if (email == null) return;
      emit(RecoveryState(status: RecoveryStatus.completing, email: email));
      final result = await _complete(email, event.code, event.newPassword);
      if (emit.isDone) return;
      emit(
        RecoveryState(
          email: email,
          status: result is AppSuccess<void>
              ? RecoveryStatus.completed
              : RecoveryStatus.codeRequested,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
    }
  }
}
