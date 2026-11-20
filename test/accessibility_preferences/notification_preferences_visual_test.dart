import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/notification_preferences.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/notifications/notification_preferences_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/screens/notification_preferences_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../support/visual_capture.dart';
import 'preferences_presentation_test.dart'
    show FakeNotifications, notificationsBloc;

/// Native summary, editing and server acknowledgements stay in the same flow.
void main() {
  setUpAll(loadTataFonts);
  testWidgets(
    'a channel receipt with equivalent policy preserves unsaved edits',
    (tester) async {
      final repository = _repository();
      await _show(tester, repository);
      await tester.tap(find.text('Editar').first);
      await tester.pumpAndSettle();
      final reminder = tester
          .widget<TextField>(find.byKey(const Key('policy-reminder')))
          .controller!;
      await tester.enterText(find.byKey(const Key('policy-reminder')), '12');
      // A decoded HTTP receipt has new objects even when policy values match.
      repository.stored = _repository().stored;
      final sms = find.widgetWithText(SwitchListTile, 'SMS');
      await tester.ensureVisible(sms);
      await tester.tap(sms);
      await tester.pumpAndSettle();
      expect(repository.updates, 1);
      expect(reminder.text, '12');
      expect(repository.stored.policy!.reminderMinutes, 10);
    },
  );
  testWidgets('Back discards an unsaved edit without leaving the summary', (
    tester,
  ) async {
    final repository = _repository();
    await _show(tester, repository);
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('policy-reminder')), '12');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('policy-reminder')), findsNothing);
    expect(find.text('10 min después de la hora programada'), findsOneWidget);
    expect(repository.policyUpdates, 0);
  });
  for (final scale in [1.0, 1.5]) {
    testWidgets('notification groups render at text scale $scale', (
      tester,
    ) async {
      await _show(tester, _repository(), scale: scale);
      expect(find.text('Después de 20 min'), findsOneWidget);
      expect(find.text('2 configurados'), findsOneWidget);
      await captureWidget(
        tester,
        find.byKey(const Key('notification-capture')),
        'notification-563-1219-$scale',
      );
      if (scale > 1) {
        await tester.ensureVisible(
          find.byKey(const Key('notification-channel-call')),
        );
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('notification-capture')),
          'notification-563-1219-$scale-channels',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'channel changes show only the server receipt and failure preserves it',
    (tester) async {
      final repository = _repository();
      await _show(tester, repository);
      final sms = find.byKey(const Key('notification-channel-sms'));
      await tester.ensureVisible(sms);
      await tester.tap(sms);
      await tester.pumpAndSettle();
      expect(repository.stored.isEnabled(ChannelType.sms), isFalse);
      repository.failure = 'NETWORK_UNAVAILABLE';
      await tester.tap(sms);
      await tester.pumpAndSettle();
      expect(repository.stored.isEnabled(ChannelType.sms), isFalse);
      expect(repository.updates, 2);
    },
  );
  testWidgets(
    'policy edit retries without losing text and returns to summary',
    (tester) async {
      final repository = _repository();
      await _show(tester, repository);
      await tester.tap(find.text('Editar').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('policy-reminder')), '12');
      final reminder = tester
          .widget<TextField>(find.byKey(const Key('policy-reminder')))
          .controller!;
      final save = find.widgetWithText(ElevatedButton, 'Guardar avisos');
      repository.failure = 'NETWORK_UNAVAILABLE';
      await tester.scrollUntilVisible(
        save,
        350,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(reminder.text, '12');
      expect(repository.stored.policy!.reminderMinutes, 10);
      repository.failure = null;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.stored.policy!.reminderMinutes, 12);
      expect(find.byKey(const Key('policy-reminder')), findsNothing);
      expect(find.text('12 min después de la hora programada'), findsOneWidget);
    },
  );
  testWidgets('cancelling the quiet time picker sends no update', (
    tester,
  ) async {
    final repository = _repository();
    await _show(tester, repository);
    await tester.tap(find.textContaining('22:00').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.updates, 0);
    expect(repository.stored.quietHours, QuietHours(22, 0, 7, 0));
  });
  testWidgets('cancelling the second quiet picker also sends no update', (
    tester,
  ) async {
    final repository = _repository();
    await _show(tester, repository);
    await tester.tap(find.textContaining('22:00').first);
    await tester.pumpAndSettle();
    final confirm = MaterialLocalizations.of(
      tester.element(find.byType(TimePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(confirm));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.updates, 0);
    expect(repository.stored.quietHours, QuietHours(22, 0, 7, 0));
  });
}

FakeNotifications _repository() => FakeNotifications()
  ..stored = NotificationPreferences(
    quietHours: QuietHours(22, 0, 7, 0),
    channels: [
      for (final type in ChannelType.values) NotificationChannel(type, true),
    ],
    policy: NotificationPolicy.tryCreate(
      reminderMinutes: 10,
      pendingAlertMinutes: 20,
      omittedAlertMinutes: 120,
      escalationMinutes: 180,
      dailySummaryHour: 20,
      dailySummaryMinute: 0,
    ),
    emergencyContacts: [
      EmergencyContact.tryCreate('Ana', '+51987654321')!,
      EmergencyContact.tryCreate('Diego', '+51912345678')!,
    ],
  );

Future<void> _show(
  WidgetTester tester,
  FakeNotifications repository, {
  double scale = 1,
}) async {
  tester.view.physicalSize = scale == 1
      ? const Size(393, 883)
      : const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TataTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          alwaysUse24HourFormat: true,
        ),
        child: RepaintBoundary(
          key: const Key('notification-capture'),
          child: child!,
        ),
      ),
      home: BlocProvider(
        create: (_) =>
            notificationsBloc(repository)
              ..add(const NotificationPreferencesRequested()),
        child: NotificationPreferencesScreen(
          onSessionInvalidated: () {},
          navigationBar: CaregiverTabBar(
            selected: CaregiverTab.more,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
