import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../application/ports/preferences_ports.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// Emits [read] on listen and again whenever [changes] announces [ownerId].
/// The subscription is created before the first read, so no change is missed.
Stream<T> _watchOwner<T>(
  Stream<String> changes,
  String ownerId,
  Future<T> Function() read,
) {
  late final StreamController<T> controller;
  StreamSubscription<String>? subscription;
  controller = StreamController<T>(
    onListen: () {
      subscription = changes.where((id) => id == ownerId).listen((_) async {
        controller.add(await read());
      });
      read().then(controller.add, onError: controller.addError);
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}

/// Stores one partition of the accessibility values per session owner. Legacy values that
/// are not bound to an owner are never claimed by any account.
final class SharedPreferencesAccessibilityStore
    implements AccessibilityLocalStore {
  SharedPreferencesAccessibilityStore({
    Future<SharedPreferences> Function()? open,
  }) : _open = open ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _open;
  final _changes = StreamController<String>.broadcast();

  String _key(String ownerId, String name) => 'tata.a11y.$ownerId.$name';

  @override
  Stream<AccessibilityPreferences> watch(String ownerId) =>
      _watchOwner(_changes.stream, ownerId, () => current(ownerId));

  @override
  Future<AccessibilityPreferences> current(String ownerId) async {
    final store = await _open();
    const defaults = AccessibilityPreferences.defaults;
    return AccessibilityPreferences(
      textSize:
          TextSizeLevel.fromWire(store.getString(_key(ownerId, 'textSize'))) ??
          defaults.textSize,
      highContrast:
          store.getBool(_key(ownerId, 'highContrast')) ?? defaults.highContrast,
      reducedMotion:
          store.getBool(_key(ownerId, 'reducedMotion')) ??
          defaults.reducedMotion,
      readingAssistance:
          store.getBool(_key(ownerId, 'readingAssistance')) ??
          defaults.readingAssistance,
      voiceConfirmation:
          store.getBool(_key(ownerId, 'voiceConfirmation')) ??
          defaults.voiceConfirmation,
      darkTheme:
          store.getBool(_key(ownerId, 'darkTheme')) ?? defaults.darkTheme,
    );
  }

  @override
  Future<void> save(
    String ownerId,
    AccessibilityPreferences preferences,
    Set<AccessibilityField> pending,
  ) async {
    final store = await _open();
    final writes = <Future<bool>>[
      store.setString(_key(ownerId, 'textSize'), preferences.textSize.wire),
      store.setBool(_key(ownerId, 'highContrast'), preferences.highContrast),
      store.setBool(_key(ownerId, 'reducedMotion'), preferences.reducedMotion),
      store.setBool(
        _key(ownerId, 'readingAssistance'),
        preferences.readingAssistance,
      ),
      store.setBool(
        _key(ownerId, 'voiceConfirmation'),
        preferences.voiceConfirmation,
      ),
      store.setBool(_key(ownerId, 'darkTheme'), preferences.darkTheme),
      store.setStringList(_key(ownerId, 'pending'), [
        for (final field in pending) field.name,
      ]),
    ];
    if (!(await Future.wait(writes)).every((written) => written)) {
      throw StateError('LOCAL_WRITE_FAILED');
    }
    _changes.add(ownerId);
  }

  @override
  Future<Set<AccessibilityField>> pending(String ownerId) async {
    final store = await _open();
    final names = store.getStringList(_key(ownerId, 'pending')) ?? const [];
    return {
      for (final field in AccessibilityField.values)
        if (names.contains(field.name)) field,
    };
  }
}

/// A language preference per verified account; no clinical values or tokens are persisted.
final class SharedPreferencesLanguageStore implements ApplicationLanguageStore {
  SharedPreferencesLanguageStore({Future<SharedPreferences> Function()? open})
    : _open = open ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _open;
  final _changes = StreamController<String>.broadcast();

  String _key(String ownerId) => 'tata.language.$ownerId';

  Future<AppLanguage> _read(String ownerId) async =>
      AppLanguage.fromTag((await _open()).getString(_key(ownerId)));

  @override
  Stream<AppLanguage> watch(String ownerId) =>
      _watchOwner(_changes.stream, ownerId, () => _read(ownerId));

  @override
  Future<void> write(String ownerId, AppLanguage language) async {
    final written = await (await _open()).setString(
      _key(ownerId),
      language.tag,
    );
    if (!written) throw StateError('LOCAL_WRITE_FAILED');
    _changes.add(ownerId);
  }
}
