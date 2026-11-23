import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/register_pin.dart';
import '../../../application/usecases/sign_in_with_pin.dart';
import '../../../domain/value_objects/pin_code.dart';
import 'pin_event.dart';
import 'pin_state.dart';

/// Collects keypad digits privately and submits them through one use case.
/// Digits are cleared after every submission, whatever its outcome.
final class PinBloc extends Bloc<PinEvent, PinState> {
  /// Enrolls a PIN for the adult of the current full adult session.
  PinBloc.setup({required RegisterPin this._register})
    : mode = PinMode.setup,
      _signIn = null,
      _olderAdultId = null,
      super(const PinState()) {
    _listen();
  }

  /// Authenticates the remembered adult identified by `olderAdultId`.
  PinBloc.access({
    required SignInWithPin this._signIn,
    required String this._olderAdultId,
  }) : mode = PinMode.access,
       _register = null,
       super(const PinState()) {
    _listen();
  }

  final PinMode mode;
  final RegisterPin? _register;
  final SignInWithPin? _signIn;
  final String? _olderAdultId;
  String _digits = '';

  void _listen() {
    on<PinDigitPressed>(_digit);
    on<PinDeletePressed>(_delete);
    on<PinSubmitted>(_submit);
  }

  void _digit(PinDigitPressed event, Emitter<PinState> emit) {
    if (!state.canEdit || _digits.length == PinCode.length) return;
    if (!RegExp(r'^[0-9]$').hasMatch(event.digit)) return;
    _digits += event.digit;
    emit(PinState(length: _digits.length));
  }

  void _delete(PinDeletePressed event, Emitter<PinState> emit) {
    if (!state.canEdit || _digits.isEmpty) return;
    _digits = _digits.substring(0, _digits.length - 1);
    emit(PinState(length: _digits.length));
  }

  Future<void> _submit(PinSubmitted event, Emitter<PinState> emit) async {
    if (!state.canSubmit) return;
    final pin = _digits;
    _digits = '';
    emit(const PinState(status: PinStatus.busy));
    final AppResult<Object?> result = switch (mode) {
      PinMode.setup => await _register!(pin),
      PinMode.access => await _signIn!(_olderAdultId!, pin),
    };
    if (emit.isDone) return;
    final error = switch (result) {
      AppSuccess() => null,
      AppFailure(:final code) => code,
    };
    emit(
      error == null
          ? const PinState(status: PinStatus.completed)
          : PinState(
              status: mode == PinMode.setup && error == 'PIN_ALREADY_REGISTERED'
                  ? PinStatus.alreadyRegistered
                  : PinStatus.editing,
              errorCode: error,
            ),
    );
  }
}
