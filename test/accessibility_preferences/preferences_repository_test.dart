import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata/features/accessibility_preferences/application/ports/preferences_ports.dart';
import 'package:tata/features/accessibility_preferences/application/readmodels/accessibility_change.dart';
import 'package:tata/features/accessibility_preferences/domain/entities/user_preferences.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/accessibility_preferences.dart';
import 'package:tata/features/accessibility_preferences/domain/value_objects/notification_preferences.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/local/shared_preferences_stores.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/mappers/user_preferences_mapper.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/remote/preferences_api.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import 'package:tata/features/accessibility_preferences/infrastructure/repositories/remote_user_preferences.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

Map<String, Object?> snapshot({
  String userId = 'user-A',
  String textSize = 'MEDIUM',
  bool dark = false,
  bool contrast = false,
  Object? quietHours,
  Map<String, Object?>? policy,
  List<Object?>? contacts,
}) => {
  'userId': userId,
  'textSize': textSize,
  'highContrast': contrast,
  'reducedMotion': false,
  'readingAssistance': false,
  'voiceConfirmationEnabled': true,
  'darkTheme': dark,
  'notificationChannels': [
    {'type': 'PUSH', 'enabled': true},
    {'type': 'SMS', 'enabled': false},
  ],
  'quietHours': quietHours,
  'notificationPolicy':
      policy ??
      {
        'reminderMinutes': 5,
        'pendingAlertMinutes': 15,
        'omittedAlertMinutes': 30,
        'escalationMinutes': 60,
        'dailySummaryTime': null,
      },
  'emergencyContacts': contacts ?? const [],
};

/// Server double that applies each change to its own snapshot.
final class FakeRemote implements UserPreferencesRemote {
  AccessibilityPreferences server = AccessibilityPreferences.defaults;
  String? failure;
  final sent = <AccessibilityField>[];
  bool echoStale = false;

  UserPreferences _snapshot() => UserPreferences(
    userId: 'user-A',
    accessibility: server,
    notifications: const NotificationPreferences(),
  );

  @override
  Future<AppResult<UserPreferences>> get(String userId) async =>
      failure != null ? AppFailure(failure!) : AppSuccess(_snapshot());

  @override
  Future<AppResult<UserPreferences>> update(
    String userId,
    AccessibilityChange change,
  ) async {
    if (failure != null) return AppFailure(failure!);
    sent.add(change.field);
    if (!echoStale) server = change.applyTo(server);
    return AppSuccess(_snapshot());
  }
}

