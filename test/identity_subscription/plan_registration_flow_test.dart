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
import 'package:tata/features/identity_subscription/application/usecases/subscription_usecases.dart';
import 'package:tata/features/identity_subscription/application/usecases/verify_email.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/registration_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/plan_choice/plan_choice_cubit.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';
import 'plan_choice_test.dart' show FakeCatalog;
import 'subscription_test.dart' show essential, family;

void main() {
  Future<({List<String> applied, MemorySessionStore store})> run(
    WidgetTester tester, {
    required bool applies,
  }) async {
    tester.view
      ..physicalSize = const Size(393, 1100)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemorySessionStore();
    final account = {
      'id': 'account-A',
      'name': 'User',
      'email': 'user@example.com',
      'status': 'PENDING_VERIFICATION',
    };
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(
        (request) async => switch (request.url.path) {
          '/api/v1/accounts' => http.Response(jsonEncode(account), 201),
          '/api/v1/accounts/verification' => http.Response(
            jsonEncode({
              ...account,
              'status': 'ACTIVE',
              'accessToken': 'issued-token',
              'expiresAt': '2030-01-01T00:00:00Z',
            }),
            200,
          ),
          '/api/v1/sessions/current' => http.Response(
            '{"subjectId":"account-A","role":"CAREGIVER"}',
            200,
          ),
          _ => throw StateError('Unexpected request'),
        },
      ),
    );
    addTearDown(client.close);
    final now = DateTime.utc(2026, 11, 18);
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
    final applied = <String>[];
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
        createPlanChoiceCubit: () => PlanChoiceCubit(
          GetPublicPlans(FakeCatalog(AppSuccess([essential, family]))),
        ),
        applyChosenPlan: (code) async {
          // The plan is applied with the new account's session, never before.
          expect(store.current?.owner.id, 'account-A');
          applied.add(code);
          return applies;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige cómo empezar'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
    await tester.tap(find.text('Elegir Familiar'));
    await tester.pumpAndSettle();
    expect(applied, isEmpty);

    await tester.enterText(find.byKey(const Key('registration-name')), 'User');
    await tester.enterText(
      find.byKey(const Key('registration-email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('registration-password')),
      'password',
    );
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('registration-code')),
      '654321',
    );
    await tester.ensureVisible(find.text('Verificar correo'));
    await tester.tap(find.text('Verificar correo'));
    await tester.pumpAndSettle();
    return (applied: applied, store: store);
  }

  testWidgets('the plan chosen before registering is activated afterwards', (
    tester,
  ) async {
    final result = await run(tester, applies: true);
    expect(result.applied, ['FAMILY']);
    expect(find.text('Sesión iniciada'), findsOneWidget);
    expect(find.textContaining('No pudimos activar'), findsNothing);
  });

  testWidgets('a plan that could not be activated is explained', (
    tester,
  ) async {
    final result = await run(tester, applies: false);
    expect(result.applied, ['FAMILY']);
    expect(find.text('Sesión iniciada'), findsOneWidget);
    expect(
      find.text(
        'Tu cuenta está lista. No pudimos activar el plan elegido; '
        'puedes cambiarlo en Ajustes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('going back from the plans keeps the welcome screen', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(393, 1100)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemorySessionStore();
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient((_) async => throw StateError('No request expected')),
    );
    addTearDown(client.close);
    final sessions = RemoteSessionRepository(
      api: SessionApi(client),
      store: store,
      clock: DateTime.now,
    );
    await tester.pumpWidget(
      TataApp(
        createAccessBloc: () => AccessBloc(
          signIn: SignIn(sessions),
          restore: RestoreSession(sessions),
          signOut: SignOut(sessions),
        ),
        createPlanChoiceCubit: () => PlanChoiceCubit(
          GetPublicPlans(FakeCatalog(AppSuccess([essential, family]))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.byKey(const Key('registration-name')), findsNothing);
  });
}
