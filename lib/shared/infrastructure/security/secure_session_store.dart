import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/session/session_owner.dart';
import '../../application/session/session_store.dart';
import '../../application/session/stored_session.dart';
import '../../application/time/clock.dart';

/// Single encrypted record and serialized mutations avoid partially written identities.
final class SecureSessionStore implements SessionStore {
  SecureSessionStore({required this._storage, required this._clock});

  static const _key = 'tata.session.v1';
  final FlutterSecureStorage _storage;
  final Clock _clock;
  Future<void> _tail = Future<void>.value();
  bool _initialized = false;
  StoredSession? _session;
  int _generation = 0;

  @override
  int get generation => _generation;

  @override
  StoredSession? get current =>
      _session?.isValidAt(_clock()) == true ? _session : null;

  @override
  Future<void> initialize() => _serial(() async {
    if (_initialized) return;
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      try {
        final value = jsonDecode(raw) as Map<String, dynamic>;
        final session = StoredSession(
          accessToken: value['token'] as String,
          expiresAt: DateTime.parse(value['expiresAt'] as String).toUtc(),
          owner: SessionOwner(
            value['ownerId'] as String,
            SessionRole.values.byName(value['role'] as String),
            careLinkId: value['careLinkId'] as String?,
          ),
        );
        if (!session.isValidAt(_clock())) throw const FormatException();
        _session = session;
      } on FormatException {
        await _storage.delete(key: _key);
        _session = null;
      } on TypeError {
        await _storage.delete(key: _key);
        _session = null;
      } on ArgumentError {
        await _storage.delete(key: _key);
        _session = null;
      }
    }
    _initialized = true;
  });

  @override
  Future<bool> replace(
    StoredSession? session, {
    required int expectedGeneration,
  }) => _serial(() async {
    if (!_initialized) throw StateError('Initialize the session store first');
    if (_generation != expectedGeneration) return false;
    if (session != null && !session.isValidAt(_clock())) {
      throw ArgumentError('Expired session cannot be persisted');
    }
    // Invalidate in-flight work before touching platform storage, even if it fails.
    _generation++;
    _session = null;
    if (session == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'token': session.accessToken,
          'expiresAt': session.expiresAt.toUtc().toIso8601String(),
          'ownerId': session.owner.id,
          'role': session.owner.role.name,
          'careLinkId': session.owner.careLinkId,
        }),
      );
    }
    _session = session;
    return true;
  });

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
