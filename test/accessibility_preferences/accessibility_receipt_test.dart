import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/accessibility_preferences/application/readmodels/accessibility_change.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_state.dart';
import 'package:tata/features/accessibility_preferences/presentation/screens/accessibility_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/adult_navigation_bar.dart';

import '../support/visual_capture.dart';
import 'preferences_presentation_test.dart'
    show accessibilityBloc, MemoryLanguage, settle;
import 'preferences_repository_test.dart' show FakeRemote, MemoryLocal;

/// Initial synchronization and offline edits must not impersonate a server receipt.
void main() {
  setUpAll(loadTataFonts);
  for (final scale in [1.0, 1.5]) {
    testWidgets('saved accessibility receipt remains readable at $scale', (
      tester,
    ) async {
      tester.view.physicalSize = scale == 1
          ? const Size(393, 883)
          : const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final remote = FakeRemote();
      final bloc = accessibilityBloc(
        OfflineFirstUserPreferences(remote: remote, local: MemoryLocal()),
        MemoryLanguage(),
      )..add(const AccessibilityStarted());
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(
              key: const Key('accessibility-receipt-capture'),
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
      );
      await tester.pumpAndSettle();
      expect(find.text('Preferencia guardada'), findsNothing);
      final toggle = find.widgetWithText(SwitchListTile, 'Reducir movimiento');
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(remote.server.reducedMotion, isTrue);
      expect(find.text('Preferencia guardada').hitTestable(), findsOneWidget);
      expect(find.textContaining('Reducir movimiento:'), findsOneWidget);
      await captureWidget(
        tester,
        find.byKey(const Key('accessibility-receipt-capture')),
        'accessibility-receipt-$scale',
      );
      remote.failure = 'NETWORK_UNAVAILABLE';
      bloc.add(const AccessibilityChanged(ReducedMotionChange(false)));
      await tester.pumpAndSettle();
      expect(find.text('Preferencia guardada'), findsNothing);
      expect(bloc.state.sync, AccessibilitySyncStatus.pending);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  test('only an acknowledged edit identifies the saved preference', () async {
    final remote = FakeRemote();
    final bloc = accessibilityBloc(
      OfflineFirstUserPreferences(remote: remote, local: MemoryLocal()),
      MemoryLanguage(),
    )..add(const AccessibilityStarted());
    addTearDown(bloc.close);
    await settle();
    expect(bloc.state.receipt, isNull);
    bloc.add(const AccessibilityChanged(HighContrastChange(true)));
    await settle();
    expect(bloc.state.accessibility.highContrast, isTrue);
    expect(bloc.state.receipt, AccessibilityField.highContrast);
    expect(bloc.state.sync, AccessibilitySyncStatus.synced);

    remote.failure = 'NETWORK_UNAVAILABLE';
    bloc.add(const AccessibilityChanged(ReducedMotionChange(true)));
    await settle();
    expect(bloc.state.accessibility.reducedMotion, isTrue);
    expect(bloc.state.sync, AccessibilitySyncStatus.pending);
    expect(bloc.state.receipt, isNull);
  });
}
