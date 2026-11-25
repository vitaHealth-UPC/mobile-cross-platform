import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/accessibility_preferences/application/usecases/observe_accessibility.dart';
import 'package:tata/features/accessibility_preferences/application/usecases/observe_application_language.dart';
import 'package:tata/features/accessibility_preferences/application/usecases/sync_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/accessibility_preferences.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/cubit/appearance_cubit.dart';
import 'package:tata/features/accessibility_preferences/presentation/screens/accessibility_screen.dart';
import 'package:tata/features/accessibility_preferences/presentation/theme/appearance.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/widgets/adult_navigation_bar.dart';

import '../support/visual_capture.dart';
import 'preferences_presentation_test.dart'
    show accessibilityBloc, MemoryLanguage;
import 'preferences_repository_test.dart' show FakeRemote, MemoryLocal;

/// Uses the real preference observers to rebuild both controls and navigation.
void main() {
  setUpAll(loadTataFonts);
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'Spanish is initial and language selection persists at $scale',
      (tester) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 883)
            : const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final language = MemoryLanguage();
        final repository = OfflineFirstUserPreferences(
          remote: FakeRemote(),
          local: MemoryLocal(),
        );
        final appearance = AppearanceCubit(
          observeAccessibility: ObserveAccessibility(repository),
          observeLanguage: ObserveApplicationLanguage(language),
          sync: SyncUserPreferences(repository),
        )..bindOwner('user-A');
        addTearDown(appearance.close);
        final bloc = accessibilityBloc(repository, language)
          ..add(const AccessibilityStarted());
        await tester.pumpWidget(
          BlocBuilder<AppearanceCubit, AppearanceState>(
            bloc: appearance,
            builder: (context, state) => MaterialApp(
              theme: Appearance.themeFor(state.accessibility),
              locale: Appearance.localeFor(state.language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: const Key('language-capture'),
                  child: child!,
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
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Accesibilidad'), findsOneWidget);
        final selector = find.byKey(const Key('language-selector'));
        await tester.scrollUntilVisible(selector, 250);
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('language-capture')),
          'language-es-$scale',
        );
        await tester.tap(selector);
        await tester.pumpAndSettle();
        expect(language.values['user-A'], AppLanguage.english);
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Application language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('More'), findsOneWidget);
        await tester.scrollUntilVisible(selector, 250);
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('language-capture')),
          'language-en-$scale-bottom',
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(find.text('Accessibility'), findsOneWidget);
        expect(find.text('Text size'), findsOneWidget);
        await captureWidget(
          tester,
          find.byKey(const Key('language-capture')),
          'language-en-$scale-top',
        );
        await tester.scrollUntilVisible(selector, 250);
        await tester.pumpAndSettle();
        await tester.tap(selector);
        await tester.pumpAndSettle();
        expect(language.values['user-A'], AppLanguage.spanish);
        expect(find.text('Idioma'), findsOneWidget);
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(find.text('Accesibilidad'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
