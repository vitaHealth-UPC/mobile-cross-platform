import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/identity_subscription/presentation/screens/landing_value_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

/// Product information stays native, localized and separate from account data.
void main() {
  setUpAll(loadTataFonts);
  for (final locale in ['es', 'en']) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('landing $locale remains actionable at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 852)
            : const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var starts = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: TataTheme.light,
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(
                key: const Key('landing-capture'),
                child: child!,
              ),
            ),
            home: LandingValueScreen(onStart: () => starts++),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/illustrations/landing_testimonial.png'),
            tester.element(find.byType(LandingValueScreen)),
          ),
        );
        await tester.pumpAndSettle();
        final start = find.byType(ElevatedButton);
        await tester.ensureVisible(start);
        await tester.pumpAndSettle();
        await tester.tap(start);
        expect(starts, 1);
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('landing-capture')),
          'landing-$locale-$scale-top',
        );
        await tester.ensureVisible(find.text('2 roles'));
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('landing-capture')),
          'landing-$locale-$scale-bottom',
        );
        expect(
          find.text(locale == 'es' ? 'Funciones principales' : 'Key features'),
          findsOneWidget,
        );
        expect(
          find.text(locale == 'es' ? 'Familia' : 'Family'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
