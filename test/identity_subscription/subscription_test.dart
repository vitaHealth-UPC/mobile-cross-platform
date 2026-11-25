import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/ports/subscription_repository.dart';
import 'package:tata/features/identity_subscription/application/usecases/change_subscription_plan.dart';
import 'package:tata/features/identity_subscription/application/usecases/get_subscription_overview.dart';
import 'package:tata/features/identity_subscription/domain/entities/subscription_plan.dart';
import 'package:tata/features/identity_subscription/infrastructure/mappers/subscription_mapper.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/subscription_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_subscription_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/subscription/subscription_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/subscription/subscription_event.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/subscription/subscription_state.dart';
import 'package:tata/features/identity_subscription/presentation/screens/plan_subscription_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/memory_session_store.dart';

const essentialJson = {
  'code': 'ESSENTIAL',
  'name': 'Esencial',
  'monthlyPrice': 9.90,
  'currency': 'PEN',
  'capabilities': ['AGENDA', 'REMINDERS', 'INTAKE_CONFIRMATION'],
};

const familyJson = {
  'code': 'FAMILY',
  'name': 'Familiar',
  'monthlyPrice': 19.90,
  'currency': 'PEN',
  'capabilities': [
    'REMINDERS',
    'AGENDA',
    'INTAKE_CONFIRMATION',
    'FAMILY_ALERTS',
    'FAMILY_MONITORING',
    'ADHERENCE_INSIGHTS',
  ],
};

Map<String, Object?> subscriptionJson(
  Map<String, Object?> plan, {
  String account = 'caregiver-1',
}) => {
  'accountId': account,
  'plan': plan,
  'status': 'ACTIVE',
  'renewsAt': '2026-12-17T12:00:00Z',
};

final essential = SubscriptionMapper.plan(essentialJson);
final family = SubscriptionMapper.plan(familyJson);

/// Server double that records changes.
final class FakeSubscriptions implements SubscriptionRepository {
  AccountSubscription now = SubscriptionMapper.subscription(
    subscriptionJson(essentialJson),
  );
  AppResult<AccountSubscription>? changeResult;
  final changes = <String>[];

  @override
  Future<AppResult<AccountSubscription>> current() async => AppSuccess(now);

  @override
  Future<AppResult<List<SubscriptionPlan>>> plans() async =>
      AppSuccess([essential, family]);

  @override
  Future<AppResult<AccountSubscription>> change(String planCode) async {
    changes.add(planCode);
    return changeResult ??
        AppSuccess(
          SubscriptionMapper.subscription(
            subscriptionJson(planCode == 'FAMILY' ? familyJson : essentialJson),
          ),
        );
  }
}

