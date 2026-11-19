import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/failure_codes.dart';
import 'package:tata/features/family_monitoring/application/ports/contact_launcher.dart';
import 'package:tata/features/family_monitoring/application/ports/monitoring_ports.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitoring_readmodels.dart';
import 'package:tata/features/family_monitoring/application/usecases/alert_usecases.dart';
import 'package:tata/features/family_monitoring/application/usecases/note_usecases.dart';
import 'package:tata/features/family_monitoring/domain/entities/caregiver_alert.dart';
import 'package:tata/features/family_monitoring/domain/repositories/monitoring_repositories.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_status.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alert_detail/alert_detail_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/screens/alert_detail_screen.dart';
import 'package:tata/features/family_monitoring/presentation/widgets/alert_detail_cards.dart';
import 'package:tata/features/family_monitoring/presentation/widgets/follow_up_note_dialog.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';
import 'monitoring_application_test.dart'
    show
        FakeAlerts,
        FakeDoseReader,
        FakeEventsReader,
        FakeNotes,
        FakePersonReader,
        anAlert,
        dose;

final class _Contact implements ContactOptionReader {
  const _Contact({this.available = true});
  final bool available;
  @override
  Future<AppResult<ContactOption>> call(String id) async => AppSuccess(
    ContactOption(
      firstName: 'Rosa',
      channel: available
          ? ContactChannel(
              type: ContactChannelType.phone,
              value: '+51 999 111 222',
            )
          : null,
    ),
  );
}

final class _Launcher implements ContactLauncher {
  final opened = <ContactChannel>[];
  @override
  Future<bool> open(ContactChannel channel) async {
    opened.add(channel);
    return true;
  }
}

/// Makes mutation and conflict reread responses arrive after an access revocation.
final class _DeferredAlerts implements AlertsRepository {
  final delegate = FakeAlerts(alerts: [anAlert()]);
  final update = Completer<AppResult<CaregiverAlert>>();
  final reread = Completer<AppResult<CaregiverAlert>>();
  final rereadStarted = Completer<void>();
  var reads = 0;

  @override
  Future<AppResult<List<CaregiverAlert>>> openAlerts(String id) =>
      delegate.openAlerts(id);
  @override
  Future<AppResult<CaregiverAlert>> alert(String id, int alertId) {
    if (++reads == 1) return delegate.alert(id, alertId);
    if (!rereadStarted.isCompleted) {
      rereadStarted.complete();
    }
    return reread.future;
  }

  @override
  Future<AppResult<CaregiverAlert>> updateStatus(
    String id,
    int alertId,
    AlertStatus status,
  ) => update.future;
}

AlertDetailBloc _detail(
  AlertsRepository alerts, {
  bool contactAvailable = true,
}) => AlertDetailBloc(
  detail: GetAlertDetail(alerts),
  update: UpdateAlertStatus(alerts),
  contact: _Contact(available: contactAvailable),
  people: FakePersonReader(
    AppSuccess(
      MonitoredPerson(
        id: 'adult-1',
        fullName: 'Rosa Vargas',
        birthDate: DateTime(1958, 7, 21),
      ),
    ),
  ),
  doses: FakeDoseReader(
    AppSuccess(dose('intake-1', 'PENDING', DateTime(2026, 7, 22, 8))),
  ),
  history: FakeEventsReader(
    AppSuccess([
      for (final minute in [0, 10, 25, 30])
        RecordedAlertEvent(
          type: minute == 0
              ? RecordedAlertEventType.intakeScheduled
              : minute == 30
              ? RecordedAlertEventType.alertGenerated
              : RecordedAlertEventType.reinforcedReminderSent,
          occurredAt: DateTime(2026, 7, 22, 8, minute),
        ),
    ]),
  ),
  olderAdultId: 'adult-1',
  alertId: 1,
);

