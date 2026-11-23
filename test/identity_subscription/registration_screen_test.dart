import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/caregiver_registration_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'registration clears password and recovers expired verification at $scale',
      (tester) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 852)
            : const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await loadTataFonts();
        var pending = false;
        var expired = false;
        var resent = false;
        var resends = 0;
        String? password;
        String? code;
        late StateSetter update;
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('registration-capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: TataTheme.light,
              locale: const Locale('es'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return CaregiverRegistrationScreen(
                    hasAccount: pending,
                    codeExpired: expired,
                    resent: resent,
                    errorTitle: expired ? 'Verificación vencida' : null,
                    errorText: expired
                        ? 'Solicita un nuevo código para habilitar la cuenta.'
                        : null,
                    onRegister: (name, email, value) {
                      password = value;
                    },
                    onVerify: (value) => code = value,
                    onResend: () => resends++,
                  );
                },
              ),
            ),
          ),
        );
        expect(find.byKey(const Key('registration-code')), findsNothing);
        expect(find.text('Diego Mendoza'), findsNothing);
        await tester.ensureVisible(find.text('Crear cuenta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear cuenta'));
        await tester.pumpAndSettle();
        expect(password, isNull);
        await tester.enterText(
          find.byKey(const Key('registration-name')),
          'Diego Mendoza',
        );
        await tester.enterText(
          find.byKey(const Key('registration-email')),
          'diego@email.com',
        );
        await tester.enterText(
          find.byKey(const Key('registration-password')),
          'password',
        );
        await tester.ensureVisible(find.text('Crear cuenta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crear cuenta'));
        await tester.pumpAndSettle();
        expect(password, 'password');
        update(() => pending = true);
        await tester.pumpAndSettle();
        final passwordField = tester.widget<TextFormField>(
          find.byKey(const Key('registration-password')),
        );
        expect(passwordField.controller!.text, isEmpty);
        await tester.enterText(
          find.byKey(const Key('registration-code')),
          '482196',
        );
        await tester.ensureVisible(find.text('Verificar correo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Verificar correo'));
        await tester.pumpAndSettle();
        expect(code, '482196');
        final scrollable = find.byType(Scrollable).first;
        tester.state<ScrollableState>(scrollable).position.jumpTo(0);
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('registration-capture')),
          'registration-$scale',
        );
        await tester.ensureVisible(find.text('Verificar correo'));
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('registration-capture')),
          'registration-$scale-bottom',
        );
        update(() => expired = true);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('registration-code')))
              .enabled,
          isFalse,
        );
        await tester.ensureVisible(find.text('Verificación vencida'));
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('registration-capture')),
          'registration-expired-$scale',
        );
        await tester.ensureVisible(find.text('Solicitar nuevo código'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Solicitar nuevo código'));
        expect(resends, 1);
        expect(code, '482196');
        update(() {
          expired = false;
          resent = true;
        });
        await tester.pumpAndSettle();
        final renewed = tester.widget<TextField>(
          find.byKey(const Key('registration-code')),
        );
        expect(renewed.enabled, isTrue);
        expect(renewed.controller!.text, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
