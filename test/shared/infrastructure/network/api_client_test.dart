import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/infrastructure/network/api_response.dart';

void main() {
  test('structured care-link queries encode values without changing the origin or path', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient((request) async {
        expect(request.url.origin, 'https://example.com');
        expect(request.url.path, '/api/v1/care-links');
        expect(request.url.queryParameters, {
          'caregiverId': 'actor+A & name/?#',
        });
        expect(request.headers['Authorization'], 'Bearer token-A');
        expect(request.followRedirects, isFalse);
        return http.Response('[]', 200);
      }),
    );
    addTearDown(client.close);
    expect(
      (await client.request(
        'GET',
        'api/v1/care-links',
        token: 'token-A',
        queryParameters: {'caregiverId': 'actor+A & name/?#'},
      )).status,
      200,
    );
    await expectLater(
      client.request('GET', 'api/v1/care-links?caregiverId=raw'),
      throwsArgumentError,
    );
  });

  test('captured credentials stay on the intended origin and redirects are disabled', () async {
    final requests = <http.Request>[];
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient((r) async {
        requests.add(r);
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);
    await client.request('GET', 'api/v1/sessions/current', token: 'token-A');
    await client.request(
      'POST',
      'api/v1/sessions',
      body: {'password': ' a b '},
    );
    expect(requests[0].headers['Authorization'], 'Bearer token-A');
    expect(requests[0].followRedirects, isFalse);
    expect(requests[1].headers.containsKey('Authorization'), isFalse);
    expect(requests[1].body, contains(' a b '));
    expect(
      () => client.request('GET', 'https://foreign.test/api/v1/'),
      throwsArgumentError,
    );
  });

  test(
    'an HTML 401 retains authorization status; malformed success is invalid',
    () async {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient(
          (r) async => http.Response(
            '<html>proxy</html>',
            r.method == 'GET' ? 401 : 200,
          ),
        ),
      );
      addTearDown(client.close);
      expect(
        (await client.request('GET', 'api/v1/sessions/current')).status,
        401,
      );
      await expectLater(
        client.request('POST', 'api/v1/sessions'),
        throwsA(
          isA<ApiTransportException>().having(
            (e) => e.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
    },
  );

  test('timeouts do not produce a successful empty response', () async {
    final pending = Completer<http.Response>();
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient((_) => pending.future),
      timeout: const Duration(milliseconds: 5),
    );
    addTearDown(client.close);
    await expectLater(
      client.request('GET', 'api/v1/sessions/current'),
      throwsA(
        isA<ApiTransportException>().having(
          (e) => e.code,
          'code',
          'NETWORK_UNAVAILABLE',
        ),
      ),
    );
    pending.complete(http.Response('{}', 200));
  });

  test('oversized response is rejected at the boundary', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(
        (_) async => http.Response('x' * (1024 * 1024 + 1), 200),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      client.request('GET', 'api/v1/sessions/current'),
      throwsA(isA<ApiTransportException>()),
    );
  });
}