SubscriptionBloc blocFor(FakeSubscriptions fake) => SubscriptionBloc(
  overview: GetSubscriptionOverview(fake),
  change: ChangeSubscriptionPlan(fake),
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('mapper', () {
    test('reads plans and ignores capabilities this app does not know', () {
      final plan = SubscriptionMapper.plan({
        ...familyJson,
        'capabilities': ['REMINDERS', 'SOMETHING_NEW'],
      });
      expect(plan.capabilities, {PlanCapability.reminders});
      expect(planPrice(family), 'S/ 19.90');
    });

    test('rejects malformed plans and subscriptions', () {
      expect(
        () => SubscriptionMapper.plan({...essentialJson, 'monthlyPrice': '9'}),
        throwsFormatException,
      );
      expect(
        () => SubscriptionMapper.subscription({
          ...subscriptionJson(essentialJson),
          'renewsAt': '2026-12-17T12:00:00',
        }),
        throwsFormatException,
      );
    });
  });

  group('remote repository', () {
    late MemorySessionStore store;
    final requests = <http.Request>[];

    setUp(() {
      requests.clear();
      store = MemorySessionStore(
        StoredSession(
          accessToken: 'caregiver-token',
          expiresAt: DateTime.utc(2099),
          owner: SessionOwner('caregiver-1', SessionRole.caregiver),
        ),
      );
    });

    RemoteSubscriptionRepository repo(int status, Object? body) {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(
            body == null ? const [] : utf8.encode(jsonEncode(body)),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      return RemoteSubscriptionRepository(
        api: SubscriptionApi(client),
        store: store,
      );
    }

    test('reads the subscription of the session account', () async {
      final result = await repo(200, subscriptionJson(familyJson)).current();
      expect(
        (result as AppSuccess<AccountSubscription>).value.plan.code,
        'FAMILY',
      );
      expect(
        requests.single.url.path,
        '/api/v1/accounts/caregiver-1/subscription',
      );
      expect(
        requests.single.headers['Authorization'],
        'Bearer caregiver-token',
      );
    });

    test('a receipt for another account is not trusted', () async {
      final result = await repo(
        200,
        subscriptionJson(familyJson, account: 'caregiver-2'),
      ).current();
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    });

    test('a change sends the plan code and must show that plan', () async {
      final result = await repo(
        200,
        subscriptionJson(familyJson),
      ).change('FAMILY');
      expect(result, isA<AppSuccess<AccountSubscription>>());
      expect(requests.single.method, 'PUT');
      expect(jsonDecode(requests.single.body), {'planCode': 'FAMILY'});

      final ignored = await repo(
        200,
        subscriptionJson(essentialJson),
      ).change('FAMILY');
      expect((ignored as AppFailure).code, 'INVALID_RESPONSE');
    });

    test('keeps the documented plan error code', () async {
      final result = await repo(404, {
        'title': 'PLAN_NOT_FOUND',
        'status': 404,
      }).change('PREMIUM');
      expect((result as AppFailure).code, 'PLAN_NOT_FOUND');
    });

    test('an older adult session has no account subscription', () async {
      store.value = StoredSession(
        accessToken: 'adult-token',
        expiresAt: DateTime.utc(2099),
        owner: SessionOwner(
          'adult-1',
          SessionRole.olderAdult,
          careLinkId: 'link-1',
        ),
      );
      final result = await repo(200, subscriptionJson(familyJson)).current();
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      expect(requests, isEmpty);
    });
  });

  group('bloc', () {
    test(
      'only another plan can be chosen, and choosing it again clears it',
      () async {
        final bloc = blocFor(FakeSubscriptions())
          ..add(const SubscriptionRequested());
        await settle();
        expect(bloc.state.phase, SubscriptionPhase.ready);
        bloc.add(const SubscriptionPlanSelected('ESSENTIAL'));
        await settle();
        expect(bloc.state.selectedCode, isNull);
        bloc.add(const SubscriptionPlanSelected('FAMILY'));
        await settle();
        expect(bloc.state.selected?.code, 'FAMILY');
        bloc.add(const SubscriptionPlanSelected('FAMILY'));
        await settle();
        expect(bloc.state.selectedCode, isNull);
        await bloc.close();
      },
    );

    test('a confirmed change shows the server subscription', () async {
      final fake = FakeSubscriptions();
      final bloc = blocFor(fake)..add(const SubscriptionRequested());
      await settle();
      bloc
        ..add(const SubscriptionPlanSelected('FAMILY'))
        ..add(const SubscriptionChangeConfirmed());
      await settle();
      await settle();
      expect(fake.changes, ['FAMILY']);
      expect(bloc.state.subscription!.plan.code, 'FAMILY');
      expect(bloc.state.updated, isTrue);
      expect(bloc.state.selectedCode, isNull);
      await bloc.close();
    });

    test('a refused change keeps the current plan and reports it', () async {
      final fake = FakeSubscriptions()
        ..changeResult = const AppFailure('PLAN_NOT_FOUND');
      final bloc = blocFor(fake)..add(const SubscriptionRequested());
      await settle();
      bloc
        ..add(const SubscriptionPlanSelected('FAMILY'))
        ..add(const SubscriptionChangeConfirmed());
      await settle();
      await settle();
      expect(bloc.state.subscription!.plan.code, 'ESSENTIAL');
      expect(bloc.state.errorCode, 'PLAN_NOT_FOUND');
      expect(bloc.state.changing, isFalse);
      await bloc.close();
    });
  });

  group('screen', () {
    Future<FakeSubscriptions> pump(
      WidgetTester tester, {
      VoidCallback? onSessionInvalidated,
      FakeSubscriptions? fake,
    }) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final subscriptions = fake ?? FakeSubscriptions();
      final bloc = blocFor(subscriptions);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: PlanSubscriptionScreen(
              clock: () => DateTime.utc(2026, 12, 2, 12),
              onSessionInvalidated: onSessionInvalidated ?? () {},
            ),
          ),
        ),
      );
      bloc.add(const SubscriptionRequested());
      await tester.pumpAndSettle();
      return subscriptions;
    }

    testWidgets(
      'shows the current plan, the catalog and the renewal (563:1701)',
      (tester) async {
        await pump(tester);
        expect(find.text('Plan y suscripción'), findsOneWidget);
        expect(find.text('Plan Esencial'), findsOneWidget);
        expect(find.text('S/ 9.90 / mes'), findsOneWidget);
        expect(find.text('Plan actual'), findsOneWidget);
        expect(find.text('S/ 19.90'), findsOneWidget);
        expect(find.text('Alertas'), findsOneWidget);
        // Product order, even though the server sends an unordered set.
        expect(
          tester.getTopLeft(find.text('Recordatorios')).dx,
          lessThan(tester.getTopLeft(find.text('Agenda')).dx),
        );
        expect(find.text('Próxima renovación'), findsOneWidget);
        final change = tester.widget<ElevatedButton>(
          find.byKey(const Key('change-plan')),
        );
        expect(change.onPressed, isNull);
      },
    );

    testWidgets('changes only after confirming, then announces it (563:5354)', (
      tester,
    ) async {
      final fake = await pump(tester);
      await tester.tap(find.text('Familiar'));
      await tester.pumpAndSettle();
      expect(find.text('Seleccionado'), findsOneWidget);

      await tester.tap(find.byKey(const Key('change-plan')));
      await tester.pumpAndSettle();
      expect(find.text('¿Cambiar al plan Familiar?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(fake.changes, isEmpty);

      await tester.tap(find.byKey(const Key('change-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();
      expect(fake.changes, ['FAMILY']);
      expect(find.text('Plan Familiar'), findsOneWidget);
      expect(find.text('Suscripción actualizada'), findsOneWidget);
      expect(
        find.text('Las capacidades del nuevo plan ya están disponibles.'),
        findsOneWidget,
      );
    });
  });
}
