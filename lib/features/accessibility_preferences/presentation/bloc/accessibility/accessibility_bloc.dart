import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/accessibility_change.dart';
import '../../../application/usecases/preferences_usecases.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../domain/value_objects/accessibility_preferences.dart';
import 'accessibility_event.dart';
import 'accessibility_state.dart';

/// Edits the accessibility and language of one user. Values are always applied on the
/// device first; the screen only reports whether the account copy is up to date.
final class AccessibilityBloc
    extends Bloc<AccessibilityEvent, AccessibilityState> {
  AccessibilityBloc({
    required this._observe,
    required this._observeLanguage,
    required this._update,
    required this._changeLanguage,
    required this._sync,
    required this.userId,
  }) : super(const AccessibilityState()) {
    on<AccessibilityStarted>(_start);
    on<AccessibilityChanged>(_change);
    on<LanguageToggled>(_toggleLanguage);
    on<AccessibilitySyncRequested>(_syncNow);
  }

  final ObserveAccessibility _observe;
  final ObserveApplicationLanguage _observeLanguage;
  final UpdateAccessibility _update;
  final ChangeApplicationLanguage _changeLanguage;
  final SyncUserPreferences _sync;
  final String userId;

  Future<void> _start(
    AccessibilityStarted event,
    Emitter<AccessibilityState> emit,
  ) async {
    add(const AccessibilitySyncRequested());
    await Future.wait([
      emit.forEach<AccessibilityPreferences>(
        _observe(userId),
        onData: (value) => state.copyWith(accessibility: value),
        onError: (_, _) => state.copyWith(errorCode: 'LOCAL_READ_FAILED'),
      ),
      emit.forEach<AppLanguage>(
        _observeLanguage(userId),
        onData: (value) => state.copyWith(language: value),
        onError: (_, _) => state.copyWith(errorCode: 'LOCAL_READ_FAILED'),
      ),
    ]);
  }

  Future<void> _syncNow(
    AccessibilitySyncRequested event,
    Emitter<AccessibilityState> emit,
  ) async {
    final result = await _sync(userId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<UserPreferences>() => state.copyWith(
        sync: AccessibilitySyncStatus.synced,
      ),
      AppFailure<UserPreferences>() => state.copyWith(
        sync: AccessibilitySyncStatus.pending,
      ),
    });
  }

  Future<void> _change(
    AccessibilityChanged event,
    Emitter<AccessibilityState> emit,
  ) async {
    final result = await _update(userId, event.change);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<PreferenceUpdate>(:final value) => state.copyWith(
        accessibility: value.accessibility,
        sync: value.syncedWithServer
            ? AccessibilitySyncStatus.synced
            : AccessibilitySyncStatus.pending,
      ),
      AppFailure<PreferenceUpdate>(:final code) => state.copyWith(
        errorCode: code,
      ),
    });
  }

  Future<void> _toggleLanguage(
    LanguageToggled event,
    Emitter<AccessibilityState> emit,
  ) async {
    final result = await _changeLanguage(userId, state.language.next);
    if (emit.isDone) return;
    if (result case AppFailure<AppLanguage>(:final code)) {
      emit(state.copyWith(errorCode: code));
    }
  }
}
