import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/app/tata_app.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_caregiver.dart';
import 'package:tata/features/identity_subscription/application/usecases/request_verification.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/application/usecases/verify_email.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/registration_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  testWidgets(
    'registration route retries expired code, resends, verifies and restores issued account',
    (tester) async {
      tester.view.physicalSize = const Size(393, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemorySessionStore();
      final paths = <String>[];
      var attempts = 0;
      final account = {
        'id': 'account-A',
        'name': 'User',
        'email': 'user@example.com',
        'status': 'PENDING_VERIFICATION',
      };
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          paths.add(request.url.path);
          switch (request.url.path) {
            case '/api/v1/accounts':
              expect(store.current, isNull);
              expect(jsonDecode(request.body), {
                'name': 'User',
                'email': 'user@example.com',
                'password': 'password',
              });
              return http.Response(jsonEncode(account), 201);
            case '/api/v1/accounts/verification':
              attempts++;
              expect(store.current, isNull);
              if (attempts == 1) {
                return http.Response('{"title":"VERIFICATION_EXPIRED"}', 410);
              }
              expect(jsonDecode(request.body), {
                'email': 'user@example.com',
                'code': '654321',
              });
              return http.Response(
                jsonEncode({
                  ...account,
                  'status': 'ACTIVE',
                  'accessToken': 'issued-token',
                  'expiresAt': '2030-01-01T00:00:00Z',
                }),
                200,
              );
            case '/api/v1/email-verification-requests':
              return http.Response(jsonEncode(account), 202);
            case '/api/v1/sessions/current':
              expect(request.headers['Authorization'], 'Bearer issued-token');
              return http.Response(
                '{"subjectId":"account-A","role":"CAREGIVER"}',
                200,
              );
            default:
              throw StateError('Unexpected request');
          }
        }),
      );
      addTearDown(client.close);
      final now = DateTime.utc(2026, 10, 27);
      final sessions = RemoteSessionRepository(
        api: SessionApi(client),
        store: store,
        clock: () => now,
      );
      final registration = RemoteAccountRegistration(
        api: RegistrationApi(client),
        store: store,
        clock: () => now,
      );
      await tester.pumpWidget(
        TataApp(
          createAccessBloc: () => AccessBloc(
            signIn: SignIn(sessions),
            restore: RestoreSession(sessions),
            signOut: SignOut(sessions),
          ),
          createRegistrationBloc: () => RegistrationBloc(
            register: RegisterCaregiver(registration),
            verify: VerifyEmail(registration),
            resend: RequestVerification(registration),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Comenzar'));
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('registration-name')),
        ' User ',
      );
      await tester.enterText(
        find.byKey(const Key('registration-email')),
        ' USER@example.com ',
      );
      await tester.enterText(
        find.byKey(const Key('registration-password')),
        'password',
      );
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(store.current, isNull);
      await tester.enterText(
        find.byKey(const Key('registration-code')),
        '123456',
      );
      await tester.ensureVisible(find.text('Verificar correo'));
      await tester.tap(find.text('Verificar correo'));
      await tester.pumpAndSettle();
      expect(
        find.text('El código venció. Solicita uno nuevo.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Reenviar código'));
      await tester.tap(find.text('Reenviar código'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('registration-code')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const Key('registration-code')),
        '654321',
      );
      await tester.ensureVisible(find.text('Verificar correo'));
      await tester.tap(find.text('Verificar correo'));
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada'), findsOneWidget);
      expect(store.current?.owner.id, 'account-A');
      expect(paths, [
        '/api/v1/accounts',
        '/api/v1/accounts/verification',
        '/api/v1/email-verification-requests',
        '/api/v1/accounts/verification',
        '/api/v1/sessions/current',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
