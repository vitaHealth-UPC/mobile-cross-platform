import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../application/ports/omission_ports.dart';

/// Only identifiers and the display name the screens already show; no health data.
final class SharedPreferencesPushTargetStore implements PushTargetStore {
  SharedPreferencesPushTargetStore({Future<SharedPreferences> Function()? open})
    : _open = open ?? SharedPreferences.getInstance;

  static const _caregiver = 'tata.push.caregiver_of_';
  static const _olderAdult = 'tata.push.older_adult_';
  final Future<SharedPreferences> Function() _open;

  @override
  Future<void> rememberCaregiver(
    String olderAdultId,
    String caregiverId,
  ) async {
    final store = await _open();
    await store.setString('$_caregiver$olderAdultId', caregiverId);
  }

  @override
  Future<void> rememberOlderAdult(
    String olderAdultId,
    String olderAdultName,
  ) async {
    final store = await _open();
    await store.setString('$_olderAdult$olderAdultId', olderAdultName);
  }

  @override
  Future<String?> caregiverFor(String olderAdultId) async =>
      (await _open()).getString('$_caregiver$olderAdultId');

  @override
  Future<String?> olderAdultName(String olderAdultId) async =>
      (await _open()).getString('$_olderAdult$olderAdultId');
}

/// Persists only an opaque installation identity; the push SDK owns the push address.
final class SharedPreferencesPushInstallationStore {
  SharedPreferencesPushInstallationStore({
    Future<SharedPreferences> Function()? open,
    Random? random,
  }) : _open = open ?? SharedPreferences.getInstance,
       _random = random ?? Random.secure();

  static const _key = 'tata.push.installation';
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  final Future<SharedPreferences> Function() _open;
  final Random _random;
  Future<String>? _pending;

  /// The stored identity, or a new random UUID that is stored before it is returned.
  Future<String> getOrCreate() =>
      _pending ??= _load().whenComplete(() => _pending = null);

  Future<String> _load() async {
    final store = await _open();
    final stored = store.getString(_key);
    if (stored != null && _uuid.hasMatch(stored)) return stored;
    final created = _newUuid();
    await store.setString(_key, created);
    return created;
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
