import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/tata_app.dart';
import 'package:tata/features/accessibility_preferences/application/ports/preferences_ports.dart';
import 'package:tata/features/accessibility_preferences/application/usecases/preferences_usecases.dart';
import 'package:tata/features/accessibility_preferences/domain/repositories/notification_preferences_repository.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/accessibility_preferences.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/notification_preferences.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_bloc.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_state.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/notifications/notification_preferences_bloc.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/notifications/notification_preferences_event.dart';
import 'package:tata/features/accessibility_preferences/presentation/bloc/notifications/notification_preferences_state.dart';
import 'package:tata/features/accessibility_preferences/presentation/cubit/appearance_cubit.dart';
import 'package:tata/features/accessibility_preferences/presentation/screens/accessibility_screen.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/repositories/session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';

import 'preferences_repository_test.dart'
    show FakeRemote, MemoryLocal, watchOwner;

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Notification repository double that remembers what it was asked to store.
final class FakeNotifications implements NotificationPreferencesRepository {
  NotificationPreferences stored = const NotificationPreferences(policy: null);
  String? failure;
  int updates = 0;
  int policyUpdates = 0;

  @override
  Future<AppResult<NotificationPreferences>> get(String userId) async =>
      failure != null ? AppFailure(failure!) : AppSuccess(stored);

  @override
  Future<AppResult<NotificationPreferences>> update(
    String userId,
    NotificationPreferences preferences,
  ) async {
    updates++;
    if (failure != null) return AppFailure(failure!);
    stored = NotificationPreferences(
      quietHours: preferences.quietHours,
      channels: preferences.channels,
      policy: stored.policy,
      emergencyContacts: stored.emergencyContacts,
    );
    return AppSuccess(stored);
  }

  @override
  Future<AppResult<NotificationPreferences>> updatePolicy(
    String userId,
    NotificationPolicy policy,
    List<EmergencyContact> contacts,
  ) async {
    policyUpdates++;
    if (failure != null) return AppFailure(failure!);
    stored = NotificationPreferences(
      quietHours: stored.quietHours,
      channels: stored.channels,
      policy: policy,
      emergencyContacts: contacts,
    );
    return AppSuccess(stored);
  }
}

NotificationPreferencesBloc notificationsBloc(FakeNotifications repository) =>
    NotificationPreferencesBloc(
      get: GetNotificationPreferences(repository),
      update: UpdateNotificationPreferences(repository),
      updatePolicy: UpdateNotificationPolicy(repository),
      userId: 'user-A',
    );

AccessibilityBloc accessibilityBloc(
  OfflineFirstUserPreferences repository,
  MemoryLanguage language,
) => AccessibilityBloc(
  observe: ObserveAccessibility(repository),
  observeLanguage: ObserveApplicationLanguage(language),
  update: UpdateAccessibility(repository),
  changeLanguage: ChangeApplicationLanguage(language),
  sync: SyncUserPreferences(repository),
  userId: 'user-A',
);

