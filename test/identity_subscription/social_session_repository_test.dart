import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/ports/social_credentials.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in_with_social.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/value_objects/social_provider.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_social_session_repository.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

final class _Credentials implements SocialCredentials {
  _Credentials(this.answer);
  final Future<AppResult<SocialIdentityToken?>> Function() answer;
  SocialProvider? requested;
  @override
  Future<AppResult<SocialIdentityToken?>> authenticate(
    SocialProvider provider,
  ) {
    requested = provider;
    return answer();
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 22);
  Map<String, Object?> receipt() => {
    'accountId': 'caregiver-A',
    'olderAdultId': null,
    'accessToken': 'tata-session',
    'expiresAt': '2030-01-01T00:00:00Z',
  };
  SignInWithSocial compose(
    MemorySessionStore store,
    SocialCredentials source,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return SignInWithSocial(
      RemoteSocialSessionRepository(
        credentials: source,
        api: SessionApi(client),
        store: store,
        clock: () => now,
      ),
    );
  }

  test(
    'stores only a validated Tata receipt after a provider exchange',
    () async {
      final store = MemorySessionStore();
      final source = _Credentials(
        () async => AppSuccess(SocialIdentityToken('firebase-evidence')),
      );
      final signIn = compose(store, source, (request) async {
        expect(request.url.path, '/api/v1/social-sessions');
        expect(request.method, 'POST');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(request.body), {
          'firebaseIdToken': 'firebase-evidence',
        });
        expect(store.current, isNull);
        return http.Response(jsonEncode(receipt()), 200);
      });
      expect(
        await signIn(SocialProvider.google),
        isA<AppSuccess<AccountSession?>>(),
      );
      expect(source.requested, SocialProvider.google);
      expect(store.current!.accessToken, 'tata-session');
      expect(store.current!.owner.id, 'caregiver-A');
      expect(
        SocialIdentityToken('private-token').toString(),
        isNot(contains('private-token')),
      );
    },
  );

  test('cancellation does not contact Tata or write a session', () async {
    final store = MemorySessionStore();
    final signIn = compose(
      store,
      _Credentials(() async => const AppSuccess(null)),
      (_) async => throw StateError('No HTTP expected'),
    );
    final result = await signIn(SocialProvider.facebook);
    expect((result as AppSuccess<AccountSession?>).value, isNull);
    expect(store.writes, 0);
  });

  test(
    'logout while the provider is open rejects its late credential',
    () async {
      final store = MemorySessionStore();
      final opened = Completer<void>();
      final evidence = Completer<AppResult<SocialIdentityToken?>>();
      final signIn = compose(
        store,
        _Credentials(() {
          opened.complete();
          return evidence.future;
        }),
        (_) async => throw StateError('No HTTP expected'),
      );
      final pending = signIn(SocialProvider.google);
      await opened.future;
      await store.replace(null, expectedGeneration: store.generation);
      evidence.complete(AppSuccess(SocialIdentityToken('late-evidence')));
      expect((await pending as AppFailure).code, 'SESSION_CHANGED');
      expect(store.current, isNull);
    },
  );

  test('logout during HTTP rejects the late Tata receipt', () async {
    final store = MemorySessionStore();
    final requested = Completer<void>();
    final response = Completer<http.Response>();
    final signIn = compose(
      store,
      _Credentials(() async => AppSuccess(SocialIdentityToken('evidence'))),
      (_) {
        requested.complete();
        return response.future;
      },
    );
    final pending = signIn(SocialProvider.facebook);
    await requested.future;
    await store.replace(null, expectedGeneration: store.generation);
    response.complete(http.Response(jsonEncode(receipt()), 200));
    expect((await pending as AppFailure).code, 'SESSION_CHANGED');
    expect(store.current, isNull);
  });

  for (final (status, code) in [
    (409, 'SOCIAL_LINK_REQUIRED'),
    (409, 'SOCIAL_LINK_CONFLICT'),
    (401, 'INVALID_SOCIAL_CREDENTIAL'),
    (422, 'SOCIAL_EMAIL_REQUIRED'),
    (503, 'SOCIAL_PROVIDER_UNAVAILABLE'),
  ]) {
    test('preserves documented $code without adopting a session', () async {
      final store = MemorySessionStore();
      final signIn = compose(
        store,
        _Credentials(() async => AppSuccess(SocialIdentityToken('evidence'))),
        (_) async => http.Response(
          jsonEncode({'title': code, 'detail': 'private diagnostic'}),
          status,
        ),
      );
      expect((await signIn(SocialProvider.google) as AppFailure).code, code);
      expect(store.writes, 0);
    });
  }

  test('a social response for the adult role is not adopted', () async {
    final store = MemorySessionStore();
    final body = receipt()
      ..['accountId'] = null
      ..['olderAdultId'] = 'adult-A'
      ..['careLinkId'] = 'link-A';
    final signIn = compose(
      store,
      _Credentials(() async => AppSuccess(SocialIdentityToken('evidence'))),
      (_) async => http.Response(jsonEncode(body), 200),
    );
    expect(
      (await signIn(SocialProvider.google) as AppFailure).code,
      'INVALID_RESPONSE',
    );
    expect(store.writes, 0);
  });
}
