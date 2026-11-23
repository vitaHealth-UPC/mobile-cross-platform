import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../test/support/memory_session_store.dart';

/// Opt-in real TCP/Spring probe. Fixture secrets never appear in output.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Supply the private local fixture path');
  }
  final file = File(arguments.single);
  final properties = <String, String>{};
  for (final line in await file.readAsLines()) {
    if (line.startsWith('#') || !line.contains('=')) continue;
    final separator = line.indexOf('=');
    properties[line.substring(0, separator)] = line
        .substring(separator + 1)
        .replaceAll(r'\:', ':')
        .replaceAll(r'\=', '=');
  }
  final url = Uri.parse(properties['baseUrl'] ?? '');
  if (url.scheme != 'http' || url.host != '127.0.0.1') {
    throw ArgumentError('Only an isolated loopback backend is accepted');
  }
  final email = properties['recoveryEmail'];
  if (email == null) {
    throw ArgumentError(
      'Start the local test host with recovery fixture enabled',
    );
  }
  final client = ApiClient(baseUrl: url, client: http.Client());
  final store = MemorySessionStore();
  final api = SessionApi(client);
  final repository = RemoteSessionRepository(
    api: api,
    store: store,
    clock: DateTime.now,
  );
  try {
    final invalid = await SignIn(repository)(email, 'incorrect-password');
    _check(
      invalid is AppFailure && store.current == null,
      'Rejected login created local access',
    );
    final signedIn = await SignIn(repository)(email, 'old-probe-password');
    _check(
      signedIn is AppSuccess &&
          store.current?.owner.id == properties['caregiverId'],
      'Login identity mismatch',
    );
    final token = store.current!.accessToken;
    _check(
      await repository.restore() is AppSuccess,
      'Current-session validation failed',
    );
    _check(
      await repository.signOut() is AppSuccess && store.current == null,
      'Logout failed',
    );
    _check(
      (await api.current(token)).status == 401,
      'Revoked session remains usable',
    );
    _check(
      await repository.restore() is AppSuccess && store.current == null,
      'Logout restored stale state',
    );
    stdout.writeln(
      'FLUTTER_LOCAL_SESSION_CONTRACT_PASS: rejected login, owner-bound session, current, logout and server revocation',
    );
  } finally {
    client.close();
    await File('${file.path}.done').writeAsString('finished');
  }
}

void _check(bool value, String message) {
  if (!value) throw StateError(message);
}
