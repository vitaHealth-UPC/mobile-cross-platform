import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../support/visual_capture.dart';

void main() {
  setUpAll(loadTataFonts);

  Future<void> pumpBar(
    WidgetTester tester, {
    double bottomInset = 0,
    CaregiverTab selected = CaregiverTab.home,
    ValueChanged<CaregiverTab>? onSelected,
  }) async {
    tester.view
      ..physicalSize = const Size(1179, 2649)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 883),
          padding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: CaregiverTabBar(
              selected: selected,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The outermost decorated box is the rounded white bar, without its margin.
  Finder barBox() => find
      .descendant(
        of: find.byType(CaregiverTabBar),
        matching: find.byType(DecoratedBox),
      )
      .first;

  double gapBelowBar(WidgetTester tester) =>
      883 - tester.getBottomLeft(barBox()).dy;

  testWidgets('keeps the Figma size: 365 wide, 68 tall, 16 above the bottom', (
    tester,
  ) async {
    await pumpBar(tester);

    expect(tester.getSize(barBox()).width, closeTo(365, 0.1));
    expect(tester.getSize(barBox()).height, closeTo(68, 0.1));
    expect(tester.getTopLeft(barBox()).dx, closeTo(14, 0.1));
    expect(gapBelowBar(tester), closeTo(16, 0.1));
  });

  testWidgets('on gesture navigation it stays above the system inset', (
    tester,
  ) async {
    await pumpBar(tester, bottomInset: 24);

    expect(gapBelowBar(tester), closeTo(24, 0.1));
  });

  testWidgets('a small inset never pulls it below the 16 px of the design', (
    tester,
  ) async {
    await pumpBar(tester, bottomInset: 6);

    expect(gapBelowBar(tester), closeTo(16, 0.1));
  });

  testWidgets('reports the tapped tab and marks only the selected one', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    CaregiverTab? tapped;
    await pumpBar(tester, onSelected: (tab) => tapped = tab);

    for (final (label, tab) in [
      ('Alertas', CaregiverTab.alerts),
      ('Notas', CaregiverTab.notes),
      ('Persona', CaregiverTab.person),
      ('Más', CaregiverTab.more),
      ('Inicio', CaregiverTab.home),
    ]) {
      await tester.tap(find.text(label));
      expect(tapped, tab, reason: label);
    }
    // A screen reader must be able to activate every tab, and only the
    // current one is announced as selected.
    for (final (label, selected) in [
      ('Inicio', true),
      ('Alertas', false),
      ('Notas', false),
      ('Persona', false),
      ('Más', false),
    ]) {
      final data = tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData();
      // Flags are reported as booleans or as tri-state values by version.
      bool on(Object? flag) => flag == true || flag == Tristate.isTrue;
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      expect(on(data.flagsCollection.isButton), isTrue, reason: label);
      expect(on(data.flagsCollection.isSelected), selected, reason: label);
    }
    handle.dispose();
  });

  testWidgets('every tab is at least 44 px wide and tall to tap', (
    tester,
  ) async {
    await pumpBar(tester);

    for (final label in ['Inicio', 'Alertas', 'Notas', 'Persona', 'Más']) {
      final size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      expect(size.width, greaterThanOrEqualTo(44), reason: label);
      expect(size.height, greaterThanOrEqualTo(44), reason: label);
    }
  });
}
