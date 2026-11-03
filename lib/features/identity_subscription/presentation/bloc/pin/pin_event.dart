/// Keypad intent handled by the PIN state machine.
sealed class PinEvent {
  const PinEvent();
}

/// Appends one ASCII digit while fewer than four digits are entered.
final class PinDigitPressed extends PinEvent {
  const PinDigitPressed(this.digit);
  final String digit;

  @override
  String toString() => 'PinDigitPressed[REDACTED]';
}

/// Removes the last entered digit.
final class PinDeletePressed extends PinEvent {
  const PinDeletePressed();
}

/// Sends the four entered digits for enrollment or access.
final class PinSubmitted extends PinEvent {
  const PinSubmitted();
}
