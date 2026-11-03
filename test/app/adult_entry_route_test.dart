import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/adult_entry_route.dart';
import 'package:tata/features/identity_subscription/application/readmodels/remembered_adult.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_pin.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/pin/pin_bloc.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_bloc.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../identity_subscription/pin_flow_test.dart' show FakePinAccess;
import '../intake_execution/adult_home_test.dart' show FakeIntakeReader;

void main() {
  late List<RememberedAdult> remembered;
  late int nameReads;

  Future<void> pumpEntry(
    WidgetTester tester, {
    RememberedAdult? stored,
    FakePinAccess? pins,
  }) async {
    tester.view
      ..physicalSize = const Size(1179, 2649)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final reader = FakeIntakeReader(
      nextResult: const AppSuccess(null),
      agendaResult: const AppSuccess([]),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdultEntryRoute(
          olderAdultId: 'adult-A',
          readRemembered: () async => stored,
          remember: (adult) async => remembered.add(adult),
          forget: () async {},
          readAdultName: () async {
            nameReads++;
            return 'Rosa Vargas';
          },
          createPinSetupBloc: () =>
              PinBloc.setup(register: RegisterPin(pins ?? FakePinAccess())),
          createHomeBloc: () => HomeBloc(
            next: GetNextIntake(reader),
            progress: GetDailyProgress(reader, DateTime.now),
          ),
          createConsentBloc: () => throw UnimplementedError(),
          onSignOut: () {},
          onSessionChanged: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    remembered = [];
    nameReads = 0;
  });

  testWidgets('a new adult enrolls a PIN, is remembered and reaches home', (
    tester,
  ) async {
    final pins = FakePinAccess();
    await pumpEntry(tester, pins: pins);
    expect(find.text('Crea tu PIN'), findsOneWidget);
    expect(find.text('Rosa Vargas'), findsOneWidget);

    for (final digit in ['2', '4', '6', '8']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar PIN'));
    await tester.pumpAndSettle();

    expect(pins.submitted, ['2468']);
    expect(remembered.single.id, 'adult-A');
    expect(remembered.single.name, 'Rosa Vargas');
    expect(find.text('Hoy'), findsOneWidget);
  });

  testWidgets('a remembered adult goes straight home without a profile read', (
    tester,
  ) async {
    await pumpEntry(
      tester,
      stored: RememberedAdult(id: 'adult-A', name: 'Rosa Vargas'),
    );
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('RV'), findsOneWidget);
    expect(nameReads, 0);
    expect(remembered, isEmpty);
  });

  testWidgets('another remembered adult does not skip enrollment', (
    tester,
  ) async {
    await pumpEntry(
      tester,
      stored: RememberedAdult(id: 'adult-B', name: 'Otra Persona'),
    );
    expect(find.text('Crea tu PIN'), findsOneWidget);
    expect(find.text('Rosa Vargas'), findsOneWidget);
  });
}
