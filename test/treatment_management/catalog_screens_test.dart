import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/infrastructure/mappers/treatment_mapper.dart';
import 'package:tata/features/treatment_management/presentation/bloc/my_medications/my_medications_bloc.dart';
import 'package:tata/features/treatment_management/presentation/screens/medication_catalog_screen.dart';
import 'package:tata/features/treatment_management/presentation/screens/medication_details_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/adult_navigation_bar.dart';

import '../support/visual_capture.dart';
import 'catalog_fixtures.dart';

void main() {
  setUpAll(loadTataFonts);
  final items = TreatmentMapper.myMedications([
    for (var i = 1; i <= 5; i++) catalogJson(id: 'med-$i'),
  ], ownerId: 'adult-A');
  final next = MedicationNextDose(
    medicationId: 'med-1',
    medicationName: 'Losartán 50 mg',
    intakeId: 'intake-real',
    scheduledAt: DateTime(2026, 11, 11, 8).toUtc(),
  );
  const bar = AdultNavigationBar(selected: AdultDestination.medications);
  for (final scale in [1.0, 1.5]) {
    for (final detail in [false, true]) {
      testWidgets(
        '${detail ? 'detail' : 'catalog'} adapts at text scale $scale and opens real dose',
        (tester) async {
          tester.view.physicalSize = scale == 1
              ? const Size(393, 883)
              : const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? opened;
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
                  key: const Key('catalog-capture'),
                  child: child!,
                ),
              ),
              home: detail
                  ? MedicationDetailsScreen(
                      item: items.first,
                      next: next,
                      onDose: (id) => opened = id,
                      navigationBar: bar,
                      onBack: () {},
                    )
                  : MedicationCatalogScreen(
                      state: MyMedicationsState(
                        status: MyMedicationsStatus.ready,
                        medications: items,
                        nextDose: next,
                      ),
                      navigationBar: bar,
                      onRefresh: () async {},
                      onHistory: (_) {},
                      onMedication: (_) {},
                      onDose: (id) => opened = id,
                    ),
            ),
          );
          await tester.runAsync(() async {
            for (final asset in ['home_tablet.png', 'dose_water_plant.png']) {
              await precacheImage(
                AssetImage('assets/illustrations/$asset'),
                tester.element(find.byType(Scaffold).first),
              );
            }
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await captureWidget(
            tester,
            find.byKey(const Key('catalog-capture')),
            '${detail ? 'medication_detail' : 'medication_catalog'}_${scale == 1 ? 'normal' : 'large'}',
          );
          if (!detail) {
            expect(
              tester
                  .widget<IconButton>(find.byType(IconButton).first)
                  .onPressed,
              isNull,
            );
          }
          final doseLabel = find.text('Próxima toma');
          await Scrollable.ensureVisible(
            tester.element(doseLabel),
            alignment: 0.3,
          );
          await tester.pumpAndSettle();
          await tester.tap(doseLabel);
          await tester.pump();
          expect(opened, 'intake-real');
          await tester.drag(find.byType(ListView).first, const Offset(0, -800));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
