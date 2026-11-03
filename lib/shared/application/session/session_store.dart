import 'stored_session.dart';

/// Session persistence boundary with generation-based conditional replacement.
abstract interface class SessionStore {
  /// Mutation version captured before asynchronous work begins.
  int get generation;

  /// Current valid credential, or null when absent, expired or invalidated.
  StoredSession? get current;

  /// Loads platform storage before reads and conditional mutations.
  Future<void> initialize();

  /// Compare-and-replace prevents a late response from restoring an old actor.
  Future<bool> replace(
    StoredSession? session, {
    required int expectedGeneration,
  });
}
