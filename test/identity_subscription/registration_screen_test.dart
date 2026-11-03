import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/caregiver_registration_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

void main() {
  testWidgets(
    'registration uses editable fields, clears password after receipt and submits entered code',
    (tester) async {
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final inter = FontLoader('Inter');
      for (final weight in ['regular', 'medium', 'semibold', 'bold']) {
        inter.addFont(rootBundle.load('assets/fonts/inter_$weight.ttf'));
      }
      await inter.load();
      await (FontLoader(
        'DMSerifDisplay',
      )..addFont(rootBundle.load('assets/fonts/dm_serif_display.ttf'))).load();
      var pending = false;
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
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: 24, bottom: 24)),
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return CaregiverRegistrationScreen(
                  hasAccount: pending,
                  onRegister: (name, email, value) {
                    password = value;
                  },
                  onVerify: (value) => code = value,
                  onResend: () {},
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('registration-code')), findsNothing);
      expect(find.text('Diego Mendoza'), findsNothing);
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
      await tester.tap(find.text('Verificar correo'));
      await tester.pumpAndSettle();
      expect(code, '482196');
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      final output = Platform.environment['TATA_CAPTURE_DIR'];
      if (output != null) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('registration-capture')),
          );
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/registration-es.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      debugDisableShadows = previousShadows;
      expect(tester.takeException(), isNull);
    },
  );
}
