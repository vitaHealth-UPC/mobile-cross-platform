import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/care_link/application/usecases/accept_care_link.dart';
import '../../features/care_link/application/usecases/generate_linking_code.dart';
import '../../features/care_link/application/usecases/register_consent.dart';
import '../../features/care_link/application/usecases/register_older_adult.dart';
import '../../features/care_link/application/usecases/withdraw_consent.dart';
import '../../features/care_link/infrastructure/remote/care_link_api.dart';
import '../../features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import '../../features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import '../../features/care_link/presentation/bloc/consent/consent_bloc.dart';
import '../../features/care_link/presentation/bloc/profiles/profiles_bloc.dart';
import '../../features/identity_subscription/application/usecases/complete_password_recovery.dart';
import '../../features/identity_subscription/application/usecases/register_caregiver.dart';
import '../../features/identity_subscription/application/usecases/request_password_recovery.dart';
import '../../features/identity_subscription/application/usecases/request_verification.dart';
import '../../features/identity_subscription/application/usecases/restore_session.dart';
import '../../features/identity_subscription/application/usecases/sign_in.dart';
import '../../features/identity_subscription/application/usecases/sign_out.dart';
import '../../features/identity_subscription/application/usecases/verify_email.dart';
import '../../features/identity_subscription/infrastructure/remote/password_recovery_api.dart';
import '../../features/identity_subscription/infrastructure/remote/registration_api.dart';
import '../../features/identity_subscription/infrastructure/remote/session_api.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_password_recovery.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import '../../features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/security/secure_session_store.dart';
import '../config/app_config.dart';

/// Owns process-wide adapters. Routes own and close the blocs they create.
final class AppDependencies {
  AppDependencies._(
    this._client,
    this._sessions,
    this._registration,
    this._careLinks,
    this._consent,
  );

  /// Composes real HTTP and secure storage using environment configuration.
  factory AppDependencies.production() {
    final client = ApiClient(
      baseUrl: AppConfig.fromEnvironment().apiBaseUrl,
      client: http.Client(),
    );
    final store = SecureSessionStore(
      storage: const FlutterSecureStorage(),
      clock: DateTime.now,
    );
    return AppDependencies._(
      client,
      RemoteSessionRepository(
        api: SessionApi(client),
        store: store,
        clock: DateTime.now,
      ),
      RemoteAccountRegistration(
        api: RegistrationApi(client),
        store: store,
        clock: DateTime.now,
      ),
      RemoteCareLinkRepository(
        api: CareLinkApi(client),
        store: store,
        clock: DateTime.now,
      ),
      RemoteCareLinkConsent(
        api: CareLinkApi(client),
        store: store,
        clock: DateTime.now,
      ),
    );
  }

  final ApiClient _client;
  final RemoteSessionRepository _sessions;
  final RemoteAccountRegistration _registration;
  final RemoteCareLinkRepository _careLinks;
  final RemoteCareLinkConsent _consent;

  /// Creates consent state without granting any caregiver or clinical capability.
  ConsentBloc createConsentBloc() => ConsentBloc(
    consent: _consent,
    accept: AcceptCareLink(_consent),
    decide: RegisterConsent(_consent),
    withdraw: WithdrawConsent(_consent),
  );

  /// Creates caregiver setup state sharing the application's captured session store.
  ProfilesBloc createProfilesBloc() => ProfilesBloc(
    reader: _careLinks,
    register: RegisterOlderAdult(_careLinks, DateTime.now),
    generate: GenerateLinkingCode(_careLinks),
  );

  /// Creates route-owned recovery state without session persistence capabilities.
  RecoveryBloc createRecoveryBloc() {
    final recovery = RemotePasswordRecovery(PasswordRecoveryApi(_client));
    return RecoveryBloc(
      request: RequestPasswordRecovery(recovery),
      complete: CompletePasswordRecovery(recovery),
    );
  }

  /// Creates registration state sharing the application session store.
  RegistrationBloc createRegistrationBloc() => RegistrationBloc(
    register: RegisterCaregiver(_registration),
    verify: VerifyEmail(_registration),
    resend: RequestVerification(_registration),
  );

  /// Creates the access authority; its provider is responsible for closing it.
  AccessBloc createAccessBloc() => AccessBloc(
    signIn: SignIn(_sessions),
    restore: RestoreSession(_sessions),
    signOut: SignOut(_sessions),
  );

  void dispose() => _client.close();
}
