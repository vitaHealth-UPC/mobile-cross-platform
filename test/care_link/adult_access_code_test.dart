import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/readmodels/adult_access_redemption.dart';
import 'package:tata/features/care_link/application/usecases/accept_care_link.dart';
import 'package:tata/features/care_link/application/usecases/end_care_link.dart';
import 'package:tata/features/care_link/application/usecases/generate_linking_code.dart';
import 'package:tata/features/care_link/application/usecases/join_as_caregiver.dart';
import 'package:tata/features/care_link/application/usecases/register_consent.dart';
import 'package:tata/features/care_link/application/usecases/register_older_adult.dart';
import 'package:tata/features/care_link/application/usecases/withdraw_consent.dart';
import 'package:tata/features/care_link/domain/value_objects/access_code_text.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_bloc.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_event.dart';
import 'package:tata/features/care_link/presentation/bloc/profiles/profiles_bloc.dart';
import 'package:tata/features/care_link/presentation/bloc/profiles/profiles_event.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25);

  ApiClient client(Future<http.Response> Function(http.Request) handler) {
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(api.close);
    return api;
  }

  ConsentBloc consentBloc(MemorySessionStore store, ApiClient api) {
    final consent = RemoteCareLinkConsent(
      api: CareLinkApi(api),
      store: store,
      clock: () => now,
    );
    return ConsentBloc(
      consent: consent,
      accept: AcceptCareLink(consent),
      decide: RegisterConsent(consent),
      withdraw: WithdrawConsent(consent),
    );
  }

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('access codes are recognized apart from full invitations', () {
    expect(AccessCodeText.tryParse(' k7pm q2xd '), 'K7PM-Q2XD');
    expect(AccessCodeText.tryParse('k7pmq2xd'), 'K7PM-Q2XD');
    expect(AccessCodeText.tryParse('K7PM-Q2XD'), 'K7PM-Q2XD');
    // Look-alike symbols are never issued.
    expect(AccessCodeText.tryParse('K0PM-Q1XD'), isNull);
    expect(AccessCodeText.tryParse('tata-link:v1:abc'), isNull);
  });

  test('an adult with a PIN is identified without storing a session', () async {
    final store = MemorySessionStore();
    late Map<String, Object?> sent;
    final bloc = consentBloc(
      store,
      client((request) async {
        expect(request.url.path, '/api/v1/care-links/access-code-redemptions');
        expect(request.headers.containsKey('Authorization'), isFalse);
        sent = jsonDecode(request.body) as Map<String, Object?>;
        return http.Response(
          jsonEncode({
            'careLinkId': 'link-A',
            'olderAdultId': 'adult-A',
            'olderAdultName': 'Rosa Vargas',
            'pinRegistered': true,
            'accessToken': null,
            'expiresAt': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(bloc.close);
    bloc.add(const InvitationSubmitted('k7pm-q2xd'));
    await settle();
    expect(sent['code'], 'K7PM-Q2XD');
    final AdultAccessRedemption redemption = bloc.state.redemption!;
    expect(redemption.pinRegistered, isTrue);
    expect(redemption.olderAdultName, 'Rosa Vargas');
    expect(store.current, isNull);
  });

  test('without a PIN the adult session is stored to create one', () async {
    final store = MemorySessionStore();
    final bloc = consentBloc(
      store,
      client(
        (_) async => http.Response(
          jsonEncode({
            'careLinkId': 'link-A',
            'olderAdultId': 'adult-A',
            'olderAdultName': 'Rosa Vargas',
            'pinRegistered': false,
            'accessToken': 'adult-token',
            'expiresAt': '2030-01-01T00:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(bloc.close);
    bloc.add(const InvitationSubmitted('K7PM-Q2XD'));
    await settle();
    expect(bloc.state.redemption!.pinRegistered, isFalse);
    expect(store.current?.owner.role, SessionRole.olderAdult);
    expect(store.current?.owner.careLinkId, 'link-A');
  });

  test('a used code is reported without touching the session', () async {
    final store = MemorySessionStore();
    final bloc = consentBloc(
      store,
      client((_) async => http.Response('{"code":"X"}', 410)),
    );
    addTearDown(bloc.close);
    bloc.add(const InvitationSubmitted('K7PM-Q2XD'));
    await settle();
    expect(bloc.state.errorCode, 'LINKING_CODE_EXPIRED_OR_USED');
    expect(bloc.state.redemption, isNull);
    expect(store.current, isNull);
  });

  test('a caregiver removes a person from the family list', () async {
    final store = MemorySessionStore(
      StoredSession(
        accessToken: 'caregiver-token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner('caregiver-A', SessionRole.caregiver),
      ),
    );
    final requests = <String>[];
    final repository = RemoteCareLinkRepository(
      api: CareLinkApi(
        client((request) async {
          requests.add('${request.method} ${request.url}');
          if (request.method == 'DELETE') return http.Response('', 204);
          return http.Response(
            jsonEncode([
              {
                'id': 'link-A',
                'olderAdultId': 'adult-A',
                'olderAdultName': 'Rosa Vargas',
                'confirmedAt': '2026-11-01T00:00:00Z',
                'adultSignedIn': false,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      store: store,
      clock: () => now,
    );
    final bloc = ProfilesBloc(
      reader: repository,
      register: RegisterOlderAdult(repository, () => now),
      generate: GenerateLinkingCode(repository),
      end: EndCareLink(repository),
    );
    addTearDown(bloc.close);
    bloc.add(const ProfilesRequested());
    await settle();
    expect(bloc.state.links.single.adultSignedIn, isFalse);
    bloc.add(const CareLinkEndRequested('link-A'));
    await settle();
    expect(bloc.state.ended, isTrue);
    expect(bloc.state.links, isEmpty);
    expect(
      requests.last,
      'DELETE https://example.com/api/v1/care-links/link-A?caregiverId=caregiver-A',
    );
  });

  test(
    'the adult accepts another caregiver and can remove the account',
    () async {
      final store = MemorySessionStore(
        StoredSession(
          accessToken: 'adult-token',
          expiresAt: DateTime.utc(2030),
          owner: SessionOwner(
            'adult-A',
            SessionRole.olderAdult,
            careLinkId: 'link-A',
          ),
        ),
      );
      var pending = true;
      final calls = <String>[];
      final bloc = consentBloc(
        store,
        client((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/decision')) {
            pending = false;
            return http.Response('{}', 200);
          }
          if (request.method == 'DELETE') return http.Response('', 204);
          return http.Response(
            jsonEncode([
              if (pending) {'careLinkId': 'link-B', 'caregiverName': 'Diego'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(bloc.close);
      bloc.add(const CaregiverRequestsRequested());
      await settle();
      expect(bloc.state.requests.single.caregiverName, 'Diego');
      bloc.add(const CaregiverRequestDecided('link-B', true));
      await settle();
      expect(bloc.state.decided, isTrue);
      expect(bloc.state.requests, isEmpty);
      expect(
        calls,
        contains('POST /api/v1/care-links/caregiver-requests/link-B/decision'),
      );
      bloc.add(const AccountRemovalRequested());
      await settle();
      expect(bloc.state.withdrawn, isTrue);
      expect(store.current, isNull);
    },
  );

  test('a caregiver joins with another caregiver code', () async {
    final store = MemorySessionStore(
      StoredSession(
        accessToken: 'caregiver-token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner('caregiver-B', SessionRole.caregiver),
      ),
    );
    late Map<String, Object?> sent;
    final repository = RemoteCareLinkRepository(
      api: CareLinkApi(
        client((request) async {
          sent = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response('{}', 201);
        }),
      ),
      store: store,
      clock: () => now,
    );
    final bloc = ProfilesBloc(
      reader: repository,
      register: RegisterOlderAdult(repository, () => now),
      generate: GenerateLinkingCode(repository),
      join: JoinAsCaregiver(repository),
    );
    addTearDown(bloc.close);
    bloc.add(const CaregiverJoinRequested('k7pm q2xd'));
    await settle();
    expect(bloc.state.joined, isTrue);
    expect(sent, {'caregiverId': 'caregiver-B', 'code': 'K7PM-Q2XD'});
  });
}
