import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/ports/remembered_adult_store.dart';
import '../../application/readmodels/remembered_adult.dart';

/// Keeps the PIN shortcut in encrypted platform storage, separate from the session.
/// A corrupt record is deleted instead of granting a shortcut to an unknown adult.
final class SecureRememberedAdultStore implements RememberedAdultStore {
  const SecureRememberedAdultStore(this._storage);

  static const _key = 'tata.remembered-adult.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<RememberedAdult?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      return RememberedAdult(
        id: value['id'] as String,
        name: value['name'] as String?,
      );
    } on FormatException {
      await forget();
    } on TypeError {
      await forget();
    } on ArgumentError {
      await forget();
    }
    return null;
  }

  @override
  Future<void> remember(RememberedAdult adult) => _storage.write(
    key: _key,
    value: jsonEncode({'id': adult.id, 'name': adult.name}),
  );

  @override
  Future<void> forget() => _storage.delete(key: _key);
}
