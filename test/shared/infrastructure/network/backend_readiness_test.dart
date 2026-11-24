import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/infrastructure/network/api_response.dart';
import 'package:tata/shared/infrastructure/network/backend_readiness.dart';

void main() {
  final url = Uri.parse('https://example.onrender.com/');

  test(
    'concurrent startup and registration share safe readiness probes',
    () async {
      final calls = <String>[];
      final notices = <bool>[];
      final first = Completer<http.Response>();
      var probes = 0;
      final transport = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path == '/actuator/health') {
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(request.followRedirects, isFalse);
          if (++probes == 1) return first.future;
          return http.Response('{"status":"UP"}', 200);
        }
        return http.Response('{}', 201);
      });
      final gate = BackendReadiness(
        baseUrl: url,
        client: transport,
        retryDelay: Duration.zero,
        maxAttempts: 3,
        onPreparing: notices.add,
      );
      final api = ApiClient(baseUrl: url, client: transport, readiness: gate);
      addTearDown(api.close);
      final warmup = api.prepareBackend();
      final registration = api.request(
        'POST',
        'api/v1/accounts',
        body: {'name': 'Test'},
      );
      first.complete(http.Response('<html>Starting</html>', 503));
      await warmup;
      expect((await registration).status, 201);
      expect(calls, [
        'GET /actuator/health',
        'GET /actuator/health',
        'POST /api/v1/accounts',
      ]);
      expect(notices, [true, false]);
    },
  );

  test('fresh activity avoids checks; inactivity prepares again', () async {
    var now = DateTime.utc(2026);
    var probes = 0;
    final transport = MockClient((request) async {
      if (request.url.path == '/actuator/health') {
        probes++;
        return http.Response('{"status":"UP"}', 200);
      }
      return http.Response('{}', 200);
    });
    final gate = BackendReadiness(
      baseUrl: url,
      client: transport,
      clock: () => now,
    );
    final api = ApiClient(baseUrl: url, client: transport, readiness: gate);
    addTearDown(api.close);
    await api.prepareBackend();
    now = now.add(const Duration(minutes: 9));
    await api.request('GET', 'api/v1/sessions/current');
    now = now.add(const Duration(minutes: 9));
    await api.request('GET', 'api/v1/sessions/current');
    expect(probes, 1);
    now = now.add(const Duration(minutes: 11));
    await api.request('GET', 'api/v1/sessions/current');
    expect(probes, 2);
  });

  test(
    'unavailable backend does not submit a mutation; explicit retry works',
    () async {
      var ready = false;
      var writes = 0;
      final transport = MockClient((request) async {
        if (request.url.path == '/actuator/health') {
          return http.Response(
            ready ? '{"status":"UP"}' : '{"status":"DOWN"}',
            200,
          );
        }
        writes++;
        return http.Response('{}', 201);
      });
      final gate = BackendReadiness(
        baseUrl: url,
        client: transport,
        retryDelay: Duration.zero,
        maxAttempts: 3,
      );
      final api = ApiClient(baseUrl: url, client: transport, readiness: gate);
      addTearDown(api.close);
      await expectLater(
        api.request('POST', 'api/v1/accounts'),
        throwsA(isA<ApiTransportException>()),
      );
      expect(writes, 0);
      ready = true;
      expect((await api.request('POST', 'api/v1/accounts')).status, 201);
      expect(writes, 1);
    },
  );

  test('timed out write is never automatically replayed', () async {
    var writes = 0;
    final pending = Completer<http.Response>();
    final transport = MockClient((request) async {
      if (request.url.path == '/actuator/health') {
        return http.Response('{"status":"UP"}', 200);
      }
      writes++;
      return pending.future;
    });
    final gate = BackendReadiness(baseUrl: url, client: transport);
    final api = ApiClient(
      baseUrl: url,
      client: transport,
      readiness: gate,
      timeout: const Duration(milliseconds: 10),
    );
    addTearDown(api.close);
    await expectLater(
      api.request('POST', 'api/v1/accounts'),
      throwsA(isA<ApiTransportException>()),
    );
    expect(writes, 1);
    pending.complete(http.Response('{}', 201));
  });

  test('probe budget is bounded even if the host never responds', () async {
    final pending = Completer<http.Response>();
    final transport = MockClient((_) => pending.future);
    final gate = BackendReadiness(
      baseUrl: url,
      client: transport,
      budget: const Duration(milliseconds: 20),
      probeTimeout: const Duration(milliseconds: 100),
      retryDelay: Duration.zero,
      maxAttempts: 3,
    );
    addTearDown(transport.close);
    await expectLater(
      gate.ensureReady(),
      throwsA(isA<ApiTransportException>()),
    );
    pending.complete(http.Response('{"status":"UP"}', 200));
  });
}
