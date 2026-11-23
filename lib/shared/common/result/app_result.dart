/// Explicit success or failure returned across application boundaries.
sealed class AppResult<T> {
  const AppResult();
}

/// Acknowledged operation result; a null value can represent an empty receipt.
final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);
  final T value;
}

/// Stable code only: presentation chooses localized text, never provider output.
final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.code);
  final String code;

  @override
  String toString() => 'AppFailure($code)';
}
