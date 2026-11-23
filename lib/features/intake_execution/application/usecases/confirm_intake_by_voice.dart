import '../../../../shared/common/result/app_result.dart';
import '../ports/voice_confirmation.dart';
import '../readmodels/voice_confirmation_result.dart';
import '../readmodels/voice_recording.dart';

/// Confirms a dose by voice (US-06, TS-11) within the server's audio limits.
final class ConfirmIntakeByVoice {
  const ConfirmIntakeByVoice(this._voice);
  final VoiceConfirmation _voice;

  /// Largest upload the server accepts.
  static const maxBytes = 5 * 1024 * 1024;

  /// Locales the server can recognize.
  static const languages = {'es-419', 'es-PE', 'es-ES', 'en-US'};

  Future<AppResult<VoiceConfirmationResult>> call(
    String intakeId,
    VoiceRecording recording,
    String language,
  ) async {
    if (intakeId.trim().isEmpty) return const AppFailure('INVALID_INTAKE');
    if (recording.bytes.isEmpty || recording.bytes.length > maxBytes) {
      return const AppFailure('INVALID_AUDIO');
    }
    if (!languages.contains(language)) return const AppFailure('INVALID_AUDIO');
    return _voice.confirmByVoice(intakeId, recording, language);
  }
}