void main() {
  group('notification preferences bloc', () {
    test('loads, toggles a channel and shows the acknowledged value', () async {
      final repository = FakeNotifications();
      final bloc = notificationsBloc(repository)
        ..add(const NotificationPreferencesRequested());
      addTearDown(bloc.close);
      await settle();
      expect(bloc.state.status, NotificationPreferencesStatus.ready);
      bloc.add(const ChannelToggled(ChannelType.sms, true));
      await settle();
      expect(bloc.state.preferences.isEnabled(ChannelType.sms), isTrue);
      expect(repository.updates, 1);
    });

    test('quiet hours switch on with the suggestion and back off', () async {
      final bloc = notificationsBloc(FakeNotifications())
        ..add(const NotificationPreferencesRequested());
      addTearDown(bloc.close);
      await settle();
      bloc.add(const QuietHoursToggled(true));
      await settle();
      expect(bloc.state.preferences.quietHours, QuietHours(22, 0, 7, 0));
      bloc.add(QuietHoursChanged(QuietHours(23, 30, 6, 0)));
      await settle();
      expect(bloc.state.preferences.quietHours, QuietHours(23, 30, 6, 0));
      bloc.add(const QuietHoursToggled(false));
      await settle();
      expect(bloc.state.preferences.quietHours, isNull);
    });

    test('a failed change keeps the last acknowledged values', () async {
      final repository = FakeNotifications();
      final bloc = notificationsBloc(repository)
        ..add(const NotificationPreferencesRequested());
      addTearDown(bloc.close);
      await settle();
      repository.failure = 'NETWORK_UNAVAILABLE';
      bloc.add(const ChannelToggled(ChannelType.email, true));
      await settle();
      expect(bloc.state.preferences.isEnabled(ChannelType.email), isFalse);
      expect(bloc.state.errorCode, 'NETWORK_UNAVAILABLE');
      expect(bloc.state.busy, isFalse);
    });

    test('policy is validated before any request', () async {
      final repository = FakeNotifications();
      final bloc = notificationsBloc(repository)
        ..add(const NotificationPreferencesRequested());
      addTearDown(bloc.close);
      await settle();
      PolicySaved save({
        String reminder = '5',
        String pending = '15',
        String omitted = '30',
        String escalation = '60',
        String summary = '',
        List<ContactInput> contacts = const [],
      }) => PolicySaved(
        reminder: reminder,
        pending: pending,
        omitted: omitted,
        escalation: escalation,
        dailySummary: summary,
        contacts: contacts,
      );

      bloc.add(save(pending: '3'));
      await settle();
      expect(bloc.state.errorCode, 'INVALID_POLICY');
      bloc.add(save(summary: '25:00'));
      await settle();
      expect(bloc.state.errorCode, 'INVALID_POLICY');
      bloc.add(save(contacts: [const ContactInput('Ana', '123')]));
      await settle();
      expect(bloc.state.errorCode, 'INVALID_CONTACT');
      expect(repository.policyUpdates, 0);
    });

    test(
      'policy and contacts are saved together; blank rows are ignored',
      () async {
        final repository = FakeNotifications();
        final bloc = notificationsBloc(repository)
          ..add(const NotificationPreferencesRequested());
        addTearDown(bloc.close);
        await settle();
        bloc.add(
          const PolicySaved(
            reminder: '10',
            pending: '20',
            omitted: '40',
            escalation: '90',
            dailySummary: '08:30',
            contacts: [
              ContactInput('Ana', '987 654 321'),
              ContactInput('', ''),
            ],
          ),
        );
        await settle();
        expect(bloc.state.saved, isTrue);
        expect(repository.policyUpdates, 1);
        final policy = bloc.state.preferences.policy!;
        expect(policy.escalationMinutes, 90);
        expect(policy.dailySummaryHour, 8);
        expect(policy.dailySummaryMinute, 30);
        expect(
          bloc.state.preferences.emergencyContacts.single.phone,
          '987654321',
        );
      },
    );
  });

  group('accessibility screen', () {
    testWidgets('a change applies locally and reports pending sync offline', (
      tester,
    ) async {
      final remote = FakeRemote()..failure = 'NETWORK_UNAVAILABLE';
      final local = MemoryLocal();
      final language = MemoryLanguage();
      final bloc = accessibilityBloc(
        OfflineFirstUserPreferences(remote: remote, local: local),
        language,
      )..add(const AccessibilityStarted());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: BlocProvider(
            create: (_) => bloc,
            child: const AccessibilityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accesibilidad'), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Tema oscuro'));
      await tester.pumpAndSettle();
      expect((await local.current('user-A')).darkTheme, isTrue);
      expect(bloc.state.sync, AccessibilitySyncStatus.pending);
      expect(
        find.textContaining('se enviará cuando haya conexión'),
        findsOneWidget,
      );
      await tester.tap(find.text('Grande'));
      await tester.pumpAndSettle();
      expect((await local.current('user-A')).textSize, TextSizeLevel.large);
      await tester.tap(find.widgetWithText(ListTile, 'Idioma'));
      await tester.pumpAndSettle();
      expect(language.values['user-A'], AppLanguage.english);
      // Leaving the screen disposes the provider, which closes the bloc.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('app-wide appearance', () {
    testWidgets('signing in applies the owner\'s theme, scale and language', (
      tester,
    ) async {
      final local = MemoryLocal()
        ..values['test-owner'] = const AccessibilityPreferences(
          darkTheme: true,
          textSize: TextSizeLevel.large,
        );
      final language = MemoryLanguage()
        ..values['test-owner'] = AppLanguage.english;
      final repository = OfflineFirstUserPreferences(
        remote: FakeRemote()..failure = 'NETWORK_UNAVAILABLE',
        local: local,
      );
      final sessions = _SessionRepository();
      await tester.pumpWidget(
        TataApp(
          createAccessBloc: () => AccessBloc(
            signIn: SignIn(sessions),
            restore: RestoreSession(sessions),
            signOut: SignOut(sessions),
          ),
          createAppearanceCubit: () => AppearanceCubit(
            observeAccessibility: ObserveAccessibility(repository),
            observeLanguage: ObserveApplicationLanguage(language),
            sync: SyncUserPreferences(repository),
          ),
          authenticatedBuilder: (context, signOut, _) => Scaffold(
            body: Column(
              children: [
                Text('brightness:${Theme.of(context).brightness.name}'),
                Text('scale:${MediaQuery.of(context).textScaler.scale(10)}'),
                TextButton(
                  onPressed: signOut,
                  child: Text(AppLocalizations.of(context).signOut),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Anonymous: defaults.
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login-email')), 'a@b.co');
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'password',
      );
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('brightness:dark'), findsOneWidget);
      expect(find.text('scale:11.5'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      // Signing out drops the account's appearance immediately.
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out'), findsNothing);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
    });
  });
}

final class MemoryLanguage implements ApplicationLanguageStore {
  final values = <String, AppLanguage>{};
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<AppLanguage> watch(String ownerId) => watchOwner(
    _changes.stream,
    ownerId,
    () async => values[ownerId] ?? AppLanguage.spanish,
  );

  @override
  Future<void> write(String ownerId, AppLanguage language) async {
    values[ownerId] = language;
    _changes.add(ownerId);
  }
}

final class _SessionRepository implements SessionRepository {
  @override
  Future<AppResult<AccountSession?>> restore() async => const AppSuccess(null);

  @override
  Future<AppResult<AccountSession>> signIn(
    String email,
    String password,
  ) async => AppSuccess(
    AccountSession(
      owner: SessionOwner('test-owner', SessionRole.caregiver),
      expiresAt: DateTime.utc(2030),
    ),
  );

  @override
  Future<AppResult<void>> signOut() async => const AppSuccess(null);
}
