import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/login_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final weight in ['regular', 'medium', 'semibold', 'bold']) {
    inter.addFont(rootBundle.load('assets/fonts/inter_$weight.ttf'));
  }
  await inter.load();
  await (FontLoader(
    'DMSerifDisplay',
  )..addFont(rootBundle.load('assets/fonts/dm_serif_display.ttf'))).load();
}

void main() {
  Widget host(
    Widget child, {
    double scale = 1,
    Locale locale = const Locale('es'),
  }) => RepaintBoundary(
    key: const Key('login-capture'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TataTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    ),
  );

  testWidgets(
    'native form validates input and dispatches distinct actions without preset credentials',
    (tester) async {
      final actions = <String>[];
      String? submittedEmail;
      String? submittedPassword;
      await tester.pumpWidget(
        host(
          LoginScreen(
            onSignIn: (email, password) {
              submittedEmail = email;
              submittedPassword = password;
            },
            onRecover: () => actions.add('recovery'),
            onRegister: () => actions.add('registration'),
            onGoogle: () => actions.add('google'),
            onFacebook: () => actions.add('facebook'),
          ),
        ),
      );
      expect(find.text('diego@email.com'), findsNothing);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(submittedEmail, isNull);
      expect(
        find.text('Ingresa un correo electrónico válido.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        ' USER@example.com ',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        ' password ',
      );
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(submittedEmail, ' USER@example.com ');
      expect(submittedPassword, ' password ');
      for (final label in [
        '¿Olvidaste tu contraseña?',
        'Continuar con Google',
        'Continuar con Facebook',
        'Crear cuenta',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(actions, ['recovery', 'google', 'facebook', 'registration']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Figma-equivalent state uses local assets and real fonts; large text remains scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _loadFonts();
      Widget screen() => LoginScreen(
        onSignIn: (_, _) {},
        onRecover: () {},
        onRegister: () {},
        onGoogle: () {},
        onFacebook: () {},
      );
      await tester.pumpWidget(host(screen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'diego@email.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        '12345678',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final directory = Platform.environment['TATA_CAPTURE_DIR'];
      if (directory != null) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('login-capture')),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File('$directory/login-es.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(host(screen(), scale: 1.5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear cuenta'));
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English is an explicit locale and busy blocks interactions', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        LoginScreen(
          busy: true,
          onSignIn: (_, _) => calls++,
          onRecover: () => calls++,
          onRegister: () => calls++,
          onGoogle: () => calls++,
          onFacebook: () => calls++,
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    expect(find.text('Access your account to continue.'), findsOneWidget);
    final buttons = tester.widgetList<ButtonStyleButton>(
      find.byType(ElevatedButton),
    );
    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(calls, 0);
  });
}
