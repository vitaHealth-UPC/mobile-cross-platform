import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/inventory_replenishment/application/ports/inventory_repository.dart';
import 'package:tata/features/inventory_replenishment/application/usecases/inventory_usecases.dart';
import 'package:tata/features/inventory_replenishment/domain/entities/inventory.dart';
import 'package:tata/features/inventory_replenishment/domain/value_objects/inventory_input.dart';
import 'package:tata/features/inventory_replenishment/infrastructure/mappers/inventory_mapper.dart';
import 'package:tata/features/inventory_replenishment/infrastructure/remote/inventory_api.dart';
import 'package:tata/features/inventory_replenishment/infrastructure/repositories/remote_inventory_repository.dart';
import 'package:tata/features/inventory_replenishment/presentation/bloc/inventory_bloc.dart';
import 'package:tata/features/inventory_replenishment/presentation/bloc/inventory_event.dart';
import 'package:tata/features/inventory_replenishment/presentation/bloc/inventory_state.dart';
import 'package:tata/features/inventory_replenishment/presentation/screens/inventory_screen.dart';
import 'package:tata/features/treatment_management/application/usecases/medication_usecases.dart';
import 'package:tata/features/treatment_management/domain/entities/medication.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_event.dart';
import 'package:tata/features/treatment_management/presentation/screens/medication_management_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
import '../support/memory_session_store.dart';

const medicationId = 'medication-1';

Map<String, Object?> resource({
  int remaining = 5,
  bool low = true,
  int? days = 5,
  List<Map<String, Object?>>? batches,
  String medication = medicationId,
}) => {
  'id': 'inventory-1',
  'medicationId': medication,
  'remainingStock': remaining,
  'replenishmentThreshold': 5,
  'lowStock': low,
  'daysRemaining': days,
  'dailyConsumptionUnits': 1,
  'createdAt': '2026-09-01T12:00:00Z',
  'updatedAt': '2026-09-02T12:00:00Z',
  'batches':
      batches ??
      [
        {
          'id': 'batch-1',
          'quantity': 30,
          'registeredAt': '2026-08-01T12:00:00Z',
          'lot': null,
        },
      ],
};

Inventory stock({
  int remaining = 5,
  bool low = true,
  int? days = 5,
  bool replenished = false,
}) => InventoryMapper.inventory(
  resource(
    remaining: remaining,
    low: low,
    days: days,
    batches: [
      {
        'id': 'batch-1',
        'quantity': 30,
        'registeredAt': '2026-08-01T12:00:00Z',
        'lot': null,
      },
      if (replenished)
        {
          'id': 'batch-2',
          'quantity': 30,
          'registeredAt': '2026-09-02T15:00:00Z',
          'lot': 'Lote 2026-09',
        },
    ],
  ),
);

/// Server double: records calls and answers with configured results.
final class FakeInventory implements InventoryRepository {
  AppResult<Inventory> found = AppSuccess(stock());
  AppResult<Inventory>? written;
  int finds = 0;
  final writes = <String>[];

  @override
  Future<AppResult<Inventory>> find(String medicationId) async {
    finds++;
    return found;
  }

  @override
  Future<AppResult<Inventory>> registerInitial(
    String medicationId, {
    required int quantity,
    required int threshold,
  }) async {
    writes.add('initial $quantity/$threshold');
    return written ?? AppSuccess(stock(remaining: quantity, low: false));
  }

  @override
  Future<AppResult<Inventory>> replenish(
    String medicationId, {
    required int quantity,
    String? lot,
  }) async {
    writes.add('replenish $quantity/$lot');
    return written ??
        AppSuccess(
          stock(
            remaining: 5 + quantity,
            low: false,
            days: 35,
            replenished: true,
          ),
        );
  }
}

InventoryBloc blocFor(FakeInventory fake) => InventoryBloc(
  medicationId: medicationId,
  read: GetInventory(fake),
  registerInitial: RegisterInitialInventory(fake),
  replenish: RegisterReplenishment(fake),
);

Future<void> settle(InventoryBloc bloc) =>
    Future<void>.delayed(Duration.zero)
        .then((_) => Future<void>.delayed(Duration.zero));

