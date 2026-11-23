import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/ports/treatment_readers.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
import 'package:tata/features/treatment_management/infrastructure/mappers/treatment_mapper.dart';
import 'package:tata/features/treatment_management/presentation/bloc/my_medications/my_medications_bloc.dart';
import 'package:tata/features/treatment_management/presentation/screens/my_medications_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import 'catalog_fixtures.dart';

final class _Reader implements MyMedicationsReader {
  AppResult<List<MyMedication>> result = AppSuccess(
    TreatmentMapper.myMedications([
      catalogJson(),
      catalogJson(id: 'med-2', status: 'PAUSED'),
    ], ownerId: 'adult-A'),
  );
  @override
  Future<AppResult<List<MyMedication>>> list() async => result;
}

void main() {
  testWidgets(
    'adult catalog opens detail, returns and filters history without another query',
    (tester) async {
      final reader = _Reader();
      final bloc = MyMedicationsBloc(
        overview: GetMyMedicationsOverview(
          reader,
          () async => const AppSuccess(null),
        ),
      )..add(const MyMedicationsRequested());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: MyMedicationsScreen(onSessionInvalidated: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Losartán 50 mg'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del medicamento'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Mis medicamentos'), findsOneWidget);
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.text('Vitamina D'), findsOneWidget);
      expect(find.text('Losartán 50 mg'), findsNothing);
    },
  );
  testWidgets('revoked adult access invalidates host and removes the catalog', (
    tester,
  ) async {
    final reader = _Reader();
    final bloc = MyMedicationsBloc(
      overview: GetMyMedicationsOverview(
        reader,
        () async => const AppSuccess(null),
      ),
    )..add(const MyMedicationsRequested());
    addTearDown(bloc.close);
    var invalidations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: bloc,
          child: MyMedicationsScreen(
            onSessionInvalidated: () => invalidations++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    reader.result = const AppFailure('ACCESS_DENIED');
    bloc.add(const MyMedicationsRequested());
    await tester.pumpAndSettle();
    expect(invalidations, 1);
    expect(find.text('Losartán 50 mg'), findsNothing);
  });
}
