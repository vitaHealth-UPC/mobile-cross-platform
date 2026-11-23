import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/accessibility_preferences/application/ports/preferences_ports.dart';
import '../../features/accessibility_preferences/application/usecases/preferences_usecases.dart';
import '../../features/accessibility_preferences/infrastructure/local/shared_preferences_stores.dart';
import '../../features/accessibility_preferences/infrastructure/remote/preferences_api.dart';
import '../../features/accessibility_preferences/infrastructure/repositories/offline_first_user_preferences.dart';
import '../../features/accessibility_preferences/infrastructure/repositories/remote_user_preferences.dart';
import '../../features/accessibility_preferences/presentation/bloc/accessibility/accessibility_bloc.dart';
import '../../features/accessibility_preferences/presentation/bloc/notifications/notification_preferences_bloc.dart';
import '../../features/accessibility_preferences/presentation/cubit/appearance_cubit.dart';
import '../../features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import '../../features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import '../../features/adherence_analytics/application/usecases/get_recommendations.dart';
import '../../features/adherence_analytics/infrastructure/remote/analytics_api.dart';
import '../../features/adherence_analytics/infrastructure/repositories/remote_adherence_repository.dart';
import '../../features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import '../../features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import '../../features/adherence_analytics/presentation/bloc/level/level_state.dart';
import '../../features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import '../../features/care_link/application/usecases/accept_care_link.dart';
import '../../features/care_link/application/usecases/generate_linking_code.dart';
import '../../features/care_link/application/usecases/register_consent.dart';
import '../../features/care_link/application/usecases/register_older_adult.dart';
import '../../features/care_link/application/usecases/withdraw_consent.dart';
import '../../features/care_link/infrastructure/remote/care_link_api.dart';
import '../../features/care_link/infrastructure/repositories/remote_adult_profile_reader.dart';
import '../../features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import '../../features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import '../../features/care_link/presentation/bloc/consent/consent_bloc.dart';
import '../../features/care_link/presentation/bloc/profiles/profiles_bloc.dart';
import '../../features/identity_subscription/application/ports/remembered_adult_store.dart';
import '../../features/identity_subscription/application/readmodels/remembered_adult.dart';
import '../../features/identity_subscription/application/usecases/complete_password_recovery.dart';
import '../../features/identity_subscription/application/usecases/register_caregiver.dart';
import '../../features/identity_subscription/application/usecases/register_pin.dart';
import '../../features/identity_subscription/application/usecases/request_password_recovery.dart';
import '../../features/identity_subscription/application/usecases/request_verification.dart';
import '../../features/identity_subscription/application/usecases/restore_session.dart';
import '../../features/identity_subscription/application/usecases/sign_in.dart';
import '../../features/identity_subscription/application/usecases/sign_in_with_pin.dart';
import '../../features/identity_subscription/application/usecases/sign_out.dart';
import '../../features/identity_subscription/application/usecases/verify_email.dart';
import '../../features/identity_subscription/infrastructure/local/secure_remembered_adult_store.dart';
import '../../features/identity_subscription/infrastructure/remote/password_recovery_api.dart';
import '../../features/identity_subscription/infrastructure/remote/pin_api.dart';
import '../../features/identity_subscription/infrastructure/remote/registration_api.dart';
import '../../features/identity_subscription/infrastructure/remote/session_api.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_password_recovery.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_pin_access.dart';
import '../../features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import '../../features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/pin/pin_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import '../../features/intake_execution/application/ports/intake_confirmation.dart';
import '../../features/intake_execution/application/ports/intake_local_store.dart';
import '../../features/intake_execution/application/ports/intake_reader.dart';
import '../../features/intake_execution/application/ports/intake_sync.dart';
import '../../features/intake_execution/application/usecases/confirm_intake.dart';
import '../../features/intake_execution/application/usecases/get_daily_progress.dart';
import '../../features/intake_execution/application/usecases/get_intake_detail.dart';
import '../../features/intake_execution/application/usecases/get_next_intake.dart';
import '../../features/intake_execution/application/usecases/get_week_agenda.dart';
import '../../features/intake_execution/application/usecases/replay_pending_confirmations.dart';
import '../../features/intake_execution/infrastructure/local/dao/intake_dao.dart';
import '../../features/intake_execution/infrastructure/local/intake_database.dart';
import '../../features/intake_execution/infrastructure/remote/intake_api.dart';
import '../../features/intake_execution/infrastructure/repositories/offline_intake_repository.dart';
import '../../features/intake_execution/infrastructure/repositories/remote_intake_confirmation.dart';
import '../../features/intake_execution/infrastructure/repositories/remote_intake_reader.dart';
import '../../features/intake_execution/infrastructure/sync/intake_sync_coordinator.dart';
import '../../features/intake_execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../../features/intake_execution/presentation/bloc/dose/dose_bloc.dart';
import '../../features/intake_execution/presentation/bloc/home/home_bloc.dart';
import '../../features/treatment_management/application/readmodels/treatment_readmodels.dart';
import '../../features/treatment_management/application/usecases/medication_usecases.dart';
import '../../features/treatment_management/application/usecases/regimen_usecases.dart';
import '../../features/treatment_management/application/usecases/treatment_usecases.dart';
import '../../features/treatment_management/infrastructure/remote/treatment_api.dart';
import '../../features/treatment_management/infrastructure/repositories/remote_medication_management_repository.dart';
import '../../features/treatment_management/infrastructure/repositories/remote_treatment_lifecycle_repository.dart';
import '../../features/treatment_management/infrastructure/repositories/remote_treatment_readers.dart';
import '../../features/treatment_management/infrastructure/repositories/remote_treatment_repository.dart';
import '../../features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import '../../features/treatment_management/presentation/bloc/medication_registration/medication_registration_bloc.dart';
import '../../features/treatment_management/presentation/bloc/my_medications/my_medications_bloc.dart';
import '../../features/treatment_management/presentation/bloc/treatment_list/treatment_list_bloc.dart';
import '../../features/treatment_management/presentation/bloc/treatment_management/treatment_management_bloc.dart';
import '../../features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../shared/application/session/session_store.dart';
import '../../shared/common/result/app_result.dart';
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
    this._pins,
    this._rememberedAdults,
    this._intakes,
    this._adultProfiles,
    this._confirmations,
    this._localIntakes,
    this._intakeRepository,
    this._intakeSync,
    this._intakeDatabase,
    this._adherence,
    this._treatmentApi,
    this._preferencesApi,
    this._sessionStore,
    this._accessibilityStore,
    this._languageStore,
  );

  /// Composes real HTTP and secure storage using environment configuration.
  factory AppDependencies.production() {
    final config = AppConfig.fromEnvironment();
    final client = ApiClient(baseUrl: config.apiBaseUrl, client: http.Client());
    final store = SecureSessionStore(
      storage: const FlutterSecureStorage(),
      clock: DateTime.now,
    );
    final database = IntakeDatabase.onDevice();
    final localIntakes = IntakeDao(database);
    final remoteConfirmations = RemoteIntakeConfirmation(
      api: IntakeApi(client),
      store: store,
    );
    final intakes = OfflineIntakeRepository(
      remoteReader: RemoteIntakeReader(api: IntakeApi(client), store: store),
      remoteConfirmation: remoteConfirmations,
      local: localIntakes,
      store: store,
      clock: DateTime.now,
    );
    final sync = IntakeSyncCoordinator(
      store: store,
      repository: intakes,
      replay: ReplayPendingConfirmations(
        remoteConfirmations,
        localIntakes,
        (owner) => store.current?.owner == owner,
      ),
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
      RemotePinAccess(api: PinApi(client), store: store, clock: DateTime.now),
      const SecureRememberedAdultStore(FlutterSecureStorage()),
      intakes,
      RemoteAdultProfileReader(api: CareLinkApi(client), store: store),
      intakes,
      localIntakes,
      intakes,
      sync,
      database,
      RemoteAdherenceRepository(
        api: AnalyticsApi(client),
        store: store,
        zoneId: config.calendarZone,
      ),
      TreatmentApi(client),
      PreferencesApi(client),
      store,
      SharedPreferencesAccessibilityStore(),
      SharedPreferencesLanguageStore(),
    );
  }

  final ApiClient _client;
  final RemoteSessionRepository _sessions;
  final RemoteAccountRegistration _registration;
  final RemoteCareLinkRepository _careLinks;
  final RemoteCareLinkConsent _consent;
  final RemotePinAccess _pins;
  final RememberedAdultStore _rememberedAdults;
  final IntakeReader _intakes;
  final RemoteAdultProfileReader _adultProfiles;
  final IntakeConfirmation _confirmations;
  final IntakeLocalStore _localIntakes;
  final OfflineIntakeRepository _intakeRepository;
  final IntakeSyncCoordinator _intakeSync;
  final IntakeDatabase _intakeDatabase;
  final RemoteAdherenceRepository _adherence;

  /// Delivers confirmations saved while the device had no connection.
  IntakeSync get intakeSync => _intakeSync;

  final TreatmentApi _treatmentApi;
  final PreferencesApi _preferencesApi;
  final SessionStore _sessionStore;
  final AccessibilityLocalStore _accessibilityStore;
  final ApplicationLanguageStore _languageStore;

  /// Treatment Management blocs; each factory shares the captured session store.
  TreatmentFactories get treatmentFactories {
    final medications = RemoteMedicationManagementRepository(
      api: _treatmentApi,
      store: _sessionStore,
    );
    final lifecycle = RemoteTreatmentLifecycleRepository(
      api: _treatmentApi,
      store: _sessionStore,
    );
    final treatmentReader = RemoteTreatmentReader(
      api: _treatmentApi,
      store: _sessionStore,
    );
    final detail = GetTreatmentDetail(treatmentReader);
    final list = ListMedications(medications);
    final configure = ConfigureTreatment(lifecycle);
    final changeStatus = ChangeTreatmentStatus(lifecycle);
    return TreatmentFactories(
      createListBloc: (olderAdultId) => TreatmentListBloc(
        list: ListTreatments(treatmentReader),
        olderAdultId: olderAdultId,
      ),
      createRegistrationBloc: (olderAdultId) => MedicationRegistrationBloc(
        register: RegisterMedication(
          RemoteTreatmentRepository(api: _treatmentApi, store: _sessionStore),
        ),
        olderAdultId: olderAdultId,
      ),
      createMedicationsBloc: (olderAdultId) => MedicationManagementBloc(
        list: list,
        update: UpdateMedication(medications),
        deactivate: DeactivateMedication(medications),
        reactivate: ReactivateMedication(medications),
        olderAdultId: olderAdultId,
      ),
      createSetupBloc: (olderAdultId, medicationId) => TreatmentSetupBloc(
        create: CreateTreatment(
          RemoteTreatmentRepository(api: _treatmentApi, store: _sessionStore),
        ),
        basics: const SetDoseFrequency(),
        schedule: const SetScheduleInstructions(),
        reminder: const SetReminderPolicy(),
        read: detail,
        configure: configure,
        changeStatus: changeStatus,
        olderAdultId: olderAdultId,
        medicationId: medicationId,
      ),
      createManagementBloc: (treatmentId, olderAdultId) =>
          TreatmentManagementBloc(
            detail: detail,
            medications: list,
            configure: configure,
            changeStatus: changeStatus,
            reactivate: ReactivateMedication(medications),
            deactivate: DeactivateMedication(medications),
            treatmentId: treatmentId,
            olderAdultId: olderAdultId,
          ),
      createMyMedicationsBloc: () => MyMedicationsBloc(
        overview: GetMyMedicationsOverview(
          RemoteMyMedicationsReader(api: _treatmentApi, store: _sessionStore),
          // The next dose belongs to the intake context; the app layer composes it.
          () async => switch (await GetNextIntake(_intakes).call()) {
            AppSuccess(:final value) => AppSuccess(
              value == null
                  ? null
                  : MedicationNextDose(
                      intakeId: value.id,
                      medicationId: value.medicationId,
                      medicationName: value.medicationName,
                      scheduledAt: value.scheduledAt,
                    ),
            ),
            AppFailure(:final code) => AppFailure(code),
          },
        ),
      ),
    );
  }

  /// One shared instance: it serializes every preference write of the process, and the
  /// app-wide appearance observes the same device copy that the screens edit.
  late final UserPreferencesRepository _preferences =
      OfflineFirstUserPreferences(
        remote: RemoteUserPreferences(
          api: _preferencesApi,
          store: _sessionStore,
        ),
        local: _accessibilityStore,
      );

  /// Accessibility & Preferences blocs.
  PreferencesFactories get preferencesFactories {
    final preferences = _preferences;
    final notifications = RemoteNotificationPreferencesRepository(
      api: _preferencesApi,
      store: _sessionStore,
    );
    return PreferencesFactories(
      createAccessibilityBloc: (userId) => AccessibilityBloc(
        observe: ObserveAccessibility(preferences),
        observeLanguage: ObserveApplicationLanguage(_languageStore),
        update: UpdateAccessibility(preferences),
        changeLanguage: ChangeApplicationLanguage(_languageStore),
        sync: SyncUserPreferences(preferences),
        userId: userId,
      ),
      createNotificationsBloc: (userId) => NotificationPreferencesBloc(
        get: GetNotificationPreferences(notifications),
        update: UpdateNotificationPreferences(notifications),
        updatePolicy: UpdateNotificationPolicy(notifications),
        userId: userId,
      ),
    );
  }

  /// App-wide appearance of the signed-in owner.
  AppearanceCubit createAppearanceCubit() => AppearanceCubit(
    observeAccessibility: ObserveAccessibility(_preferences),
    observeLanguage: ObserveApplicationLanguage(_languageStore),
    sync: SyncUserPreferences(_preferences),
  );

  /// Adult remembered on this device after PIN enrollment, if any.
  Future<RememberedAdult?> readRememberedAdult() => _rememberedAdults.read();

  /// Stores the PIN shortcut after the server acknowledged enrollment.
  Future<void> rememberAdult(RememberedAdult adult) =>
      _rememberedAdults.remember(adult);

  /// Removes the PIN shortcut and the adult's clinical data from this device,
  /// for example after consent withdrawal.
  Future<void> forgetRememberedAdult() async {
    final adult = await _rememberedAdults.read();
    await _rememberedAdults.forget();
    if (adult != null) await _localIntakes.clearAdult(adult.id);
  }

  /// Display name of the adult in the current session, or null if unreadable.
  Future<String?> readAdultName() async =>
      switch (await _adultProfiles.readOwn()) {
        AppSuccess(:final value) => value.fullName,
        AppFailure() => null,
      };

  /// Creates PIN enrollment state for the current full adult session.
  PinBloc createPinSetupBloc() => PinBloc.setup(register: RegisterPin(_pins));

  /// Creates PIN access state for the remembered adult [olderAdultId].
  PinBloc createPinAccessBloc(String olderAdultId) =>
      PinBloc.access(signIn: SignInWithPin(_pins), olderAdultId: olderAdultId);

  /// Creates the weekly agenda state for the current adult session.
  AgendaBloc createAgendaBloc() =>
      AgendaBloc(agenda: GetWeekAgenda(_intakes), clock: DateTime.now);

  /// Creates the detail and touch-confirmation state of one dose.
  DoseBloc createDoseBloc(String intakeId) => DoseBloc(
    intakeId: intakeId,
    detail: GetIntakeDetail(_intakes),
    confirm: ConfirmIntake(_confirmations),
    next: GetNextIntake(_intakes),
  );

  /// Creates the adult home state; day boundaries follow the device clock.
  HomeBloc createHomeBloc() => HomeBloc(
    next: GetNextIntake(_intakes),
    progress: GetDailyProgress(_intakes, DateTime.now),
  );

  /// Creates the adherence history state of [olderAdultId], read with the
  /// session of the caregiver of that link or of the adult themselves.
  HistoryBloc createAdherenceHistoryBloc(String olderAdultId) => HistoryBloc(
    olderAdultId: olderAdultId,
    summary: GetAdherenceSummary(_adherence),
  );

  /// Creates the adherence level of [olderAdultId] for a screen that shows it
  /// as a card, such as the person profile.
  LevelBloc createAdherenceLevelBloc(String olderAdultId) => LevelBloc(
    olderAdultId: olderAdultId,
    summary: GetAdherenceSummary(_adherence),
  );

  /// Creates the weekly adherence of [olderAdultId] for a screen that shows it
  /// as a card, such as the family summary.
  LevelBloc createAdherenceWeekBloc(String olderAdultId) => LevelBloc(
    olderAdultId: olderAdultId,
    summary: GetAdherenceSummary(_adherence),
    periodDays: adherenceWeekPeriodDays,
  );

  /// Creates the recommendations state of [olderAdultId]; the server insight is
  /// shown as received and never derived locally.
  RecommendationsBloc createAdherenceRecommendationsBloc(String olderAdultId) =>
      RecommendationsBloc(
        olderAdultId: olderAdultId,
        recommendations: GetRecommendations(_adherence),
      );

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

  Future<void> dispose() async {
    await _intakeSync.dispose();
    await _intakeRepository.dispose();
    await _intakeDatabase.close();
    _client.close();
  }
}
