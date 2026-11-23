import '../../../../shared/common/result/app_result.dart';
import '../readmodels/voice_recording.dart';

/// Owns one microphone capture at a time and keeps the audio in memory only.
abstract interface class VoiceRecorder {
  /// Asks for the microphone when needed. Fails with
  /// `MICROPHONE_PERMISSION_DENIED` or `MICROPHONE_UNAVAILABLE`.
  Future<AppResult<void>> start();

  /// Stops and returns the recording; fails with `INVALID_AUDIO` when empty.
  Future<AppResult<VoiceRecording>> finish();

  /// Stops and discards any audio captured so far.
  Future<void> cancel();
}
