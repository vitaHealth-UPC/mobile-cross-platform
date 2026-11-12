import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/application/ports/intake_confirmation.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/ports/intake_sync.dart';
import 'package:tata/features/intake_execution/application/readmodels/confirmation_receipt.dart';
import 'package:tata/features/intake_execution/application/readmodels/intake_sync_status.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_state.dart';
import 'package:tata/features/intake_execution/presentation/bloc/home/home_bloc.dart';
import 'package:tata/features/intake_execution/presentation/navigation/adult_home_route.dart';
import 'package:tata/features/intake_execution/presentation/screens/dose_detail_screen.dart';
import 'package:tata/features/intake_execution/presentation/screens/dose_outcome_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

final now = DateTime(2026, 11, 10, 9);

Intake dose({
  LocalConfirmation local = LocalConfirmation.none,
  IntakeStatus status = IntakeStatus.pending,
}) => Intake(
  id: 'd1',
  olderAdultId: 'adult-A',
  medicationName: 'Losartán',
  dose: '1 tableta',
  scheduledAt: now.toUtc(),
  status: status,
  localConfirmation: local,
);

Widget localized(Widget child) => MaterialApp(
  theme: TataTheme.light,
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

Widget detail(Intake intake) => localized(
  DoseDetailScreen(
    intake: intake,
    now: now,
    confirming: false,
    canConfirm: intake.confirmable,
    onConfirm: () {},
    onBack: () {},
  ),
);

final class FakeIntakes implements IntakeReader, IntakeConfirmation {
  FakeIntakes(this.confirmResult);
  final AppResult<ConfirmationReceipt> confirmResult;
  AppResult<Intake?> nextResult = const AppSuccess(null);

  @override
  Future<AppResult<Intake?>> next() async => nextResult;
  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      const AppSuccess([]);
  @override
  Future<AppResult<Intake>> detail(String intakeId) async => AppSuccess(dose());
  @override
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId) async =>
      confirmResult;
}

final class FakeSync implements IntakeSync {
  final controller = StreamController<IntakeSyncStatus>.broadcast();
  @override
  IntakeSyncStatus status = const IntakeSyncStatus();
  int requests = 0;

  @override
  Stream<IntakeSyncStatus> get changes => controller.stream;
  @override
  Future<void> request() async => requests++;
  @override
  void suspend() {}

  void publish(IntakeSyncStatus value) {
    status = value;
    controller.add(value);
  }
}

void main() {
  test('a saved confirmation ends as pending, not as confirmed', () async {
    final intakes = FakeIntakes(const AppFailure('PENDING_SYNC'));
    final bloc = DoseBloc(
      intakeId: 'd1',
      detail: GetIntakeDetail(intakes),
      confirm: ConfirmIntake(intakes),
      next: GetNextIntake(intakes),
    )..add(const DoseRequested());
    addTearDown(bloc.close);
    await bloc.stream.firstWhere((state) => state.status == DoseStatus.ready);

    bloc.add(const DoseConfirmRequested());
    final state = await bloc.stream.firstWhere(
      (state) => state.outcome != null,
    );

    expect(state.outcome, ConfirmationOutcome.pendingSync);
    expect(state.intake!.queued, isTrue);
    expect(state.intake!.taken, isFalse);
    expect(state.errorCode, isNull);
  });

  testWidgets('outcome says saved and does not claim history', (tester) async {
    await tester.pumpWidget(
      localized(
        DoseOutcomeScreen(
          outcome: ConfirmationOutcome.pendingSync,
          intake: dose(local: LocalConfirmation.queued),
          now: now,
          onBackHome: () {},
        ),
      ),
    );

    expect(find.text('Toma guardada'), findsOneWidget);
    expect(
      find.text('Se registrará cuando vuelva la conexión.'),
      findsOneWidget,
    );
    expect(find.text('Tu progreso se ha actualizado'), findsNothing);
  });

  testWidgets('a queued dose offers no confirm button', (tester) async {
    await tester.pumpWidget(detail(dose(local: LocalConfirmation.queued)));

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('Por enviar'), findsOneWidget);
    expect(
      find.text(
        'Guardamos tu confirmación. La enviaremos cuando vuelva la conexión.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a pending dose still offers the button', (tester) async {
    await tester.pumpWidget(detail(dose()));

    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('a rejected offline confirmation is explained', (tester) async {
    await tester.pumpWidget(
      detail(
        dose(local: LocalConfirmation.rejected, status: IntakeStatus.omitted),
      ),
    );

    expect(
      find.text(
        'Tu confirmación se envió cuando esta toma ya no se podía registrar.',
      ),
      findsOneWidget,
    );
  });

  group('home', () {
    late FakeSync sync;
    late FakeIntakes intakes;

    Widget home() => localized(
      AdultHomeRoute(
        createBloc: () => HomeBloc(
          next: GetNextIntake(intakes),
          progress: GetDailyProgress(intakes, () => now),
        ),
        adultName: 'Rosa',
        clock: () => now,
        onOpenMore: () {},
        onSessionInvalidated: () {},
        sync: sync,
      ),
    );

    setUp(() {
      sync = FakeSync();
      intakes = FakeIntakes(const AppFailure('REQUEST_FAILED'));
    });

    testWidgets('requests delivery when it opens', (tester) async {
      await tester.pumpWidget(home());
      await tester.pump();

      expect(sync.requests, 1);
    });

    testWidgets('shows no notice while everything is synchronized', (
      tester,
    ) async {
      await tester.pumpWidget(home());
      await tester.pump();

      expect(find.textContaining('Sin conexión'), findsNothing);
      expect(find.textContaining('por enviar'), findsNothing);
    });

    testWidgets('warns about stored data and unsent doses', (tester) async {
      await tester.pumpWidget(home());
      await tester.pump();

      sync.publish(const IntakeSyncStatus(queued: 2, offline: true));
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'Sin conexión. Ves la última información guardada. '
          '2 tomas por enviar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reloads when the server answers a queued dose', (
      tester,
    ) async {
      await tester.pumpWidget(home());
      await tester.pump();
      expect(find.text('Losartán'), findsNothing);

      intakes.nextResult = AppSuccess(
        Intake(
          id: 'd2',
          olderAdultId: 'adult-A',
          medicationName: 'Losartán',
          dose: '1 tableta',
          scheduledAt: now.add(const Duration(hours: 1)).toUtc(),
          status: IntakeStatus.pending,
        ),
      );
      sync.publish(const IntakeSyncStatus(resolved: 1));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Losartán'), findsWidgets);
    });
  });
}
