import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_adult_profile_reader.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_pin.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in_with_pin.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/pin_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_pin_access.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/features/intake_execution/application/readmodels/agenda_week.dart';
import 'package:tata/features/intake_execution/application/readmodels/daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_week_agenda.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/remote/intake_api.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_intake_confirmation.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_intake_reader.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../test/support/memory_session_store.dart';

/// Opt-in real TCP/Spring probe for PIN access, the adult home and touch
/// confirmation with its idempotent retry.
/// The caregiver prepares one active treatment, then the adult signs in with
/// the PIN and reads the next intake and today's progress. Fixture secrets
/// never appear in output.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Supply the private local fixture path');
  }
  final properties = <String, String>{};
  for (final line in await File(arguments.single).readAsLines()) {
    if (line.startsWith('#') || !line.contains('=')) continue;
    final separator = line.indexOf('=');
    properties[line.substring(0, separator)] = line.substring(separator + 1);
  }
  final url = Uri.parse(properties['baseUrl'] ?? '');
  if (url.scheme != 'http' || url.host != '127.0.0.1') {
    throw ArgumentError('Only an isolated loopback backend is accepted');
  }
  final adultId = _required(properties, 'olderAdultId');
  final pin = _required(properties, 'pin');
  final client = ApiClient(baseUrl: url, client: http.Client());
  try {
    await _prepareTreatment(client, properties, adultId);

    final store = MemorySessionStore();
    final pins = RemotePinAccess(
      api: PinApi(client),
      store: store,
      clock: DateTime.now,
    );
    final wrong = pin == '0000' ? '1111' : '0000';
    final rejected = await SignInWithPin(pins)(adultId, wrong);
    _check(
      _code(rejected) == 'INVALID_PIN',
      'Incorrect PIN was not rejected as INVALID_PIN',
    );
    _check(store.current == null, 'Rejected PIN created local access');

    final signedIn = await SignInWithPin(pins)(adultId, pin);
    _check(signedIn is AppSuccess, 'PIN access failed');
    final owner = store.current?.owner;
    _check(
      owner?.id == adultId &&
          owner?.role == SessionRole.olderAdult &&
          owner?.careLinkId != null,
      'PIN session lacks the adult relationship scope',
    );
    stdout.writeln('PIN access: adult session scoped to its care link');

    final again = await RegisterPin(pins)(pin);
    _check(
      _code(again) == 'PIN_ALREADY_REGISTERED',
      'Enrolled adult did not report PIN_ALREADY_REGISTERED',
    );
    stdout.writeln('PIN setup: existing enrollment reported, setup continues');

    final profile = await RemoteAdultProfileReader(
      api: CareLinkApi(client),
      store: store,
    ).readOwn();
    _check(switch (profile) {
      AppSuccess(:final value) => value.fullName.isNotEmpty,
      AppFailure() => false,
    }, 'Adult could not read their own profile');
    stdout.writeln('Profile: own name readable for the home avatar');

    final intakes = RemoteIntakeReader(api: IntakeApi(client), store: store);
    final next = await GetNextIntake(intakes)();
    _check(
      next is AppSuccess<Intake?> && next.value?.olderAdultId == adultId,
      'Next intake was not readable after activation',
    );
    final progress = await GetDailyProgress(intakes, DateTime.now)();
    _check(
      progress is AppSuccess<DailyProgress> && progress.value.total > 0,
      'Daily progress did not include the scheduled intakes',
    );
    if (next case AppSuccess(:final value?)) {
      stdout.writeln(
        'Home: next intake ${value.status.name} at '
        '${value.scheduledAt.toIso8601String()}',
      );
    }
    if (progress case AppSuccess(:final value)) {
      stdout.writeln('Home: ${value.taken}/${value.total} taken today');
    }

    // The next intake is about 25 minutes ahead, so it is confirmed on time.
    final nextId = switch (next) {
      AppSuccess(:final value?) => value.id,
      _ => throw StateError('No next intake to confirm'),
    };
    final confirmations = RemoteIntakeConfirmation(
      api: IntakeApi(client),
      store: store,
    );
    final first = await ConfirmIntake(confirmations)(nextId);
    _check(switch (first) {
      AppSuccess(:final value) =>
        value.intake.status == IntakeStatus.confirmed &&
            !value.alreadyConfirmed,
      AppFailure() => false,
    }, 'Touch confirmation was not recorded on time');
    final replay = await ConfirmIntake(confirmations)(nextId);
    _check(switch (replay) {
      AppSuccess(:final value) => value.alreadyConfirmed,
      AppFailure() => false,
    }, 'A repeated confirmation was not reported as already confirmed');
    stdout.writeln('Confirm: on time, and the retry created no duplicate');

    final detail = await GetIntakeDetail(intakes)(nextId);
    _check(switch (detail) {
      AppSuccess(:final value) => value.taken && value.confirmedAt != null,
      AppFailure() => false,
    }, 'Detail does not show the recorded confirmation');
    final week = await GetWeekAgenda(intakes)(
      AgendaWeek.containing(DateTime.now()),
    );
    _check(switch (week) {
      AppSuccess(:final value) => value.any(
        (intake) => intake.id == nextId && intake.taken,
      ),
      AppFailure() => false,
    }, 'Weekly agenda does not show the confirmed intake');
    stdout.writeln('Agenda: the confirmed dose appears as taken this week');

    // The second dose is confirmed as if saved offline a moment ago.
    final secondId = switch (await GetNextIntake(intakes)()) {
      AppSuccess(:final value?) => value.id,
      _ => throw StateError('No second intake to replay'),
    };
    final future = await confirmations.replay(
      secondId,
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    _check(
      _code(future) == 'INVALID_CONFIRMATION_TIME',
      'A device time in the future was not rejected',
    );
    final tapped = DateTime.now().toUtc();
    final delivered = await confirmations.replay(secondId, tapped);
    _check(switch (delivered) {
      AppSuccess(:final value) =>
        value.intake.status == IntakeStatus.confirmed &&
            value.intake.confirmedAt == tapped,
      AppFailure() => false,
    }, 'The offline tap time was not stored as the evidence');
    stdout.writeln('Offline: tap time stored; a future device time rejected');
    stdout.writeln('PIN + Home + confirmation probe passed');
  } finally {
    client.close();
  }
}