void main() {
  setUpAll(loadTataFonts);

  Future<void> pump(
    WidgetTester tester, {
    required FakeAlerts alerts,
    required FakeNotes notes,
    required _Launcher launcher,
    double scale = 1,
    bool contactAvailable = true,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const Key('alert-variant-capture'),
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    _detail(alerts, contactAvailable: contactAvailable)
                      ..add(const AlertDetailRequested()),
              ),
              BlocProvider(
                create: (_) => NoteComposerCubit(
                  register: RegisterFollowUpNote(notes),
                  olderAdultId: 'adult-1',
                ),
              ),
            ],
            child: AlertDetailScreen(
              launcher: launcher,
              onTab: (_) {},
              onOpenProfile: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/illustrations/alert_tablet.png'),
        tester.element(find.byType(AlertDetailScreen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> write(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text('Agregar nota de seguimiento'));
    await tester.tap(find.text('Agregar nota de seguimiento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text('Guardar nota'));
    await tester.pumpAndSettle();
  }

  for (final variant in ['unavailable', 'saved', 'attended']) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('$variant follows the recorded outcome at scale $scale', (
        tester,
      ) async {
        final alerts = FakeAlerts(alerts: [anAlert()]);
        final notes = FakeNotes();
        final launcher = _Launcher();
        await pump(
          tester,
          alerts: alerts,
          notes: notes,
          launcher: launcher,
          scale: scale,
          contactAvailable: variant != 'unavailable',
        );
        if (variant == 'unavailable') {
          final button = find.widgetWithText(
            FilledButton,
            'Contacto no disponible',
          );
          await tester.ensureVisible(button);
          expect(tester.widget<FilledButton>(button).onPressed, isNull);
          await tester.tap(button);
          expect(launcher.opened, isEmpty);
        } else if (variant == 'saved') {
          await write(tester, 'Llamé a Rosa y registré el seguimiento.');
          expect(notes.registered, ['Llamé a Rosa y registré el seguimiento.']);
          expect(find.byKey(const Key('follow-up-note-saved')), findsOneWidget);
          expect(alerts.updates, isEmpty);
        } else {
          await tester.ensureVisible(find.text('Marcar como atendida'));
          await tester.tap(find.text('Marcar como atendida'));
          await tester.pumpAndSettle();
          final button = find.widgetWithText(OutlinedButton, 'Atendida');
          expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
          await tester.tap(button);
          expect(alerts.updates, [(1, AlertStatus.attended)]);
          final bloc = tester
              .element(find.byType(AlertDetailScreen))
              .read<AlertDetailBloc>();
          expect(bloc.state.alert!.status, AlertStatus.attended);
        }
        ScaffoldMessenger.of(tester.element(find.byType(AlertDetailScreen)))
            .hideCurrentSnackBar();
        await tester.pumpAndSettle();
        if (scale > 1) {
          await Scrollable.ensureVisible(
            tester.element(find.byType(AlertDetailSurface).last),
            alignment: 0.1,
          );
          await tester.pumpAndSettle();
        } else {
          Scrollable.of(tester.element(find.byType(AlertDetailSurface).last))
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await captureWidget(
          tester,
          find.byKey(const Key('alert-variant-capture')),
          'alert_${variant}_$scale',
        );
      });
    }
  }

  testWidgets(
    'system back closes the follow-up draft and permits another note',
    (tester) async {
      await pump(
        tester,
        alerts: FakeAlerts(alerts: [anAlert()]),
        notes: FakeNotes(),
        launcher: _Launcher(),
      );
      await tester.ensureVisible(find.text('Agregar nota de seguimiento'));
      await tester.tap(find.text('Agregar nota de seguimiento'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final cubit = tester
          .element(find.byType(AlertDetailScreen))
          .read<NoteComposerCubit>();
      expect(cubit.state.open, isFalse);
      await tester.tap(find.text('Agregar nota de seguimiento'));
      await tester.pumpAndSettle();
      expect(find.byType(FollowUpNoteDialog), findsOneWidget);
    },
  );

  testWidgets(
    'a denied note write clears the detail and removes the protected draft',
    (tester) async {
      final notes = FakeNotes()
        ..registerResult = const AppFailure('ACCESS_DENIED');
      await pump(
        tester,
        alerts: FakeAlerts(alerts: [anAlert()]),
        notes: notes,
        launcher: _Launcher(),
      );
      await write(tester, 'Borrador privado');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Borrador privado'), findsNothing);
      expect(find.text('Rosa Vargas'), findsNothing);
      expect(find.byKey(const Key('follow-up-note-saved')), findsNothing);
      final bloc = tester
          .element(find.byType(AlertDetailScreen))
          .read<AlertDetailBloc>();
      expect(bloc.state.status, AlertDetailStatus.failure);
      expect(bloc.state.errorCode, 'ACCESS_DENIED');
      expect(bloc.state.alert, isNull);
    },
  );

  for (final conflict in [false, true]) {
    test(
      'late ${conflict ? 'conflict reread' : 'mutation receipt'} cannot restore revoked evidence',
      () async {
        final alerts = _DeferredAlerts();
        final bloc = _detail(alerts)..add(const AlertDetailRequested());
        await pumpEventQueue();
        bloc.add(const AlertStatusChangeRequested(AlertStatus.attended));
        await pumpEventQueue();
        if (conflict) {
          alerts.update.complete(
            const AppFailure(MonitoringFailureCodes.statusConflict),
          );
          await alerts.rereadStarted.future;
        }
        bloc.add(const AlertDetailAccessLost('ACCESS_DENIED'));
        await pumpEventQueue();
        if (conflict) {
          alerts.reread.complete(
            AppSuccess(anAlert(status: AlertStatus.attended)),
          );
        } else {
          alerts.update.complete(
            AppSuccess(anAlert(status: AlertStatus.attended)),
          );
        }
        await pumpEventQueue();
        expect(bloc.state.status, AlertDetailStatus.failure);
        expect(bloc.state.alert, isNull);
        expect(bloc.state.person, isNull);
        expect(bloc.state.dose, isNull);
        expect(bloc.state.history, isNull);
        expect(bloc.state.contact.option, isNull);
        expect(bloc.state.feedback, isNull);
        await bloc.close();
      },
    );
  }
}
