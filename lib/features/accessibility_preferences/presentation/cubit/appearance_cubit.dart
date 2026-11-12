import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/usecases/preferences_usecases.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// What the whole application renders with: device-applied accessibility and language.
final class AppearanceState {
  const AppearanceState({
    this.accessibility = AccessibilityPreferences.defaults,
    this.language = AppLanguage.spanish,
  });

  final AccessibilityPreferences accessibility;
  final AppLanguage language;

  @override
  bool operator ==(Object other) =>
      other is AppearanceState &&
      accessibility == other.accessibility &&
      language == other.language;

  @override
  int get hashCode => Object.hash(accessibility, language);
}

/// Applies the preferences of the signed-in owner app-wide. Values come from the device copy,
/// so they apply before any network call finishes; reconciliation with the server runs in
/// the background and never blocks rendering. Without an owner the defaults apply.
final class AppearanceCubit extends Cubit<AppearanceState> {
  AppearanceCubit({
    required this._observeAccessibility,
    required this._observeLanguage,
    required this._sync,
  }) : super(const AppearanceState());

  final ObserveAccessibility _observeAccessibility;
  final ObserveApplicationLanguage _observeLanguage;
  final SyncUserPreferences _sync;
  StreamSubscription<AccessibilityPreferences>? _accessibilitySubscription;
  StreamSubscription<AppLanguage>? _languageSubscription;
  String? _ownerId;

  /// Follows [ownerId]; null (signed out) restores the defaults at once so one account's
  /// settings never leak into the next screen.
  void bindOwner(String? ownerId) {
    if (ownerId == _ownerId) return;
    _ownerId = ownerId;
    unawaited(_accessibilitySubscription?.cancel());
    unawaited(_languageSubscription?.cancel());
    _accessibilitySubscription = null;
    _languageSubscription = null;
    if (ownerId == null) {
      emit(const AppearanceState());
      return;
    }
    emit(const AppearanceState());
    _accessibilitySubscription = _observeAccessibility(ownerId).listen(
      (value) =>
          emit(AppearanceState(accessibility: value, language: state.language)),
      onError: (Object _) {},
    );
    _languageSubscription = _observeLanguage(ownerId).listen(
      (value) => emit(
        AppearanceState(accessibility: state.accessibility, language: value),
      ),
      onError: (Object _) {},
    );
    // Best effort: an offline device keeps its local copy and syncs next time.
    unawaited(_sync(ownerId));
  }

  @override
  Future<void> close() async {
    await _accessibilitySubscription?.cancel();
    await _languageSubscription?.cancel();
    return super.close();
  }
}
