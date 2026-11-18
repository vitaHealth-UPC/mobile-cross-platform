import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/app/config/app_config.dart';
import 'package:tata/features/identity_subscription/application/ports/public_plan_catalog.dart';
import 'package:tata/features/identity_subscription/application/usecases/subscription_usecases.dart';
import 'package:tata/features/identity_subscription/domain/entities/subscription_plan.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/subscription_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_public_plan_catalog.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/plan_choice/plan_choice_cubit.dart';
import 'package:tata/features/identity_subscription/presentation/navigation/plan_choice_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import 'subscription_test.dart'
    show FakeSubscriptions, essential, essentialJson, family, familyJson;

/// Catalog double with a scripted answer.
final class FakeCatalog implements PublicPlanCatalog {
  FakeCatalog(this.result);
  AppResult<List<SubscriptionPlan>> result;
  int reads = 0;

  @override
  Future<AppResult<List<SubscriptionPlan>>> plans() async {
    reads++;
    return result;
  }
}

void main() {
  group('public catalog', () {
    final requests = <http.Request>[];

    RemotePublicPlanCatalog catalog(int status, Object? body) {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(
            utf8.encode(jsonEncode(body)),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      return RemotePublicPlanCatalog(SubscriptionApi(client));
    }

    setUp(requests.clear);

    test('reads plans without any credential', () async {
      final result = await catalog(200, [familyJson, essentialJson]).plans();
      expect((result as AppSuccess).value, hasLength(2));
      expect(requests.single.url.path, '/api/v1/plans');
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('an empty or malformed catalog is not shown as plans', () async {
      expect(
        (await catalog(200, []).plans() as AppFailure).code,
        'INVALID_RESPONSE',
      );
      expect(
        (await catalog(200, {'x': 1}).plans() as AppFailure).code,
        'INVALID_RESPONSE',
      );
      expect(
        (await catalog(503, null).plans() as AppFailure).code,
        'REQUEST_FAILED',
      );
    });

    test('plans are listed from the lowest price', () async {
      final result = await GetPublicPlans(
        FakeCatalog(AppSuccess([family, essential])),
      ).call();
      expect((result as AppSuccess<List<SubscriptionPlan>>).value, [
        essential,
        family,
      ]);
    });
  });

  group('chosen plan', () {
    test('a choice that matches the starting plan sends nothing', () async {
      final subscriptions = FakeSubscriptions();
      final result = await ApplyChosenPlan(subscriptions).call('essential');
      expect(result, isA<AppSuccess<AccountSubscription>>());
      expect(subscriptions.changes, isEmpty);
    });

    test('another plan is activated for the new account', () async {
      final subscriptions = FakeSubscriptions();
      final result = await ApplyChosenPlan(subscriptions).call('FAMILY');
      expect(
        (result as AppSuccess<AccountSubscription>).value.plan.code,
        'FAMILY',
      );
      expect(subscriptions.changes, ['FAMILY']);
    });
  });

  group('contact destination', () {
    test('only https, mailto and tel with a target are accepted', () {
      for (final valid in [
        'https://tata.example/contacto',
        'mailto:hola@tata.example',
        'tel:+51999999999',
      ]) {
        expect(AppConfig.contactDestination(valid), isNotNull, reason: valid);
      }
      for (final invalid in [
        '',
        'http://tata.example',
        'javascript:alert(1)',
        'mailto:',
        'https://user@tata.example',
        'ftp://tata.example',
      ]) {
        expect(AppConfig.contactDestination(invalid), isNull, reason: invalid);
      }
    });
  });

  group('screen', () {
    Future<List<PlanChoice?>> pump(
      WidgetTester tester, {
      required FakeCatalog catalog,
      Uri? contact,
      Future<bool> Function(Uri)? open,
    }) async {
      tester.view
        ..physicalSize = const Size(393, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final results = <PlanChoice?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => results.add(
                  await Navigator.of(context).push<PlanChoice>(
                    MaterialPageRoute(
                      builder: (_) => PlanChoiceRoute(
                        createCubit: () =>
                            PlanChoiceCubit(GetPublicPlans(catalog)),
                        contactUri: contact,
                        openContact: open,
                      ),
                    ),
                  ),
                ),
                child: const Text('Comenzar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      return results;
    }

    OutlinedButton contactButton(WidgetTester tester) =>
        tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.textContaining(RegExp('Contactar|No disponible')),
            matching: find.byType(OutlinedButton),
          ),
        );

    testWidgets('plans, prices and what each includes (Figma 563:1913)', (
      tester,
    ) async {
      final results = await pump(
        tester,
        catalog: FakeCatalog(AppSuccess([family, essential])),
        contact: Uri.parse('mailto:hola@tata.example'),
        open: (_) async => true,
      );
      expect(find.text('Elige cómo empezar'), findsOneWidget);
      expect(find.text('S/ 9.90 / mes'), findsOneWidget);
      expect(find.text('S/ 19.90 / mes'), findsOneWidget);
      expect(find.text('Recomendado'), findsOneWidget);
      expect(find.text('Qué incluye cada plan'), findsOneWidget);
      expect(
        find.bySemanticsLabel('No incluido en Esencial'),
        findsNWidgets(2),
      );
      expect(find.bySemanticsLabel('Incluido en Familiar'), findsNWidgets(3));
      expect(contactButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Elegir Familiar'));
      await tester.pumpAndSettle();
      expect(results.single?.plan, family);
    });

    testWidgets('without a destination contact is unavailable (563:5425)', (
      tester,
    ) async {
      await pump(tester, catalog: FakeCatalog(AppSuccess([essential, family])));
      expect(find.text('No disponible'), findsOneWidget);
      expect(find.text('Contactar'), findsNothing);
      expect(contactButton(tester).onPressed, isNull);
      final node = tester.getSemantics(find.text('No disponible'));
      expect(
        node.getSemanticsData().hint,
        'El contacto no está disponible por ahora.',
      );
    });

    testWidgets('a destination that cannot open is not offered again', (
      tester,
    ) async {
      final opened = <Uri>[];
      await pump(
        tester,
        catalog: FakeCatalog(AppSuccess([essential, family])),
        contact: Uri.parse('https://tata.example/contacto'),
        open: (uri) async {
          opened.add(uri);
          return false;
        },
      );
      await tester.tap(find.text('Contactar'));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(find.text('No disponible'), findsOneWidget);
      expect(contactButton(tester).onPressed, isNull);
    });

    testWidgets('a failed catalog can be retried or skipped', (tester) async {
      final catalog = FakeCatalog(const AppFailure('NETWORK_UNAVAILABLE'));
      final results = await pump(tester, catalog: catalog);
      expect(find.text('No pudimos cargar los planes'), findsOneWidget);
      expect(find.text('Elegir Esencial'), findsNothing);

      catalog.result = AppSuccess([essential, family]);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(catalog.reads, 2);
      expect(find.text('Elegir Esencial'), findsOneWidget);

      catalog.result = const AppFailure('REQUEST_FAILED');
      await tester.tap(find.text('Elegir Esencial'));
      await tester.pumpAndSettle();
      expect(results.single?.plan, essential);
    });

    testWidgets('continuing without plans still reaches registration', (
      tester,
    ) async {
      final results = await pump(
        tester,
        catalog: FakeCatalog(const AppFailure('REQUEST_FAILED')),
      );
      await tester.tap(find.text('Continuar al registro'));
      await tester.pumpAndSettle();
      expect(results, hasLength(1));
      expect(results.single, isNotNull);
      expect(results.single!.plan, isNull);
    });
  });
}
