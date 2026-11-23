import '../../../../shared/common/result/app_result.dart';
import '../readmodels/voice_confirmation_result.dart';
import '../readmodels/voice_recording.dart';

/// Sends a spoken confirmation; recognition and the final status are decided
/// by the server.
abstract interface class VoiceConfirmation {
  /// Fails with `VOICE_CONFIRMATION_DISABLED` when the adult turned voice off,
  /// and with `INTAKE_NOT_CONFIRMABLE` when the dose is no longer pending.
  Future<AppResult<VoiceConfirmationResult>> confirmByVoice(
    String intakeId,
    VoiceRecording recording,
    String language,
  );
}

/// Reads the suggested phrase aloud for adults who prefer to hear it.
abstract interface class PhraseSpeaker {
  Future<void> speak(String phrase, String languageTag);
  Future<void> stop();
}
