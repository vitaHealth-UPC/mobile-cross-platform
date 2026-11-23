import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/usecases/complete_password_recovery.dart';
import 'package:tata/features/identity_subscription/application/usecases/request_password_recovery.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/password_recovery_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_password_recovery.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/recovery/recovery_event.dart';
import 'package:tata/features/identity_subscription/presentation/screens/password_recovery_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

void main() {
  RemotePasswordRecovery repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemotePasswordRecovery(PasswordRecoveryApi(client));
  }

  test(
    'anonymous recovery normalizes email and preserves new password exactly',
    () async {
      final repo = repository((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.path.endsWith('password-recovery-requests')) {
          expect(jsonDecode(request.body), {'email': 'user@example.com'});
          return http.Response('', 202);
        }
        expect(request.url.path, '/api/v1/password-recoveries');
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'code': '123456',
          'newPassword': ' password ',
        });
        return http.Response('', 204);
      });
      expect(
        await RequestPasswordRecovery(repo)(' USER@example.com '),
        isA<AppSuccess<void>>(),
      );
      expect(
        await CompletePasswordRecovery(repo)(
          ' USER@example.com ',
          '123456',
          ' password ',
        ),
        isA<AppSuccess<void>>(),
      );
    },
  );

  test(
    'input validation prevents HTTP and events redact recovery secrets',
    () async {
      var calls = 0;
      final repo = repository((_) async {
        calls++;
        return http.Response('', 500);
      });
      expect(await RequestPasswordRecovery(repo)('invalid'), isA<AppFailure>());
      expect(
        await CompletePasswordRecovery(repo)(
          'user@example.com',
          '１２３４５６',
          'password',
        ),
        isA<AppFailure>(),
      );
      expect(
        await CompletePasswordRecovery(repo)(
          'user@example.com',
          '123456',
          'é' * 40,
        ),
        isA<AppFailure>(),
      );
      expect(calls, 0);
      expect(
        const RecoveryCompleted('123456', 'secret-password').toString(),
        isNot(contains('secret-password')),
      );
      expect(
        const RecoveryRequested('private@example.com').toString(),
        isNot(contains('private@example.com')),
      );
    },
  );

  test(
    'only exact receipts succeed and invalid code retains safe error',
    () async {
      for (final status in [200, 201, 204]) {
        final repo = repository((_) async => http.Response('', status));
        expect(await repo.request('user@example.com'), isA<AppFailure>());
      }
      final repo = repository(
        (_) async => http.Response(
          '{"title":"INVALID_RECOVERY_CODE","detail":"private diagnostic"}',
          400,
        ),
      );
      expect(
        await repo.complete('user@example.com', '123456', 'password'),
        isA<AppFailure>().having(
          (r) => r.code,
          'code',
          'INVALID_RECOVERY_CODE',
        ),
      );
    },
  );

  testWidgets(
    'recovery retries invalid code, resends and ends at sign-in confirmation without creating a session',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadTataFonts();
      var requests = 0;
      var completions = 0;
      final repo = repository((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.path.endsWith('password-recovery-requests')) {
          requests++;
          if (requests == 2) return http.Response('', 503);
          return http.Response('', 202);
        }
        completions++;
        return completions == 1
            ? http.Response('{"title":"INVALID_RECOVERY_CODE"}', 400)
            : http.Response('', 204);
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('es'),
          theme: TataTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider(
            create: (_) => RecoveryBloc(
              request: RequestPasswordRecovery(repo),
              complete: CompletePasswordRecovery(repo),
            ),
            child: const RepaintBoundary(
              key: Key('recovery-capture'),
              child: PasswordRecoveryScreen(),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('recovery-email')),
        'user@example.com',
      );
      await tester.tap(find.text('Solicitar código'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Si existe una cuenta con ese correo, recibirás un código de recuperación.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('recovery-code')), '123456');
      await tester.enterText(
        find.byKey(const Key('recovery-password')),
        'new-password',
      );
      await tester.pumpAndSettle();
      await captureWidget(
        tester,
        find.byKey(const Key('recovery-capture')),
        'recovery-code-es',
      );
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
      expect(find.text('El código no es válido o ha vencido.'), findsOneWidget);
      await tester.tap(find.text('Reenviar código'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recovery-code')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('recovery-code')))
            .controller!
            .text,
        '123456',
      );
      expect(
        find.text(
          'No pudimos completar la recuperación. Inténtalo nuevamente.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Reenviar código'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('recovery-code')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(find.byKey(const Key('recovery-code')), '654321');
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Tu contraseña se actualizó. Inicia sesión con tu nueva contraseña.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recovery-password')), findsNothing);
      expect(find.text('Sesión iniciada'), findsNothing);
      await captureWidget(
        tester,
        find.byKey(const Key('recovery-capture')),
        'recovery-success-es',
      );
      expect(requests, 3);
      expect(completions, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
