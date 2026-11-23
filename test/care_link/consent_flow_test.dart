import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/app/tata_app.dart';
import 'package:tata/features/care_link/application/usecases/accept_care_link.dart';
import 'package:tata/features/care_link/application/usecases/register_consent.dart';
import 'package:tata/features/care_link/application/usecases/withdraw_consent.dart';
import 'package:tata/features/care_link/domain/value_objects/care_link_invitation.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_bloc.dart';
import 'package:tata/features/care_link/presentation/navigation/consent_management_route.dart';
import 'package:tata/features/care_link/presentation/navigation/consent_route.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';
import '../support/visual_capture.dart';

void main() {
  for (final accepted in [true, false]) {
    testWidgets(
      'adult invitation and explicit decision $accepted route through restricted access',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await loadTataFonts();
        final store = MemorySessionStore();
        var decided = false;
        Map<String, Object?> body({bool credential = true}) => {
          'id': 'link-A',
          'caregiverId': 'caregiver-A',
          'olderAdultId': 'adult-A',
          'status': !decided
              ? 'AWAITING_CONSENT'
              : accepted
              ? 'CONFIRMED'
              : 'REVOKED',
          'consentGranted': decided && accepted,
          'codeUsedAt': '2026-10-27T00:00:00Z',
          'consentRecordedAt': decided ? '2026-10-27T00:01:00Z' : null,
          'confirmedAt': decided && accepted ? '2026-10-27T00:01:00Z' : null,
          'accessToken': credential && (!decided || accepted)
              ? (decided ? 'adult-token' : 'setup-token')
              : null,
          'expiresAt': credential && (!decided || accepted)
              ? '2030-01-01T00:00:00Z'
              : null,
        };
        final client = ApiClient(
          baseUrl: Uri.parse('https://example.com/'),
          client: MockClient((request) async {
            switch (request.url.path) {
              case '/api/v1/care-links/acceptances':
                expect(request.headers.containsKey('Authorization'), false);
                return http.Response(jsonEncode(body()), 200);
              case '/api/v1/sessions/current':
                expect(
                  request.headers['Authorization'],
                  decided ? 'Bearer adult-token' : 'Bearer setup-token',
                );
                return http.Response(
                  jsonEncode({
                    'subjectId': 'adult-A',
                    'role': decided ? 'OLDER_ADULT' : 'LINK_SETUP',
                    'careLinkId': 'link-A',
                  }),
                  200,
                );
              case '/api/v1/care-links/link-A':
                expect(request.headers['Authorization'], 'Bearer setup-token');
                return http.Response(jsonEncode(body(credential: false)), 200);
              case '/api/v1/care-links/link-A/consent':
                expect(store.current?.owner.role, SessionRole.linkSetup);
                expect(jsonDecode(request.body), {'accepted': accepted});
                decided = true;
                return http.Response(jsonEncode(body()), 200);
              default:
                throw StateError('Unexpected endpoint');
            }
          }),
        );
        addTearDown(client.close);
        final consent = RemoteCareLinkConsent(
          api: CareLinkApi(client),
          store: store,
          clock: DateTime.now,
        );
        final sessions = RemoteSessionRepository(
          api: SessionApi(client),
          store: store,
          clock: DateTime.now,
        );
        ConsentBloc createConsent() => ConsentBloc(
          consent: consent,
          accept: AcceptCareLink(consent),
          decide: RegisterConsent(consent),
          withdraw: WithdrawConsent(consent),
        );
        await tester.pumpWidget(
          TataApp(
            createAccessBloc: () => AccessBloc(
              signIn: SignIn(sessions),
              restore: RestoreSession(sessions),
              signOut: SignOut(sessions),
            ),
            authenticatedBuilder: (_, _, _) => throw StateError(
              'Adult incorrectly routed into caregiver setup',
            ),
            adultBuilder: (_, signOut, changed) => ConsentManagementRoute(
              createBloc: createConsent,
              onSessionChanged: changed,
              onSignOut: signOut,
            ),
            consentBuilder: (_, signOut, changed) => RepaintBoundary(
              key: const Key('consent-capture'),
              child: ConsentRoute(
                createBloc: createConsent,
                onSessionChanged: changed,
                onSignOut: signOut,
              ),
            ),
            invitationBuilder: (context) => ConsentRoute(
              createBloc: createConsent,
              invitationEntry: true,
              onSessionChanged: () => Navigator.of(context).pop(false),
              onSignOut: () => Navigator.of(context).pop(false),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Iniciar sesión'));
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Tengo una invitación'));
        await tester.tap(find.text('Tengo una invitación'));
        await tester.pumpAndSettle();
        final invitation = CareLinkInvitation(
          caregiverId: 'caregiver-A',
          code: 'TATA-TEST',
        );
        await tester.enterText(
          find.byKey(const Key('care-invitation')),
          invitation.encode(),
        );
        await tester.ensureVisible(find.text('Revisar invitación'));
        await tester.tap(find.text('Revisar invitación'));
        await tester.pumpAndSettle();
        expect(store.current?.owner.role, SessionRole.linkSetup);
        expect(find.text('Sesión iniciada'), findsNothing);
        expect(
          tester.getTopLeft(find.text('Vincula a tu familiar')).dy,
          greaterThanOrEqualTo(44),
        );
        if (accepted) {
          await captureWidget(
            tester,
            find.byKey(const Key('consent-capture')),
            'adult-consent-ready-es',
          );
        }
        await tester.ensureVisible(
          find.text(accepted ? 'Aceptar vínculo' : 'Rechazar'),
        );
        await tester.tap(find.text(accepted ? 'Aceptar vínculo' : 'Rechazar'));
        await tester.pumpAndSettle();
        expect(decided, true);
        if (accepted) {
          expect(store.current?.owner.role, SessionRole.olderAdult);
          expect(find.text('Tu vínculo de cuidado'), findsOneWidget);
        } else {
          expect(store.current, isNull);
          expect(find.text('Inicia sesión'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
