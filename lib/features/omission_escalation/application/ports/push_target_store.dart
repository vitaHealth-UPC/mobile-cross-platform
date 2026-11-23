/// Who this device follows, so a tapped notification can open the right screen.
/// It stores identifiers and the display name the screens already show, no health data.
abstract interface class PushTargetStore {
  Future<void> rememberCaregiver(String olderAdultId, String caregiverId);
  Future<void> rememberOlderAdult(String olderAdultId, String olderAdultName);
  Future<String?> caregiverFor(String olderAdultId);
  Future<String?> olderAdultName(String olderAdultId);
}
