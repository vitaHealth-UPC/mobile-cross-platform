import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/usecases/accept_care_link.dart';
import 'package:tata/features/care_link/application/usecases/register_consent.dart';
import 'package:tata/features/care_link/application/usecases/withdraw_consent.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_bloc.dart';
import 'package:tata/features/care_link/presentation/navigation/consent_management_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/memory_session_store.dart';
import '../support/visual_capture.dart';

void main() {
  testWidgets(
    'adult cancels withdrawal, retries an outage, then confirms revocation',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadTataFonts();
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
      var requests = 0;
      var changes = 0;
      var withdrawals = 0;
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          requests++;
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/v1/care-links/link-A/consent');
          return http.Response('', requests == 1 ? 503 : 204);
        }),
      );
      addTearDown(client.close);
      final consent = RemoteCareLinkConsent(
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
            key: const Key('withdrawal-capture'),
            child: ConsentManagementRoute(
              createBloc: () => ConsentBloc(
                consent: consent,
                accept: AcceptCareLink(consent),
                decide: RegisterConsent(consent),
                withdraw: WithdrawConsent(consent),
              ),
              onSessionChanged: () => changes++,
              onWithdrawn: () => withdrawals++,
              onSignOut: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureWidget(
        tester,
        find.byKey(const Key('withdrawal-capture')),
        'adult-consent-management-es',
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Retirar consentimiento'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conservar vínculo'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(store.current, isNotNull);
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Retirar consentimiento'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-withdrawal')));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(changes, 0);
      expect(withdrawals, 0, reason: 'an outage is not a withdrawal');
      expect(store.current, isNotNull);
      expect(
        find.text('No pudimos completar el vínculo. Inténtalo nuevamente.'),
        findsOneWidget,
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Retirar consentimiento'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-withdrawal')));
      await tester.pumpAndSettle();
      expect(requests, 2);
      expect(changes, 1);
      expect(withdrawals, 1);
      expect(store.current, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
