import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tata/features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'package:tata/features/care_link/application/readmodels/older_adult_profile.dart';
import 'package:tata/features/care_link/application/usecases/generate_linking_code.dart';
import 'package:tata/features/care_link/application/usecases/register_older_adult.dart';
import 'package:tata/features/care_link/domain/entities/care_link.dart';
import 'package:tata/features/care_link/domain/value_objects/care_link_invitation.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/features/identity_subscription/application/usecases/complete_password_recovery.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_caregiver.dart';
import 'package:tata/features/identity_subscription/application/usecases/request_password_recovery.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/verify_email.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/password_recovery_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/registration_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_password_recovery.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../test/support/memory_session_store.dart';

/// Explicit loopback-only probe against the test host's ephemeral code source.
/// It does not send external mail or certify native secure storage.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Supply a private fixture path');
  }
  final fixture = File(arguments.single);
  final properties = <String, String>{};
  for (final line in await fixture.readAsLines()) {
    if (line.startsWith('#') || !line.contains('=')) continue;
    final separator = line.indexOf('=');
    properties[line.substring(0, separator)] = line
        .substring(separator + 1)
        .replaceAll(r'\:', ':')
        .replaceAll(r'\=', '=');
  }
  final url = Uri.parse(properties['baseUrl'] ?? '');
  final code = properties['recoveryCode'];
  if (url.scheme != 'http' || url.host != '127.0.0.1' || code == null) {
    throw ArgumentError(
      'Only an isolated test host with code fixture is accepted',
    );
  }
  final client = ApiClient(baseUrl: url, client: http.Client());
  final store = MemorySessionStore();
  final api = SessionApi(client);
  final sessions = RemoteSessionRepository(
    api: api,
    store: store,
    clock: DateTime.now,
  );
  final registration = RemoteAccountRegistration(
    api: RegistrationApi(client),
    store: store,
    clock: DateTime.now,
  );
  final recovery = RemotePasswordRecovery(PasswordRecoveryApi(client));
  final email =
      'flutter-${DateTime.now().microsecondsSinceEpoch}@example.invalid';
  const password = 'first-probe-password';
  const newPassword = 'new-probe-password';
  try {
    final created = await RegisterCaregiver(registration)(
      'Flutter contract',
      email,
      password,
    );
    _check(
      created is AppSuccess<String> && store.current == null,
      'Pending account created access',
    );
    final id = (created as AppSuccess<String>).value;
    _check(
      await SignIn(sessions)(email, password) is AppFailure,
      'Unverified account authenticated',
    );
    final duplicate = await RegisterCaregiver(registration)(
      'Flutter contract',
      email,
      password,
    );
    _check(
      duplicate is AppFailure<String> && duplicate.code == 'DUPLICATE_EMAIL',
      'Duplicate registration contract mismatch',
    );
    _check(
      await registration.requestVerification(id, email) is AppSuccess,
      'Verification resend failed',
    );
    _check(
      await VerifyEmail(registration)(id, email, code) is AppSuccess &&
          store.current?.owner.id == id,
      'Verification did not bind issued session',
    );
    final originalToken = store.current!.accessToken;
    _check(
      await sessions.restore() is AppSuccess,
      'Verified session current failed',
    );
    final careLinks = RemoteCareLinkRepository(
      api: CareLinkApi(client),
      store: store,
      clock: DateTime.now,
    );
    final initialLinks = await careLinks.readConfirmed();
    _check(
      initialLinks is AppSuccess<List<CaregiverLinkSummary>> &&
          initialLinks.value.isEmpty,
      'New account returned unrelated confirmed profiles',
    );
    final adult = await RegisterOlderAdult(careLinks, DateTime.now)(
      'Flutter relative',
      DateTime.utc(1958, 5, 3),
    );
    _check(
      adult is AppSuccess<OlderAdultProfile> && adult.value.caregiverId == id,
      'Caregiver profile registration failed',
    );
    final adultId = (adult as AppSuccess<OlderAdultProfile>).value.id;
    final issued = await GenerateLinkingCode(careLinks)(adultId);
    _check(
      issued is AppSuccess<CareLink> &&
          issued.value.olderAdultId == adultId &&
          issued.value.status == CareLinkStatus.pending &&
          issued.value.code!.isValidAt(DateTime.now()),
      'Temporary linking receipt is invalid',
    );
    final pendingLinks = await careLinks.readConfirmed();
    _check(
      pendingLinks is AppSuccess<List<CaregiverLinkSummary>> &&
          pendingLinks.value.isEmpty &&
          store.current?.owner.id == id,
      'Pending evidence invented consent or replaced the caregiver session',
    );
    stdout.writeln(
      'FLUTTER_LOCAL_CAREGIVER_SETUP_PASS: authorized list, adult registration and pending linking evidence without consent',
    );
    final adultStore = MemorySessionStore();
    final consent = RemoteCareLinkConsent(
      api: CareLinkApi(client),
      store: adultStore,
      clock: DateTime.now,
    );
    final issuedLink = (issued as AppSuccess<CareLink>).value;
    _check(
      await consent.accept(
            CareLinkInvitation(caregiverId: id, code: issuedLink.code!.value),
          ) is AppSuccess &&
          adultStore.current?.owner.role == SessionRole.linkSetup,
      'Invitation did not establish restricted access',
    );
    final restrictedToken = adultStore.current!.accessToken;
    final adultSessions = RemoteSessionRepository(
      api: api,
      store: adultStore,
      clock: DateTime.now,
    );
    _check(
      await adultSessions.restore() is AppSuccess &&
          adultStore.current?.owner.careLinkId == issuedLink.id,
      'Restricted session scope did not restore',
    );
    _check(
      (await client.request(
            'GET',
            'api/v1/care-links',
            token: restrictedToken,
            queryParameters: {'caregiverId': id},
          )).status ==
          403,
      'Restricted token accessed caregiver resources',
    );
    _check(
      await consent.pending() is AppSuccess,
      'Pending consent could not be loaded',
    );
    _check(
      await consent.decide(true) is AppSuccess &&
          adultStore.current?.owner.role == SessionRole.olderAdult,
      'Approval did not issue scoped adult access',
    );
    _check(
      (await api.current(restrictedToken)).status == 401,
      'Approved setup credential remains active',
    );
    _check(
      await adultSessions.restore() is AppSuccess,
      'Full adult scope did not restore',
    );
    final confirmedLinks = await careLinks.readConfirmed();
    _check(
      confirmedLinks is AppSuccess<List<CaregiverLinkSummary>> &&
          confirmedLinks.value.any((link) => link.olderAdultId == adultId),
      'Consent did not expose the authorized caregiver list item',
    );
    final activeAdultToken = adultStore.current!.accessToken;
    _check(
      await consent.withdraw() is AppSuccess && adultStore.current == null,
      'Flutter withdrawal did not acknowledge revocation and clear access',
    );
    _check(
      (await api.current(activeAdultToken)).status == 401,
      'Withdrawn adult credential remains valid',
    );
    _check(
      await adultSessions.restore() is AppSuccess && adultStore.current == null,
      'Withdrawn adult access restored',
    );
    final renewed = await GenerateLinkingCode(careLinks)(adultId);
    _check(
      renewed is AppSuccess<CareLink>,
      'Revoked relationship could not receive new evidence',
    );
    _check(
      await consent.accept(
        CareLinkInvitation(
          caregiverId: id,
          code: (renewed as AppSuccess<CareLink>).value.code!.value,
        ),
      ) is AppSuccess,
      'Renewed invitation could not be reviewed',
    );
    _check(
      await consent.decide(false) is AppSuccess && adultStore.current == null,
      'Rejection left adult access available',
    );
    final rejectedLinks = await careLinks.readConfirmed();
    _check(
      rejectedLinks is AppSuccess<List<CaregiverLinkSummary>> &&
          rejectedLinks.value.isEmpty,
      'Rejected relationship appears confirmed',
    );
    stdout.writeln(
      'FLUTTER_LOCAL_ADULT_CONSENT_PASS: restricted restore, denied caregiver access, approval, token replacement and rejection',
    );
    _check(
      await RequestPasswordRecovery(recovery)('absent-$email') is AppSuccess,
      'Unknown-email recovery did not accept uniformly',
    );
    _check(
      await RequestPasswordRecovery(recovery)(email) is AppSuccess,
      'Recovery request failed',
    );
    final wrongCode = code == '000000' ? '000001' : '000000';
    final invalid = await CompletePasswordRecovery(recovery)(
      email,
      wrongCode,
      newPassword,
    );
    _check(
      invalid is AppFailure && invalid.code == 'INVALID_RECOVERY_CODE',
      'Invalid recovery challenge accepted',
    );
    _check(
      await CompletePasswordRecovery(recovery)(email, code, newPassword)
          is AppSuccess,
      'Password replacement failed',
    );
    _check(
      (await api.current(originalToken)).status == 401,
      'Recovery did not revoke prior server session',
    );
    _check(
      await sessions.restore() is AppSuccess && store.current == null,
      'Revoked local session restored',
    );
    final replay = await CompletePasswordRecovery(recovery)(
      email,
      code,
      newPassword,
    );
    _check(
      replay is AppFailure && replay.code == 'INVALID_RECOVERY_CODE',
      'Consumed recovery code replayed',
    );
    _check(
      await SignIn(sessions)(email, password) is AppFailure,
      'Old password still authenticates',
    );
    _check(
      await SignIn(sessions)(email, newPassword) is AppSuccess &&
          store.current?.owner.id == id,
      'New password did not authenticate original account',
    );
    _check(
      await sessions.signOut() is AppSuccess && store.current == null,
      'Final cleanup failed',
    );
    stdout.writeln(
      'FLUTTER_LOCAL_IDENTITY_CONTRACT_PASS: pending registration, duplicate, resend, verification, recovery, revocation, replay and password replacement',
    );
  } finally {
    client.close();
    await File('${fixture.path}.done').writeAsString('finished');
  }
}

void _check(bool value, String message) {
  if (!value) throw StateError(message);
}
