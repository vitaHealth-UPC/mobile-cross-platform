import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/caregiver_registration_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_colors.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/status_notice.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool hasAccount = false,
    String? title,
    String? body,
    bool expired = false,
    bool resent = false,
    VoidCallback? onResend,
    ValueChanged<String>? onVerify,
  }) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CaregiverRegistrationScreen(
          hasAccount: hasAccount,
          errorTitle: title,
          errorText: body,
          codeExpired: expired,
          resent: resent,
          onRegister: (_, _, _) {},
          onVerify: onVerify ?? (_) {},
          onResend: onResend ?? () {},
        ),
      ),
    );
  }

  Color surfaceOf(WidgetTester tester) {
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(StatusNotice),
        matching: find.byType(Container),
      ),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('a duplicate email is a named error notice (Figma 563:2162)', (
    tester,
  ) async {
    await pump(
      tester,
      title: 'Correo ya registrado',
      body: 'Utiliza otro correo o inicia sesión con la cuenta existente.',
    );
    expect(find.text('Correo ya registrado'), findsOneWidget);
    expect(
      find.text('Utiliza otro correo o inicia sesión con la cuenta existente.'),
      findsOneWidget,
    );
    expect(surfaceOf(tester), TataColors.errorSurface);
    final semantics = tester.getSemantics(find.byType(StatusNotice));
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('an expired code asks for a new one instead of verifying', (
    tester,
  ) async {
    var resends = 0;
    final verified = <String>[];
    await pump(
      tester,
      hasAccount: true,
      title: 'Verificación vencida',
      body: 'Solicita un nuevo código para habilitar la cuenta.',
      expired: true,
      onResend: () => resends++,
      onVerify: verified.add,
    );
    expect(find.text('Verificación vencida'), findsOneWidget);
    expect(surfaceOf(tester), isNot(TataColors.errorSurface));
    expect(find.text('Verificar correo'), findsNothing);
    expect(find.text('Reenviar código'), findsNothing);
    await tester.ensureVisible(find.text('Solicitar nuevo código'));
    await tester.tap(find.text('Solicitar nuevo código'));
    expect(resends, 1);
    expect(verified, isEmpty);
  });

  testWidgets('a resent code is a plain confirmation, not a notice', (
    tester,
  ) async {
    await pump(tester, hasAccount: true, resent: true);
    expect(find.byType(StatusNotice), findsNothing);
    expect(find.text('Verificar correo'), findsOneWidget);
    expect(find.text('Reenviar código'), findsOneWidget);
  });
}
