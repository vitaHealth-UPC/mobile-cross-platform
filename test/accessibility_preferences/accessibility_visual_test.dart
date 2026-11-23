import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/accessibility_preferences.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/screens/accessibility_screen.dart';
import 'package:tata/features/accessibility_preferences/presentation/theme/appearance.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/widgets/adult_navigation_bar.dart';

import '../support/visual_capture.dart';
import 'preferences_presentation_test.dart'
    show accessibilityBloc, MemoryLanguage;
import 'preferences_repository_test.dart' show FakeRemote, MemoryLocal;

void main() {
  setUpAll(loadTataFonts);
  final variants = {
    'default': AccessibilityPreferences.defaults,
    'dark': const AccessibilityPreferences(darkTheme: true),
    'contrast': const AccessibilityPreferences(highContrast: true),
    'large_text': const AccessibilityPreferences(
      textSize: TextSizeLevel.extraLarge,
    ),
    'reduced_motion': const AccessibilityPreferences(reducedMotion: true),
    'reading': const AccessibilityPreferences(readingAssistance: true),
  };
  for (final variant in variants.entries) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'accessibility ${variant.key} adapts at system text scale $scale',
        (tester) async {
          final prefs = variant.value;
          tester.view.physicalSize = scale == 1
              ? const Size(393, 883)
              : const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final remote = FakeRemote()..server = prefs;
          final local = MemoryLocal()..values['user-A'] = prefs;
          final bloc = accessibilityBloc(
            OfflineFirstUserPreferences(remote: remote, local: local),
            MemoryLanguage(),
          )..add(const AccessibilityStarted());
          await tester.pumpWidget(
            MaterialApp(
              theme: Appearance.themeFor(prefs),
              locale: const Locale('es'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: Builder(
                  builder: (inner) => Appearance.wrap(
                    inner,
                    prefs,
                    RepaintBoundary(
                      key: const Key('accessibility-capture'),
                      child: child!,
                    ),
                  ),
                ),
              ),
              home: BlocProvider(
                create: (_) => bloc,
                child: const AccessibilityScreen(
                  navigationBar: AdultNavigationBar(
                    selected: AdultDestination.more,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            MediaQuery.of(tester.element(find.byType(AccessibilityScreen)))
                .highContrast,
            prefs.highContrast,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'Native controls and groups must not overflow',
          );
          await captureWidget(
            tester,
            find.byKey(const Key('accessibility-capture')),
            'accessibility_${variant.key}_${scale == 1 ? 'normal' : 'large'}',
          );
          await tester.scrollUntilVisible(
            find.widgetWithText(ListTile, 'Idioma'),
            250,
          );
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(ListTile, 'Idioma').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
