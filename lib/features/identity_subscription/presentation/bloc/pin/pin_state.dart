import '../../../domain/value_objects/pin_code.dart';

/// Whether the keypad enrolls a new PIN or authenticates with an existing one.
enum PinMode { setup, access }

/// Observable PIN phases; completed means the server acknowledged the PIN.
enum PinStatus { editing, busy, completed, alreadyRegistered }

/// Exposes how many digits are entered, never the digits themselves.
final class PinState {
  const PinState({
    this.length = 0,
    this.status = PinStatus.editing,
    this.errorCode,
  });

  final int length;
  final PinStatus status;
  final String? errorCode;

  /// The backend locks access for fifteen minutes after repeated failures.
  bool get locked => errorCode == 'PIN_LOCKED';

  bool get canEdit => status == PinStatus.editing && !locked;

  bool get canSubmit => canEdit && length == PinCode.length;
}
