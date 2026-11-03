import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/application/ports/pin_access.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_pin.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in_with_pin.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/value_objects/pin_code.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/pin/pin_bloc.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/pin/pin_event.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/pin/pin_state.dart';
import 'package:tata/features/identity_subscription/presentation/navigation/pin_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

/// Records submitted PINs and answers with a configurable result.
final class FakePinAccess implements PinAccess {
  FakePinAccess({this.registerResult, this.signInResult});

  AppResult<void>? registerResult;
  AppResult<AccountSession>? signInResult;
  final submitted = <String>[];

  @override
  Future<AppResult<void>> register(PinCode pin) async {
    submitted.add(pin.value);
    return registerResult ?? const AppSuccess(null);
  }

  @override
  Future<AppResult<AccountSession>> signIn(
    String olderAdultId,
    PinCode pin,
  ) async {
    submitted.add('$olderAdultId:${pin.value}');
    return signInResult ??
        AppSuccess(
          AccountSession(
            owner: SessionOwner(
              olderAdultId,
              SessionRole.olderAdult,
              careLinkId: 'link-A',
            ),
            expiresAt: DateTime.utc(2030),
          ),
        );
  }
}

void main() {
  PinBloc access(FakePinAccess fake) =>
      PinBloc.access(signIn: SignInWithPin(fake), olderAdultId: 'adult-A');
  PinBloc setup(FakePinAccess fake) =>
      PinBloc.setup(register: RegisterPin(fake));

  group('PinBloc', () {
    blocTest<PinBloc, PinState>(
      'exposes only the digit count and caps input at four digits',
      build: () => access(FakePinAccess()),
      act: (bloc) => bloc
        ..add(const PinDigitPressed('1'))
        ..add(const PinDigitPressed('x'))
        ..add(const PinDigitPressed('2'))
        ..add(const PinDeletePressed())
        ..add(const PinDigitPressed('3'))
        ..add(const PinDigitPressed('4'))
        ..add(const PinDigitPressed('5'))
        ..add(const PinDigitPressed('6')),
      verify: (bloc) {
        expect(bloc.state.length, 4);
        expect(bloc.state.canSubmit, isTrue);
      },
    );

    test('submits once, clears digits and completes on success', () async {
      final fake = FakePinAccess();
      final bloc = access(fake);
      for (final digit in ['2', '4', '6', '8']) {
        bloc.add(PinDigitPressed(digit));
      }
      bloc
        ..add(const PinSubmitted())
        ..add(const PinSubmitted());
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PinState>().having(
            (s) => s.status,
            'status',
            PinStatus.completed,
          ),
        ),
      );
      expect(fake.submitted, ['adult-A:2468']);
      expect(bloc.state.length, 0);
      await bloc.close();
    });

    test('a locked PIN blocks further input', () async {
      final bloc = access(
        FakePinAccess(signInResult: const AppFailure('PIN_LOCKED')),
      );
      for (final digit in ['1', '1', '1', '1']) {
        bloc.add(PinDigitPressed(digit));
      }
      bloc.add(const PinSubmitted());
      await expectLater(
        bloc.stream,
        emitsThrough(isA<PinState>().having((s) => s.locked, 'locked', true)),
      );
      bloc.add(const PinDigitPressed('1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.length, 0);
      expect(bloc.state.canEdit, isFalse);
      await bloc.close();
    });

    test('setup treats an existing enrollment as completed', () async {
      final bloc = setup(
        FakePinAccess(
          registerResult: const AppFailure('PIN_ALREADY_REGISTERED'),
        ),
      );
      for (final digit in ['1', '3', '5', '7']) {
        bloc.add(PinDigitPressed(digit));
      }
      bloc.add(const PinSubmitted());
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<PinState>().having(
            (s) => s.status,
            'status',
            PinStatus.completed,
          ),
        ),
      );
      await bloc.close();
    });
  });

  group('PinRoute', () {
    setUpAll(loadTataFonts);
    // Figma's 393x883 phone frame keeps the whole keypad on screen.
    void phone(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(1179, 2649)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Widget host(Widget child) => RepaintBoundary(
      key: const Key('pin-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

    testWidgets('keypad enters digits, hides them and signs in', (
      tester,
    ) async {
      phone(tester);
      final fake = FakePinAccess();
      var completed = 0;
      await tester.pumpWidget(
        host(
          PinRoute(
            createBloc: () => access(fake),
            adultName: 'Ana Pérez',
            onCompleted: () => completed++,
            onBack: () {},
          ),
        ),
      );
      expect(find.text('Ingresa a Tata'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('AP'), findsOneWidget);
      final submit = find.widgetWithText(ElevatedButton, 'Ingresar');
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

      for (final digit in ['9', '7', '5', '3']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await captureWidget(
        tester,
        find.byKey(const Key('pin-capture')),
        'pin_access',
      );
      expect(find.byKey(const ValueKey('pin-dot-filled')), findsNWidgets(4));
      expect(find.text('9'), findsOneWidget, reason: 'only the keypad label');

      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(fake.submitted, ['adult-A:9753']);
      expect(completed, 1);
    });

    testWidgets('setup explains the enrollment before saving', (tester) async {
      phone(tester);
      final fake = FakePinAccess();
      var completed = 0;
      await tester.pumpWidget(
        host(
          PinRoute(
            createBloc: () => setup(fake),
            adultName: 'Rosa Vargas',
            onCompleted: () => completed++,
          ),
        ),
      );
      expect(find.text('Crea tu PIN'), findsOneWidget);
      expect(find.text('Configura tu acceso'), findsOneWidget);
      expect(find.text('Volver'), findsNothing);
      await captureWidget(
        tester,
        find.byKey(const Key('pin-capture')),
        'pin_setup',
      );
      for (final digit in ['1', '3', '5', '7']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar PIN'));
      await tester.pumpAndSettle();
      expect(fake.submitted, ['1357']);
      expect(completed, 1);
    });

    testWidgets('incorrect and locked PINs show their Figma messages', (
      tester,
    ) async {
      phone(tester);
      final fake = FakePinAccess(signInResult: const AppFailure('INVALID_PIN'));
      await tester.pumpWidget(
        host(
          PinRoute(
            createBloc: () => access(fake),
            adultName: null,
            onCompleted: () {},
            onBack: () {},
          ),
        ),
      );
      Future<void> enter() async {
        for (final digit in ['1', '2', '3', '4']) {
          await tester.tap(find.text(digit));
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(ElevatedButton, 'Ingresar'));
        await tester.pumpAndSettle();
      }

      await enter();
      expect(find.text('PIN incorrecto'), findsOneWidget);
      await captureWidget(
        tester,
        find.byKey(const Key('pin-capture')),
        'pin_incorrect',
      );

      fake.signInResult = const AppFailure('PIN_LOCKED');
      await enter();
      expect(find.text('Acceso temporalmente bloqueado'), findsOneWidget);
      expect(find.text('Intenta más tarde'), findsOneWidget);
    });
  });
}
