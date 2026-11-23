import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

void main() {
  testWidgets(
    'caregiver bar tints the selected icon and disables unconnected destinations',
    (tester) async {
      final selected = <CaregiverTab>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            bottomNavigationBar: CaregiverTabBar(
              selected: CaregiverTab.person,
              enabledTabs: const {CaregiverTab.home, CaregiverTab.person},
              onSelected: selected.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final icons = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .toList();
      expect(icons, hasLength(5));
      expect(
        icons[3].colorFilter,
        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
      await tester.tap(find.text('Notas'));
      await tester.pump();
      expect(selected, isEmpty);
      await tester.tap(find.text('Persona'));
      await tester.pump();
      expect(selected, [CaregiverTab.person]);
    },
  );
}
