import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_event.dart';
import 'package:tata/features/intake_execution/presentation/navigation/adult_home_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';

/// Server responses can be delayed independently of the foreground clock.
final class _Reader implements IntakeReader {
  AppResult<Intake?> result = const AppSuccess(null);
  Future<AppResult<Intake?>>? pending;
  AppResult<List<Intake>> day = const AppSuccess([]);
  int reads = 0;
  final days = <DateTime>[];

  @override
  Future<AppResult<Intake?>> next() async {
    reads++;
    return pending ?? Future.value(result);
  }

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async {
    days.add(from);
    return day;
  }

  @override
  Future<AppResult<Intake>> detail(String intakeId) async =>
      const AppFailure('INTAKE_NOT_FOUND');
}

void main() {
  setUpAll(loadTataFonts);
  final initialTime = DateTime(2026, 11, 17, 23, 59, 30);
  Intake dose(String id) => Intake(
    id: id,
    olderAdultId: 'adult-A',
    medicationName: 'Medicamento $id',
    dose: '1 tableta',
    scheduledAt: initialTime.toUtc(),
    status: IntakeStatus.pending,
  );

  Future<void> open(
    WidgetTester tester,
    _Reader reader, {
    GlobalKey<NavigatorState>? navigator,
    VoidCallback? onInvalidated,
    DateTime Function()? clock,
    void Function(HomeBloc)? onBloc,
  }) async {
    tester.view
      ..physicalSize = const Size(1179, 2649)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdultHomeRoute(
          createBloc: () {
            final bloc = HomeBloc(
              next: GetNextIntake(reader),
              progress: GetDailyProgress(reader, clock ?? () => initialTime),
            );
            onBloc?.call(bloc);
            return bloc;
          },
          adultName: 'Rosa Vargas',
          clock: clock ?? () => initialTime,
          onOpenMore: () {},
          onSessionInvalidated: onInvalidated ?? () {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/illustrations/home_tablet.png'),
        tester.element(find.byType(AdultHomeRoute)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  testWidgets('a new remote dose replaces the empty state without navigation', (
    tester,
  ) async {
    final reader = _Reader();
    await open(tester, reader);
    expect(find.text('Sin próxima toma'), findsOneWidget);
    reader.result = AppSuccess(dose('nueva'));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(reader.reads, 2);
    expect(find.text('Medicamento nueva'), findsOneWidget);
    expect(find.text('Sin próxima toma'), findsNothing);
    await close(tester);
  });

  testWidgets('background reads keep the card and do not overlap a slow read', (
    tester,
  ) async {
    final reader = _Reader()..result = AppSuccess(dose('actual'));
    await open(tester, reader);
    final response = Completer<AppResult<Intake?>>();
    reader.pending = response.future;
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(find.text('Medicamento actual'), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
    await tester.pump();
    expect(reader.reads, 2, reason: 'one initial and one unfinished read');
    response.complete(AppSuccess(dose('siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Medicamento siguiente'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a covered home does not poll another flow', (tester) async {
    final reader = _Reader();
    final navigator = GlobalKey<NavigatorState>();
    await open(tester, reader, navigator: navigator);
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('Otra pantalla')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(reader.reads, 1);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(reader.reads, 2);
    await close(tester);
  });

  testWidgets('background and inactive states stop polling; resume reloads', (
    tester,
  ) async {
    final reader = _Reader();
    await open(tester, reader);
    for (final lifecycle in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(lifecycle);
      await tester.pump(const Duration(minutes: 2));
      await tester.pump();
      expect(reader.reads, 1);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(reader.reads, 2);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(reader.reads, 3);
    await close(tester);
  });

  testWidgets('lost access clears clinical values and stops periodic reads', (
    tester,
  ) async {
    var invalidations = 0;
    final reader = _Reader()..result = AppSuccess(dose('actual'));
    await open(tester, reader, onInvalidated: () => invalidations++);
    reader.result = const AppFailure('ACCESS_DENIED');
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Medicamento actual'), findsNothing);
    expect(invalidations, 1);
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(reader.reads, 2);
    await close(tester);
  });

  testWidgets('the next refresh uses the new calendar day after midnight', (
    tester,
  ) async {
    var time = initialTime;
    final reader = _Reader();
    await open(tester, reader, clock: () => time);
    time = time.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(reader.days, [
      DateTime(2026, 11, 17).toUtc(),
      DateTime(2026, 11, 18).toUtc(),
    ]);
    await close(tester);
  });

  testWidgets('a return reload supersedes a pending background response', (
    tester,
  ) async {
    final reader = _Reader()..result = AppSuccess(dose('actual'));
    late HomeBloc bloc;
    await open(tester, reader, onBloc: (value) => bloc = value);
    final oldResponse = Completer<AppResult<Intake?>>();
    reader.pending = oldResponse.future;
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    reader.pending = null;
    reader.result = AppSuccess(dose('reciente'));
    bloc.add(const HomeRequested());
    await tester.pumpAndSettle();
    oldResponse.complete(AppSuccess(dose('antigua')));
    await tester.pumpAndSettle();
    expect(find.text('Medicamento reciente'), findsOneWidget);
    expect(find.text('Medicamento antigua'), findsNothing);
    await close(tester);
  });
}
