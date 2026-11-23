import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/onboarding_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'onboarding has distinct actions and readable layout at scale $scale',
      (tester) async {
        final previousShadows = debugDisableShadows;
        debugDisableShadows = false;
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await loadTataFonts();
        var starts = 0;
        var signIns = 0;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TataTheme.light,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: const Key('onboarding-capture'),
              child: OnboardingScreen(
                onStart: () => starts++,
                onSignIn: () => signIns++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(OnboardingScreen));
          for (final asset in [
            'onboarding_sun',
            'onboarding_heart',
            'onboarding_botanical',
          ]) {
            await precacheImage(
              AssetImage('assets/illustrations/$asset.png'),
              context,
            );
          }
        });
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('onboarding-capture')),
          'onboarding-es-$scale',
        );
        await tester.ensureVisible(find.text('Comenzar'));
        await tester.tap(find.text('Comenzar'));
        await tester.ensureVisible(find.text('Iniciar sesión'));
        await tester.tap(find.text('Iniciar sesión'));
        expect(starts, 1);
        expect(signIns, 1);
        debugDisableShadows = previousShadows;
        expect(tester.takeException(), isNull);
      },
    );
  }
}