/// Signs in the caregiver and activates a treatment with doses later today
/// (UTC), so the adult has a pending next intake.
Future<void> _prepareTreatment(
  ApiClient client,
  Map<String, String> properties,
  String adultId,
) async {
  final store = MemorySessionStore();
  final sessions = RemoteSessionRepository(
    api: SessionApi(client),
    store: store,
    clock: DateTime.now,
  );
  final signedIn = await SignIn(sessions)(
    _required(properties, 'caregiverEmail'),
    _required(properties, 'caregiverPassword'),
  );
  _check(signedIn is AppSuccess, 'Caregiver sign-in failed');
  final caregiverId = store.current!.owner.id;
  final token = store.current!.accessToken;
  final adult = Uri.encodeComponent(adultId);

  final medication = await client.request(
    'POST',
    'api/v1/older-adults/$adult/medications',
    token: token,
    body: {
      'caregiverId': caregiverId,
      'name': 'Losartán',
      'presentation': '50 mg, tableta',
    },
  );
  _check(medication.status == 201, 'Medication was not registered');
  final medicationId = _id(medication.body);

  final treatment = await client.request(
    'POST',
    'api/v1/older-adults/$adult/treatments',
    token: token,
    body: {'caregiverId': caregiverId, 'name': 'Control de presión'},
  );
  _check(treatment.status == 201, 'Treatment was not created');
  final treatmentId = Uri.encodeComponent(_id(treatment.body));

  String at(Duration offset) {
    final time = DateTime.now().toUtc().add(offset);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:00';
  }

  final regimen = await client.request(
    'PUT',
    'api/v1/treatments/$treatmentId/regimen',
    token: token,
    body: {
      'caregiverId': caregiverId,
      'medicationId': medicationId,
      'dose': '1 tableta',
      'frequency': 'DAILY',
      'scheduledTimes': [
        at(const Duration(minutes: 25)),
        at(const Duration(minutes: 50)),
      ],
      'instructions': 'Con un vaso de agua',
      'reminderLeadMinutes': 10,
    },
  );
  _check(regimen.status == 200, 'Regimen was not configured');

  final activation = await client.request(
    'POST',
    'api/v1/treatments/$treatmentId/activation',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );
  _check(activation.status == 200, 'Treatment was not activated');
  stdout.writeln('Setup: caregiver activated a treatment for the adult');
}

String? _code(AppResult<Object?> result) => switch (result) {
  AppFailure(:final code) => code,
  AppSuccess() => null,
};

String _required(Map<String, String> properties, String key) {
  final value = properties[key];
  if (value == null || value.isEmpty) {
    throw ArgumentError('Missing fixture property $key');
  }
  return value;
}

String _id(Object? body) {
  if (body is Map<String, dynamic> && body['id'] is String) {
    return body['id'] as String;
  }
  throw const FormatException('Missing resource id');
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
