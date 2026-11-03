import '../readmodels/remembered_adult.dart';

/// Installation-scoped memory of the adult who enrolled a PIN on this device.
abstract interface class RememberedAdultStore {
  /// Returns the remembered adult, or null when none was enrolled or the record is invalid.
  Future<RememberedAdult?> read();

  /// Replaces the remembered adult after a confirmed PIN enrollment.
  Future<void> remember(RememberedAdult adult);

  /// Removes the shortcut, for example after the adult withdraws consent.
  Future<void> forget();
}
