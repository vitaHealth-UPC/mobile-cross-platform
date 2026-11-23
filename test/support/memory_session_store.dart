import 'package:tata/shared/application/session/session_store.dart';
import 'package:tata/shared/application/session/stored_session.dart';

/// Explicit test double; production uses encrypted platform storage.
final class MemorySessionStore implements SessionStore {
  MemorySessionStore([this.value]);
  StoredSession? value;
  int writes = 0;
  @override
  int generation = 0;
  @override
  StoredSession? get current => value;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> replace(
    StoredSession? session, {
    required int expectedGeneration,
  }) async {
    if (generation != expectedGeneration) return false;
    generation++;
    writes++;
    value = session;
    return true;
  }
}
