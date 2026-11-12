import 'dart:async';

import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/preferences_ports.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// The device copy is written first so a setting applies immediately; the backend stays the
/// source of truth and replaces the copy whenever it can be reached. Each field is
/// acknowledged independently, so a failure never discards unsent fields.
final class OfflineFirstUserPreferences implements UserPreferencesRepository {
  OfflineFirstUserPreferences({required this._remote, required this._local});

  final UserPreferencesRemote _remote;
  final AccessibilityLocalStore _local;
  Future<void> _tail = Future.value();

  @override
  Stream<AccessibilityPreferences> watch(String userId) => _local.watch(userId);

  /// Serializes operations: one never starts before the previous one finishes.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<AppResult<UserPreferences>> sync(String userId) =>
      _serialized(() async {
        if ((await _local.pending(userId)).isNotEmpty) {
          final pushed = await _push(userId);
          if (pushed is AppFailure<UserPreferences>) return pushed;
        }
        final fetched = await _remote.get(userId);
        if (fetched is AppSuccess<UserPreferences>) {
          await _local.save(userId, fetched.value.accessibility, const {});
        }
        return fetched;
      });

  @override
  Future<AppResult<PreferenceUpdate>> update(
    String userId,
    AccessibilityChange change,
  ) => _serialized(() async {
    final previous = await _local.current(userId);
    final previouslyPending = await _local.pending(userId);
    final updated = change.applyTo(previous);
    // Persist the intent before the network operation.
    await _local.save(userId, updated, {...previouslyPending, change.field});
    final result = await _remote.update(userId, change);
    switch (result) {
      case AppSuccess<UserPreferences>(:final value):
        final receipt = value.accessibility;
        // A receipt for one field cannot acknowledge older unsent fields.
        if (AccessibilityChange.merge(receipt, updated, {change.field}) !=
            receipt) {
          return const AppFailure('INVALID_RESPONSE');
        }
        final remaining = {...previouslyPending}..remove(change.field);
        final accepted = AccessibilityChange.merge(receipt, updated, remaining);
        await _local.save(userId, accepted, remaining);
        return AppSuccess(
          PreferenceUpdate(accepted, syncedWithServer: remaining.isEmpty),
        );
      case AppFailure<UserPreferences>(:final code):
        if (code == 'NETWORK_UNAVAILABLE') {
          return AppSuccess(PreferenceUpdate(updated, syncedWithServer: false));
        }
        if (code == 'REQUEST_VALIDATION_FAILED') {
          await _local.save(userId, previous, previouslyPending);
        }
        return AppFailure(code);
    }
  });

  /// Acknowledges each changed field independently; failed and unattempted fields stay
  /// pending.
  Future<AppResult<UserPreferences>> _push(String userId) async {
    final desired = await _local.current(userId);
    var remaining = await _local.pending(userId);
    AppSuccess<UserPreferences>? last;
    for (final field in AccessibilityField.values.where(remaining.contains)) {
      final result = await _remote.update(
        userId,
        AccessibilityChange.forField(field, desired),
      );
      switch (result) {
        case AppFailure<UserPreferences>():
          return result;
        case AppSuccess<UserPreferences>(:final value):
          final receipt = value.accessibility;
          if (AccessibilityChange.merge(receipt, desired, {field}) != receipt) {
            return const AppFailure('INVALID_RESPONSE');
          }
          remaining = {...remaining}..remove(field);
          await _local.save(
            userId,
            AccessibilityChange.merge(receipt, desired, remaining),
            remaining,
          );
          last = result;
      }
    }
    return last ?? const AppFailure('INVALID_RESPONSE');
  }
}
