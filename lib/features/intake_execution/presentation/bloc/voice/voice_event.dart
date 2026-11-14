/// Intent handled by the voice confirmation state machine.
sealed class VoiceEvent {
  const VoiceEvent();
}

/// Loads or retries the dose that will be confirmed.
final class VoiceRequested extends VoiceEvent {
  const VoiceRequested();
}

/// Starts listening; [language] is the server locale, such as `es-419`.
final class VoiceStarted extends VoiceEvent {
  const VoiceStarted(this.language);
  final String language;
}

/// Stops listening and sends what was recorded.
final class VoiceStopped extends VoiceEvent {
  const VoiceStopped();
}

/// Stops listening and discards the audio, for example when leaving.
final class VoiceCancelled extends VoiceEvent {
  const VoiceCancelled();
}
