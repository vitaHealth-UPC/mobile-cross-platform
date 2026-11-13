import '../../../../shared/common/result/app_result.dart';
import '../entities/caregiver_alert.dart';
import '../entities/notes.dart';
import '../value_objects/alert_status.dart';
import '../value_objects/contact_channel.dart';
import '../value_objects/note_values.dart';

/// Reads caregiver alerts and applies allowed status transitions. The caregiver is the
/// owner of the session in force, never an argument.
abstract interface class AlertsRepository {
  /// There is no alert list endpoint: these are the alerts that still need attention,
  /// taken from the recent status of the older adult.
  Future<AppResult<List<CaregiverAlert>>> openAlerts(String olderAdultId);

  Future<AppResult<CaregiverAlert>> alert(String olderAdultId, int alertId);

  Future<AppResult<CaregiverAlert>> updateStatus(
    String olderAdultId,
    int alertId,
    AlertStatus status,
  );
}

/// Provides the contact channel and identity available to authorized follow-up.
abstract interface class ContactRepository {
  /// Fails with `NOT_FOUND` when there is no follow-up or no channel.
  Future<AppResult<ContactChannel>> contactChannel(String olderAdultId);

  Future<AppResult<String>> olderAdultFullName(String olderAdultId);
}

/// Reads and records caregiver follow-up notes without binding them to one alert.
abstract interface class NotesRepository {
  Future<AppResult<List<FollowUpNote>>> notes(String olderAdultId);

  Future<AppResult<FollowUpNote>> register(String olderAdultId, String text);
}

/// Reads and creates notes owned by the authenticated older adult.
abstract interface class PersonalNotesRepository {
  Future<AppResult<List<PersonalNote>>> list();

  Future<AppResult<PersonalNote>> create(
    String title,
    String text,
    PersonalNoteCategory category,
  );
}