/// Emits the current value on listen and again after each change of [ownerId]. A plain
/// controller (not an async generator) so cancelling never waits on pending microtasks.
Stream<T> watchOwner<T>(
  Stream<String> changes,
  String ownerId,
  Future<T> Function() read,
) {
  late final StreamController<T> controller;
  StreamSubscription<String>? subscription;
  controller = StreamController<T>(
    onListen: () {
      subscription = changes.where((id) => id == ownerId).listen((_) async {
        controller.add(await read());
      });
      read().then(controller.add);
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}

final class MemoryLocal implements AccessibilityLocalStore {
  final values = <String, AccessibilityPreferences>{};
  final pendingFields = <String, Set<AccessibilityField>>{};
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<AccessibilityPreferences> watch(String ownerId) =>
      watchOwner(_changes.stream, ownerId, () => current(ownerId));

  @override
  Future<AccessibilityPreferences> current(String ownerId) async =>
      values[ownerId] ?? AccessibilityPreferences.defaults;

  @override
  Future<void> save(
    String ownerId,
    AccessibilityPreferences preferences,
    Set<AccessibilityField> pending,
  ) async {
    values[ownerId] = preferences;
    pendingFields[ownerId] = {...pending};
    _changes.add(ownerId);
  }

  @override
  Future<Set<AccessibilityField>> pending(String ownerId) async => {
    ...?pendingFields[ownerId],
  };
}

void main() {
  group('domain', () {
    test('text size scale factors and large-text switch', () {
      expect(TextSizeLevel.small.scaleFactor, 0.9);
      expect(TextSizeLevel.extraLarge.scaleFactor, 1.3);
      expect(const AccessibilityPreferences().largeTextEnabled, isFalse);
      expect(
        const AccessibilityPreferences(textSize: TextSizeLevel.large)
            .largeTextEnabled,
        isTrue,
      );
      expect(TextSizeLevel.fromWire('HUGE'), isNull);
    });

    test('quiet hours may cross midnight but never be empty', () {
      expect(QuietHours.tryCreate(22, 0, 7, 0), isNotNull);
      expect(QuietHours.tryCreate(8, 30, 8, 30), isNull);
      expect(QuietHours.tryCreate(24, 0, 7, 0), isNull);
    });

    test('policy delays must be strictly increasing and bounded', () {
      NotificationPolicy? make(int a, int b, int c, int d) =>
          NotificationPolicy.tryCreate(
            reminderMinutes: a,
            pendingAlertMinutes: b,
            omittedAlertMinutes: c,
            escalationMinutes: d,
          );
      expect(make(5, 15, 30, 60), isNotNull);
      expect(make(5, 5, 30, 60), isNull);
      expect(make(0, 15, 30, 60), isNull);
      expect(make(5, 15, 30, 1441), isNull);
      expect(
        NotificationPolicy.tryCreate(
          reminderMinutes: 1,
          pendingAlertMinutes: 2,
          omittedAlertMinutes: 3,
          escalationMinutes: 4,
          dailySummaryHour: 8,
        ),
        isNull,
        reason: 'summary needs hour and minute together',
      );
    });

    test('emergency contacts normalize phones and reject bad data', () {
      expect(
        EmergencyContact.tryCreate(' Ana ', '(+51) 987-654 321')!.phone,
        '+51987654321',
      );
      expect(EmergencyContact.tryCreate('', '987654321'), isNull);
      expect(EmergencyContact.tryCreate('Ana', '12345'), isNull);
      expect(EmergencyContact.tryCreate('Ana', 'abc'), isNull);
    });

    test('language tags fall back to Spanish', () {
      expect(AppLanguage.fromTag('en'), AppLanguage.english);
      expect(AppLanguage.fromTag(null), AppLanguage.spanish);
      expect(AppLanguage.spanish.next, AppLanguage.english);
    });

    test('merge copies only the requested fields', () {
      const target = AccessibilityPreferences();
      const source = AccessibilityPreferences(
        highContrast: true,
        darkTheme: true,
        textSize: TextSizeLevel.large,
      );
      final merged = AccessibilityChange.merge(target, source, {
        AccessibilityField.highContrast,
      });
      expect(merged.highContrast, isTrue);
      expect(merged.darkTheme, isFalse);
      expect(merged.textSize, TextSizeLevel.medium);
    });
  });

  group('mapper', () {
    test('parses a complete snapshot and defaults a missing dark theme', () {
      final json = snapshot(
        quietHours: {'start': '22:00:00', 'end': '07:00'},
        contacts: [
          {'name': 'Ana', 'phone': '+51987654321'},
        ],
      )..remove('darkTheme');
      final result = UserPreferencesMapper.preferences(json, 'user-A');
      expect(result.accessibility.darkTheme, isFalse);
      expect(result.notifications.quietHours, QuietHours(22, 0, 7, 0));
      expect(result.notifications.emergencyContacts, hasLength(1));
      expect(result.notifications.isEnabled(ChannelType.push), isTrue);
      expect(result.notifications.isEnabled(ChannelType.call), isFalse);
    });

    test('rejects other users, unknown values and missing booleans', () {
      expect(
        () => UserPreferencesMapper.preferences(
          snapshot(userId: 'user-B'),
          'user-A',
        ),
        throwsFormatException,
      );
      expect(
        () => UserPreferencesMapper.preferences(
          snapshot(textSize: 'HUGE'),
          'user-A',
        ),
        throwsFormatException,
      );
      expect(
        () => UserPreferencesMapper.preferences(
          snapshot()..remove('highContrast'),
          'user-A',
        ),
        throwsFormatException,
      );
      expect(
        () => UserPreferencesMapper.preferences(
          snapshot(quietHours: {'start': '10:00', 'end': '10:00'}),
          'user-A',
        ),
        throwsFormatException,
      );
      expect(
        () => UserPreferencesMapper.preferences(
          snapshot(
            policy: {
              'reminderMinutes': 30,
              'pendingAlertMinutes': 15,
              'omittedAlertMinutes': 40,
              'escalationMinutes': 60,
            },
          ),
          'user-A',
        ),
        throwsFormatException,
      );
    });
  });

  group('http', () {
    StoredSession session(
      String id, [
      SessionRole role = SessionRole.caregiver,
    ]) => StoredSession(
      accessToken: 'token',
      expiresAt: DateTime.utc(2030),
      owner: SessionOwner(
        id,
        role,
        careLinkId: role == SessionRole.caregiver ? null : 'link',
      ),
    );

    PreferencesApi api(Future<http.Response> Function(http.Request) handler) {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient(handler),
      );
      addTearDown(client.close);
      return PreferencesApi(client);
    }

    test('each field goes to its own endpoint with its own body', () async {
      final seen = <String, Object?>{};
      final remote = RemoteUserPreferences(
        api: api((request) async {
          seen['${request.method} ${request.url.path}'] = request.body.isEmpty
              ? null
              : jsonDecode(request.body);
          return http.Response(jsonEncode(snapshot()), 200);
        }),
        store: MemorySessionStore(session('user-A')),
      );
      await remote.get('user-A');
      await remote.update('user-A', const TextSizeChange(TextSizeLevel.large));
      await remote.update('user-A', const HighContrastChange(true));
      await remote.update('user-A', const DarkThemeChange(true));
      await remote.update('user-A', const ReducedMotionChange(true));
      await remote.update('user-A', const VoiceConfirmationChange(false));
      await remote.update('user-A', const ReadingAssistanceChange(true));
      expect(seen, {
        'GET /api/v1/users/user-A/preferences': null,
        'PUT /api/v1/users/user-A/preferences/text-size': {'textSize': 'LARGE'},
        'PUT /api/v1/users/user-A/preferences/contrast': {'enabled': true},
        'PUT /api/v1/users/user-A/preferences/dark-theme': {'enabled': true},
        'PUT /api/v1/users/user-A/preferences/reduced-motion': {
          'enabled': true,
        },
        'PUT /api/v1/users/user-A/preferences/voice-confirmation': {
          'enabled': false,
        },
        'PUT /api/v1/users/user-A/preferences/reading-assistance': {
          'enabled': true,
        },
      });
    });

    test('another user\'s preferences are never requested', () async {
      var calls = 0;
      final remote = RemoteUserPreferences(
        api: api((_) async {
          calls++;
          return http.Response(jsonEncode(snapshot()), 200);
        }),
        store: MemorySessionStore(session('user-B')),
      );
      final result = await remote.get('user-A');
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      expect(calls, 0);
    });

    test('restricted link-setup sessions are rejected', () async {
      var calls = 0;
      final remote = RemoteUserPreferences(
        api: api((_) async {
          calls++;
          return http.Response(jsonEncode(snapshot()), 200);
        }),
        store: MemorySessionStore(session('user-A', SessionRole.linkSetup)),
      );
      expect(await remote.get('user-A'), isA<AppFailure>());
      expect(calls, 0);
    });

    test('notification update sends HH:mm and requires the echo', () async {
      Object? body;
      final repo = RemoteNotificationPreferencesRepository(
        api: api((request) async {
          expect(
            request.url.path,
            '/api/v1/users/user-A/notification-preferences',
          );
          body = jsonDecode(request.body);
          return http.Response(
            jsonEncode(
              snapshot(quietHours: {'start': '22:00:00', 'end': '07:00:00'}),
            ),
            200,
          );
        }),
        store: MemorySessionStore(session('user-A')),
      );
      const channels = [
        NotificationChannel(ChannelType.push, true),
        NotificationChannel(ChannelType.sms, false),
      ];
      final ok = await repo.update(
        'user-A',
        NotificationPreferences(
          quietHours: QuietHours(22, 0, 7, 0),
          channels: channels,
        ),
      );
      expect(ok, isA<AppSuccess>());
      expect(body, {
        'quietHours': {'start': '22:00', 'end': '07:00'},
        'channels': [
          {'type': 'PUSH', 'enabled': true},
          {'type': 'SMS', 'enabled': false},
        ],
      });
      // The server answered quiet hours that were not requested.
      final mismatch = await repo.update(
        'user-A',
        const NotificationPreferences(channels: channels),
      );
      expect((mismatch as AppFailure).code, 'INVALID_PREFERENCES_RESPONSE');
    });

    test(
      'policy update compares policy and contacts with the receipt',
      () async {
        final repo = RemoteNotificationPreferencesRepository(
          api: api((request) async {
            expect(
              request.url.path,
              '/api/v1/users/user-A/notification-preferences/policy',
            );
            return http.Response(
              jsonEncode(
                snapshot(
                  contacts: [
                    {'name': 'Ana', 'phone': '+51987654321'},
                  ],
                ),
              ),
              200,
            );
          }),
          store: MemorySessionStore(session('user-A')),
        );
        final policy = NotificationPolicy.tryCreate(
          reminderMinutes: 5,
          pendingAlertMinutes: 15,
          omittedAlertMinutes: 30,
          escalationMinutes: 60,
        )!;
        final ok = await repo.updatePolicy('user-A', policy, [
          EmergencyContact.tryCreate('Ana', '+51987654321')!,
        ]);
        expect(ok, isA<AppSuccess>());
        final missing = await repo.updatePolicy('user-A', policy, const []);
        expect((missing as AppFailure).code, 'INVALID_PREFERENCES_RESPONSE');
      },
    );
  });

  group('offline first', () {
    late FakeRemote remote;
    late MemoryLocal local;
    late OfflineFirstUserPreferences repository;

    setUp(() {
      remote = FakeRemote();
      local = MemoryLocal();
      repository = OfflineFirstUserPreferences(remote: remote, local: local);
    });

    test('an online change is stored locally and acknowledged', () async {
      final result = await repository.update(
        'user-A',
        const DarkThemeChange(true),
      ) as AppSuccess<PreferenceUpdate>;
      expect(result.value.syncedWithServer, isTrue);
      expect(result.value.accessibility.darkTheme, isTrue);
      expect((await local.current('user-A')).darkTheme, isTrue);
      expect(await local.pending('user-A'), isEmpty);
      expect(remote.server.darkTheme, isTrue);
    });

    test('offline changes apply at once and stay pending', () async {
      remote.failure = 'NETWORK_UNAVAILABLE';
      final result = await repository.update(
        'user-A',
        const TextSizeChange(TextSizeLevel.extraLarge),
      ) as AppSuccess<PreferenceUpdate>;
      expect(result.value.syncedWithServer, isFalse);
      expect(
        (await local.current('user-A')).textSize,
        TextSizeLevel.extraLarge,
      );
      expect(await local.pending('user-A'), {AccessibilityField.textSize});
      expect(remote.server.textSize, TextSizeLevel.medium);
    });

    test(
      'sync sends only pending fields, one by one, then adopts the server',
      () async {
        remote.failure = 'NETWORK_UNAVAILABLE';
        await repository.update('user-A', const HighContrastChange(true));
        await repository.update('user-A', const DarkThemeChange(true));
        remote.failure = null;
        final result = await repository.sync('user-A');
        expect(result, isA<AppSuccess>());
        expect(remote.sent, [
          AccessibilityField.highContrast,
          AccessibilityField.darkTheme,
        ]);
        expect(await local.pending('user-A'), isEmpty);
        expect(remote.server.highContrast, isTrue);
        expect(remote.server.darkTheme, isTrue);
        expect((await local.current('user-A')).darkTheme, isTrue);
      },
    );

    test('the server wins for fields without pending changes', () async {
      remote.server = const AccessibilityPreferences(
        darkTheme: true,
        textSize: TextSizeLevel.large,
      );
      await repository.sync('user-A');
      final adopted = await local.current('user-A');
      expect(adopted.darkTheme, isTrue);
      expect(adopted.textSize, TextSizeLevel.large);
    });

    test('a failed sync keeps unsent fields pending', () async {
      remote.failure = 'NETWORK_UNAVAILABLE';
      await repository.update('user-A', const ReducedMotionChange(true));
      final result = await repository.sync('user-A');
      expect((result as AppFailure).code, 'NETWORK_UNAVAILABLE');
      expect(await local.pending('user-A'), {AccessibilityField.reducedMotion});
      expect((await local.current('user-A')).reducedMotion, isTrue);
    });

    test('a validation rejection restores the previous value', () async {
      remote.failure = 'REQUEST_VALIDATION_FAILED';
      final result = await repository.update(
        'user-A',
        const HighContrastChange(true),
      );
      expect((result as AppFailure).code, 'REQUEST_VALIDATION_FAILED');
      expect((await local.current('user-A')).highContrast, isFalse);
      expect(await local.pending('user-A'), isEmpty);
    });

    test('a receipt that ignores the change is invalid', () async {
      remote.echoStale = true;
      final result = await repository.update(
        'user-A',
        const DarkThemeChange(true),
      );
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
      expect(await local.pending('user-A'), {AccessibilityField.darkTheme});
    });

    test('owners are isolated from each other', () async {
      remote.failure = 'NETWORK_UNAVAILABLE';
      await repository.update('user-A', const DarkThemeChange(true));
      expect((await local.current('user-B')).darkTheme, isFalse);
      expect(await local.pending('user-B'), isEmpty);
    });
  });

  group('shared_preferences stores', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('values and the pending set round-trip per owner', () async {
      final store = SharedPreferencesAccessibilityStore();
      const value = AccessibilityPreferences(
        textSize: TextSizeLevel.large,
        highContrast: true,
        voiceConfirmation: false,
        darkTheme: true,
      );
      await store.save('user-A', value, {
        AccessibilityField.highContrast,
        AccessibilityField.textSize,
      });
      expect(await store.current('user-A'), value);
      expect(await store.pending('user-A'), {
        AccessibilityField.textSize,
        AccessibilityField.highContrast,
      });
      expect(await store.current('user-B'), AccessibilityPreferences.defaults);
    });

    test('watch emits the current value and then every save', () async {
      final store = SharedPreferencesAccessibilityStore();
      final seen = <AccessibilityPreferences>[];
      final subscription = store.watch('user-A').listen(seen.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);
      await store.save(
        'user-A',
        const AccessibilityPreferences(darkTheme: true),
        const {},
      );
      await Future<void>.delayed(Duration.zero);
      await store.save(
        'user-B',
        const AccessibilityPreferences(highContrast: true),
        const {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(seen, hasLength(2));
      expect(seen.first, AccessibilityPreferences.defaults);
      expect(seen.last.darkTheme, isTrue);
    });

    test('the language is stored per owner', () async {
      final store = SharedPreferencesLanguageStore();
      await store.write('user-A', AppLanguage.english);
      final language = await store.watch('user-A').first;
      expect(language, AppLanguage.english);
      expect(await store.watch('user-B').first, AppLanguage.spanish);
    });
  });
}
