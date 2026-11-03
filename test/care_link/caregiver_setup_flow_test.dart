import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/usecases/generate_linking_code.dart';
import 'package:tata/features/care_link/application/usecases/register_older_adult.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/features/care_link/presentation/bloc/profiles/profiles_bloc.dart';
import 'package:tata/features/care_link/presentation/navigation/caregiver_setup_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/memory_session_store.dart';
import '../support/visual_capture.dart';

void main() {
  testWidgets(
    'caregiver registers a real editable profile, generates evidence and refreshes adult consent',
    (tester) async {
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadTataFonts();
      var confirmed = false;
      var registered = false;
      var generated = false;
      final store = MemorySessionStore(
        StoredSession(
          accessToken: 'caregiver-token',
          expiresAt: DateTime.utc(2030),
          owner: SessionOwner('caregiver-A', SessionRole.caregiver),
        ),
      );
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer caregiver-token');
          switch (request.url.path) {
            case '/api/v1/care-links':
              return http.Response(
                jsonEncode(
                  confirmed
                      ? [
                          {
                            'id': 'link-A',
                            'olderAdultId': 'adult-A',
                            'olderAdultName': 'Rosa Vargas',
                            'confirmedAt': '2026-10-27T00:00:00Z',
                          },
                        ]
                      : [],
                ),
                200,
              );
            case '/api/v1/older-adults':
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['fullName'], 'Rosa Vargas');
              expect(body['birthDate'], '1958-05-03');
              registered = true;
              return http.Response(
                jsonEncode({
                  'id': 'adult-A',
                  'registeredByCaregiverId': 'caregiver-A',
                  'fullName': body['fullName'],
                  'birthDate': body['birthDate'],
                }),
                201,
              );
            case '/api/v1/care-links/linking-codes':
              expect(registered, true);
              generated = true;
              return http.Response(
                jsonEncode({
                  'id': 'link-A',
                  'caregiverId': 'caregiver-A',
                  'olderAdultId': 'adult-A',
                  'status': 'PENDING',
                  'linkingCode': 'TATA-4821',
                  'codeExpiresAt': '2030-01-01T00:00:00Z',
                  'consentGranted': false,
                  'codeUsedAt': null,
                }),
                201,
              );
            default:
              throw StateError('Unexpected request');
          }
        }),
      );
      addTearDown(client.close);
      final repository = RemoteCareLinkRepository(
        api: CareLinkApi(client),
        store: store,
        clock: DateTime.now,
      );
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(top: 24, bottom: 24)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const Key('care-link-capture'),
            child: CaregiverSetupRoute(
              createBloc: () => ProfilesBloc(
                reader: repository,
                register: RegisterOlderAdult(repository, DateTime.now),
                generate: GenerateLinkingCode(repository),
              ),
              onSignOut: () {},
              onSessionInvalidated: () =>
                  fail('Unexpected session invalidation'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No tienes vínculos confirmados.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('adult-name')),
        'Rosa Vargas',
      );
      await tester.tap(find.text('Fecha de nacimiento'));
      await tester.pumpAndSettle();
      final pickerText = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.byTooltip(pickerText.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      final dateField = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dateField, '03/05/1958');
      await tester.tap(find.text(pickerText.okButtonLabel));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Registrar familiar'),
      );
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Registrar familiar'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Rosa Vargas,'), findsOneWidget);
      await tester.tap(find.text('Generar código'));
      await tester.pumpAndSettle();
      expect(generated, true);
      expect(find.text('TATA-4821'), findsOneWidget);
      expect(find.text('Aceptar vínculo'), findsNothing);
      await captureWidget(
        tester,
        find.byKey(const Key('care-link-capture')),
        'caregiver-link-pending-es',
      );
      confirmed = true;
      await tester.ensureVisible(find.text('Consultar consentimiento'));
      await tester.tap(find.text('Consultar consentimiento'));
      await tester.pumpAndSettle();
      expect(find.text('Vínculo confirmado'), findsOneWidget);
      expect(find.text('Renovar código'), findsNothing);
      expect(store.current?.owner.role, SessionRole.caregiver);
      debugDisableShadows = previousShadows;
      expect(tester.takeException(), isNull);
    },
  );
}
