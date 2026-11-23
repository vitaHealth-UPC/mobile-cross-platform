import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_trend_point.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/adherence_badge_view.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/treatment_adherence_view.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/domain/entities/medication.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_management/treatment_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_management/treatment_management_event.dart';
import 'package:tata/features/treatment_management/presentation/screens/treatment_detail_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../support/fake_treatment_backend.dart';
import '../support/visual_capture.dart';
import 'treatment_blocs_test.dart' show managementBloc;

AdherenceSummary _summary() => AdherenceSummary(
  periodDays: 7,
  scheduledCount: 25,
  adherencePercent: 92,
  onTimePercent: 88,
  lateCount: 1,
  omittedCount: 2,
  recentIntakes: const [],
  trend: [
    for (var i = 0; i < 7; i++)
      AdherenceTrendPoint(
        date: DateTime(2026, 11, 2 + i),
        adherencePercent: [100, 100, 75, 100, 67, 100, 100][i],
      ),
  ],
);

final class _Adherence implements AdherenceReader {
  _Adherence({this.treatmentId = 'tr-1'});
  final String? treatmentId;
  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays, {
    String? treatmentId,
  }) async {
    expect(olderAdultId, 'adult-A');
    expect(periodDays, 7);
    expect(treatmentId, this.treatmentId);
    return AppSuccess(_summary());
  }
}

FakeBackend _backend({
  TreatmentStatus status = TreatmentStatus.active,
  bool active = true,
}) {
  final value = FakeBackend();
  value.medications['med-1'] = Medication(
    id: 'med-1',
    olderAdultId: 'adult-A',
    name: 'Losartán',
    presentation: '50 mg',
    active: active,
  );
  value.stored = TreatmentDetail(
    id: 'tr-1',
    olderAdultId: 'adult-A',
    name: 'Control de presión',
    status: status,
    medicationId: 'med-1',
    dose: '1 comprimido',
    frequency: 'Cada día',
    scheduledTimes: const ['08:00'],
    instructions: 'Con agua',
    followUpDelayMinutes: 10,
    recurrenceZone: 'America/Lima',
  );
  return value;
}

void main() {
  setUpAll(loadTataFonts);
  Future<TreatmentManagementBloc> pump(
    WidgetTester tester,
    FakeBackend backend,
    double scale,
  ) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = managementBloc(backend)
      ..add(const TreatmentManagementRequested());
    addTearDown(bloc.close);
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
            key: const Key('management-capture'),
            child: child!,
          ),
        ),
        home: BlocProvider.value(
          value: bloc,
          child: TreatmentDetailScreen(
            personName: 'Rosa Vargas',
            personAdherenceBadge: AdherenceBadgeView(
              createBloc: () => LevelBloc(
                olderAdultId: 'adult-A',
                periodDays: 7,
                summary: GetAdherenceSummary(_Adherence(treatmentId: null)),
              ),
              onSessionInvalidated: () {},
            ),
            onSessionInvalidated: () {},
            navigationBar: CaregiverTabBar(
              selected: CaregiverTab.person,
              enabledTabs: const {CaregiverTab.home, CaregiverTab.person},
              onSelected: (_) {},
            ),
            adherence: TreatmentAdherenceView(
              createBloc: () => LevelBloc(
                olderAdultId: 'adult-A',
                periodDays: 7,
                treatmentId: 'tr-1',
                summary: GetAdherenceSummary(_Adherence()),
              ),
              onSessionInvalidated: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  for (final variant in ['active', 'paused', 'inactive', 'denied']) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('management $variant adapts to text scale $scale', (
        tester,
      ) async {
        final backend = _backend(
          status: variant == 'paused'
              ? TreatmentStatus.paused
              : TreatmentStatus.active,
          active: variant != 'inactive',
        );
        if (variant == 'denied') backend.failure = 'ACCESS_DENIED';
        await pump(tester, backend, scale);
        expect(tester.takeException(), isNull);
        if (variant == 'denied') {
          expect(find.text('Acceso restringido'), findsOneWidget);
          expect(find.text('Rosa Vargas'), findsNothing);
          expect(find.text('Control de presión'), findsNothing);
          expect(find.text('92%'), findsNothing);
        }
        await captureWidget(
          tester,
          find.byKey(const Key('management-capture')),
          'treatment_management_${variant}_${scale == 1 ? 'normal' : 'large'}',
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'pause preserves zone, deactivation requires confirmation and reactivation restores actions',
    (tester) async {
      final backend = _backend();
      final bloc = await pump(tester, backend, 1);
      await tester.tap(find.text('Pausar'));
      await tester.pumpAndSettle();
      expect(bloc.state.detail!.recurrenceZone, 'America/Lima');
      expect(find.text('Reanudar'), findsOneWidget);
      final deactivate = find.byKey(
        const Key('deactivate-treatment-medication'),
      );
      await tester.ensureVisible(deactivate);
      await tester.pumpAndSettle();
      await tester.tap(deactivate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(backend.medications['med-1']!.active, isTrue);
      await tester.tap(deactivate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desactivar'));
      await tester.pumpAndSettle();
      expect(backend.medications['med-1']!.active, isFalse);
      expect(bloc.state.activeMedicationCount, 0);
      expect(find.text('Editar pauta'), findsNothing);
      final reactivate = find.text('Reactivar');
      await tester.ensureVisible(reactivate);
      await tester.pumpAndSettle();
      await tester.tap(reactivate);
      await tester.pumpAndSettle();
      expect(bloc.state.activeMedicationCount, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editor saves real values and controllers survive the exit animation',
    (tester) async {
      final backend = _backend();
      await pump(tester, backend, 1);
      await tester.tap(find.text('Editar pauta'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('edit-dose')),
        '2 comprimidos',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(backend.stored!.dose, '2 comprimidos');
      expect(find.textContaining('2 comprimidos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