void main() {
  group('input and entity', () {
    test('quantities must be whole and positive; thresholds may be zero', () {
      expect(InventoryInput.quantity(' 30 '), 30);
      expect(InventoryInput.quantity('0'), isNull);
      expect(InventoryInput.quantity('-3'), isNull);
      expect(InventoryInput.quantity('2.5'), isNull);
      expect(InventoryInput.quantity(''), isNull);
      expect(InventoryInput.threshold('0'), 0);
      expect(InventoryInput.threshold('-1'), isNull);
    });

    test('a blank lot is no lot and a long one is rejected', () {
      expect(InventoryInput.lot('  '), (valid: true, value: null));
      expect(InventoryInput.lot(' Lote 9 '), (valid: true, value: 'Lote 9'));
      expect(InventoryInput.lot('x' * 201).valid, isFalse);
    });

    test('the initial batch alone is not shown as a replenishment', () {
      expect(stock().lastReplenishment, isNull);
      final last = stock(replenished: true).lastReplenishment!;
      expect(last.id, 'batch-2');
      expect(last.lot, 'Lote 2026-09');
    });

    test('the mapper rejects malformed resources', () {
      expect(
        () => InventoryMapper.inventory({...resource(), 'remainingStock': -1}),
        throwsFormatException,
      );
      expect(
        () => InventoryMapper.inventory({...resource(), 'batches': []}),
        throwsFormatException,
      );
      expect(
        () => InventoryMapper.inventory({...resource(), 'lowStock': 'yes'}),
        throwsFormatException,
      );
      expect(
        InventoryMapper.inventory({...resource(), 'daysRemaining': null})
            .daysRemaining,
        isNull,
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

    RemoteInventoryRepository repo(int status, Object? body) {
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
      return RemoteInventoryRepository(api: InventoryApi(client), store: store);
    }

    test('reads the stock with the caregiver token', () async {
      final result = await repo(200, resource()).find(medicationId);
      expect((result as AppSuccess<Inventory>).value.remainingStock, 5);
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/v1/inventories/medication-1');
      expect(
        requests.single.headers['Authorization'],
        'Bearer caregiver-token',
      );
    });

    test('a medication without stock reports INVENTORY_NOT_FOUND', () async {
      final result = await repo(404, {
        'code': 'INVENTORY_NOT_FOUND',
        'message': 'x',
      }).find(medicationId);
      expect((result as AppFailure).code, 'INVENTORY_NOT_FOUND');
    });

    test('registers the initial stock with the documented body', () async {
      final result = await repo(
        201,
        resource(remaining: 30, low: false),
      ).registerInitial(medicationId, quantity: 30, threshold: 5);
      expect(result, isA<AppSuccess<Inventory>>());
      expect(requests.single.url.path, '/api/v1/inventories');
      expect(jsonDecode(requests.single.body), {
        'medicationId': medicationId,
        'initialQuantity': 30,
        'replenishmentThreshold': 5,
      });
    });

    test(
      'a replenishment without lot omits it and needs a new batch',
      () async {
        final replenished = resource(
          remaining: 35,
          low: false,
          batches: [
            {
              'id': 'batch-1',
              'quantity': 30,
              'registeredAt': '2026-08-01T12:00:00Z',
              'lot': null,
            },
            {
              'id': 'batch-2',
              'quantity': 30,
              'registeredAt': '2026-09-02T12:00:00Z',
              'lot': null,
            },
          ],
        );
        final result = await repo(
          201,
          replenished,
        ).replenish(medicationId, quantity: 30);
        expect(result, isA<AppSuccess<Inventory>>());
        expect(
          requests.single.url.path,
          '/api/v1/inventories/medication-1/replenishments',
        );
        expect(jsonDecode(requests.single.body), {'quantity': 30});

        final unacknowledged = await repo(
          201,
          resource(),
        ).replenish(medicationId, quantity: 30);
        expect((unacknowledged as AppFailure).code, 'INVALID_RESPONSE');
      },
    );

    test('a receipt for another medication is not trusted', () async {
      final result = await repo(
        200,
        resource(medication: 'medication-2'),
      ).find(medicationId);
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    });

    test('keeps documented conflict codes and hides unknown ones', () async {
      final inactive = await repo(409, {
        'code': 'MEDICATION_INACTIVE',
      }).registerInitial(medicationId, quantity: 30, threshold: 5);
      expect((inactive as AppFailure).code, 'MEDICATION_INACTIVE');
      final unknown = await repo(500, {
        'code': 'SQL_STATE_42',
      }).find(medicationId);
      expect((unknown as AppFailure).code, 'REQUEST_FAILED');
    });

    test('an older adult session cannot use the caregiver inventory', () async {
      store.value = StoredSession(
        accessToken: 'adult-token',
        expiresAt: DateTime.utc(2099),
        owner: SessionOwner(
          'adult-1',
          SessionRole.olderAdult,
          careLinkId: 'link-1',
        ),
      );
      final result = await repo(200, resource()).find(medicationId);
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      expect(requests, isEmpty);
    });

    test('a rejected credential is cleared', () async {
      final result = await repo(401, null).find(medicationId);
      expect((result as AppFailure).code, 'AUTHENTICATION_REQUIRED');
      expect(store.value, isNull);
    });
  });

  group('use cases', () {
    test('invalid input never reaches the server', () async {
      final fake = FakeInventory();
      expect(
        await RegisterReplenishment(fake)(medicationId, quantity: '0'),
        isA<AppFailure<Inventory>>(),
      );
      expect(
        ((await RegisterInitialInventory(fake)(
          medicationId,
          quantity: '30',
          threshold: '',
        )) as AppFailure).code,
        'INVALID_THRESHOLD',
      );
      expect(fake.writes, isEmpty);
    });
  });

  group('bloc', () {
    test('a medication without stock opens the initial form', () async {
      final fake = FakeInventory()
        ..found = const AppFailure('INVENTORY_NOT_FOUND');
      final bloc = blocFor(fake)..add(const InventoryRequested());
      await settle(bloc);
      expect(bloc.state.phase, InventoryPhase.notInitialized);

      bloc.add(const InitialStockSubmitted(quantity: '30', threshold: '5'));
      await settle(bloc);
      expect(fake.writes, ['initial 30/5']);
      expect(bloc.state.phase, InventoryPhase.ready);
      expect(bloc.state.replenished, isFalse);
      await bloc.close();
    });

    test('an invalid quantity marks the field without a request', () async {
      final fake = FakeInventory();
      final bloc = blocFor(fake)..add(const InventoryRequested());
      await settle(bloc);
      bloc.add(const ReplenishmentSubmitted(quantity: ''));
      await settle(bloc);
      expect(bloc.state.invalidField, InventoryField.quantity);
      expect(fake.writes, isEmpty);

      bloc.add(const InventoryInputChanged());
      await settle(bloc);
      expect(bloc.state.invalidField, isNull);
      await bloc.close();
    });

    test('a saved replenishment shows the server stock', () async {
      final fake = FakeInventory();
      final bloc = blocFor(fake)..add(const InventoryRequested());
      await settle(bloc);
      bloc.add(
        const ReplenishmentSubmitted(quantity: '30', lot: ' Lote 2026-09 '),
      );
      await settle(bloc);
      expect(fake.writes, ['replenish 30/Lote 2026-09']);
      expect(bloc.state.replenished, isTrue);
      expect(bloc.state.inventory!.remainingStock, 35);
      expect(bloc.state.inventory!.lowStock, isFalse);
      await bloc.close();
    });

    test('stock registered elsewhere first is reloaded', () async {
      final fake = FakeInventory()
        ..found = const AppFailure('INVENTORY_NOT_FOUND');
      final bloc = blocFor(fake)..add(const InventoryRequested());
      await settle(bloc);
      fake
        ..written = const AppFailure('INVENTORY_ALREADY_EXISTS')
        ..found = AppSuccess(stock());
      bloc.add(const InitialStockSubmitted(quantity: '30', threshold: '5'));
      await settle(bloc);
      await settle(bloc);
      expect(fake.finds, 2);
      expect(bloc.state.phase, InventoryPhase.ready);
      await bloc.close();
    });

    test('a refused write keeps the stock and reports the code', () async {
      final fake = FakeInventory()
        ..written = const AppFailure('CONCURRENT_UPDATE');
      final bloc = blocFor(fake)..add(const InventoryRequested());
      await settle(bloc);
      bloc.add(const ReplenishmentSubmitted(quantity: '10'));
      await settle(bloc);
      expect(bloc.state.phase, InventoryPhase.ready);
      expect(bloc.state.errorCode, 'CONCURRENT_UPDATE');
      expect(bloc.state.submitting, isFalse);
      await bloc.close();
    });
  });

  group('screen', () {
    Future<InventoryBloc> pump(
      WidgetTester tester,
      FakeInventory fake, {
      VoidCallback? onSessionInvalidated,
    }) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final bloc = blocFor(fake);
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: InventoryScreen(
              medicationLabel: 'Losartán · 50 mg',
              personName: 'Rosa Quispe',
              onSessionInvalidated: onSessionInvalidated ?? () {},
            ),
          ),
        ),
      );
      // Like the route: the screen listens before the first load answers.
      bloc.add(const InventoryRequested());
      await tester.pumpAndSettle();
      addTearDown(bloc.close);
      return bloc;
    }

    testWidgets('shows low stock with its coverage (563:1632)', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, FakeInventory());
      expect(find.text('Inventario'), findsOneWidget);
      expect(
        find.text('Stock inicial, disponibilidad y reposiciones de Rosa.'),
        findsOneWidget,
      );
      expect(find.text('5 unidades restantes'), findsOneWidget);
      expect(find.text('≈ 5 días de tratamiento'), findsOneWidget);
      expect(find.text('Stock bajo'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Alcanza para 5 días',
              ),
            )
            .label,
        'Alcanza para 5 días',
      );
      expect(find.text('Última reposición'), findsNothing);
      semantics.dispose();
    });

    testWidgets('marks an invalid quantity in place (563:5213)', (
      tester,
    ) async {
      final fake = FakeInventory();
      await pump(tester, fake);
      await tester.tap(find.byKey(const Key('save-replenishment')));
      await tester.pumpAndSettle();
      expect(find.text('Cantidad inválida'), findsOneWidget);
      expect(
        find.text('Ingresa una cantidad mayor que cero antes de guardar.'),
        findsOneWidget,
      );
      expect(fake.writes, isEmpty);
    });

    testWidgets('a restock updates the stock and the last receipt (563:5284)', (
      tester,
    ) async {
      final fake = FakeInventory();
      await pump(tester, fake);
      await tester.enterText(find.byType(TextField).first, '30');
      await tester.enterText(find.byType(TextField).last, 'Lote 2026-09');
      await tester.tap(find.byKey(const Key('save-replenishment')));
      await tester.pumpAndSettle();
      expect(fake.writes, ['replenish 30/Lote 2026-09']);
      expect(find.text('35 unidades restantes'), findsOneWidget);
      expect(find.text('Stock disponible'), findsOneWidget);
      expect(find.text('Reposición registrada.'), findsOneWidget);
      expect(find.text('Última reposición'), findsOneWidget);
      expect(find.text('30 unidades, Lote 2026-09'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
    });

    testWidgets('offers the initial form when there is no stock', (
      tester,
    ) async {
      final fake = FakeInventory()
        ..found = const AppFailure('INVENTORY_NOT_FOUND');
      await pump(tester, fake);
      expect(find.text('Cantidad inicial'), findsOneWidget);
      expect(find.text('Umbral de reposición'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '30');
      await tester.enterText(find.byType(TextField).last, '5');
      await tester.tap(find.byKey(const Key('save-initial-stock')));
      await tester.pumpAndSettle();
      expect(fake.writes, ['initial 30/5']);
      expect(find.text('30 unidades restantes'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
    });

    testWidgets('an ended session goes back to the host', (tester) async {
      var invalidated = 0;
      final fake = FakeInventory()
        ..found = const AppFailure('AUTHENTICATION_REQUIRED');
      await pump(tester, fake, onSessionInvalidated: () => invalidated++);
      expect(invalidated, 1);
    });
  });

  group('entry from the caregiver medications', () {
    Future<void> pump(
      WidgetTester tester, {
      void Function(Medication medication)? onOpenInventory,
    }) async {
      final backend = FakeBackend();
      final bloc = MedicationManagementBloc(
        list: ListMedications(backend),
        update: UpdateMedication(backend),
        deactivate: DeactivateMedication(backend),
        reactivate: ReactivateMedication(backend),
        olderAdultId: 'adult-A',
      )..add(const MedicationsRequested());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: MedicationManagementScreen(
              onRegister: () {},
              onCreateTreatment: (_) {},
              onSessionInvalidated: () {},
              onOpenInventory: onOpenInventory,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('each medication opens its own inventory', (tester) async {
      final opened = <String>[];
      await pump(
        tester,
        onOpenInventory: (medication) => opened.add(medication.id),
      );
      await tester.tap(find.text('Inventario'));
      expect(opened, ['med-1']);
    });

    testWidgets('without a host the action is not offered', (tester) async {
      await pump(tester);
      expect(find.text('Inventario'), findsNothing);
    });
  });
}
