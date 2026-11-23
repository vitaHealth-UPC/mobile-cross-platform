import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/adherence_badge_view.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/adherence_fixtures.dart';

final class _Reader implements AdherenceReader {
  AppResult<AdherenceSummary?> result = AppSuccess(
    sampleSummary(periodDays: 7),
  );
  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays, {
    String? treatmentId,
  }) async {
    expect(
      treatmentId,
      isNull,
      reason: 'The person badge cannot borrow a treatment filter',
    );
    expect(periodDays, 7);
    return result;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    _Reader reader,
    VoidCallback invalidated,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdherenceBadgeView(
            createBloc: () => LevelBloc(
              olderAdultId: 'adult-A',
              periodDays: 7,
              summary: GetAdherenceSummary(reader),
            ),
            onSessionInvalidated: invalidated,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'person badge reads unfiltered evidence and displays only the received percentage',
    (tester) async {
      await pump(tester, _Reader(), () {});
      expect(find.text('92% adherencia'), findsOneWidget);
    },
  );
  testWidgets('missing person evidence never fabricates a zero-percent badge', (
    tester,
  ) async {
    final reader = _Reader()..result = const AppSuccess(null);
    await pump(tester, reader, () {});
    expect(find.textContaining('%'), findsNothing);
  });
  testWidgets(
    'foreground revocation removes the badge and invalidates its host',
    (tester) async {
      final reader = _Reader();
      var invalidations = 0;
      await pump(tester, reader, () => invalidations++);
      reader.result = const AppFailure('ACCESS_DENIED');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.textContaining('%'), findsNothing);
      expect(invalidations, 1);
    },
  );
}
