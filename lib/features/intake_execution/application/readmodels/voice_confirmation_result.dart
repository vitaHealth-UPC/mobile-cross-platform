import '../../domain/entities/intake.dart';

/// How the server judged a spoken confirmation.
enum VoiceRecognition {
  /// Recognized and recorded now.
  confirmed,

  /// Recognized, but the dose had already been taken; nothing new was recorded.
  alreadyConfirmed,

  /// Nothing understandable was heard.
  notRecognized,

  /// Something was heard, but it did not confirm taking this medication.
  notValidated,

  /// The speech service could not answer.
  providerUnavailable,
}

/// Server answer to a spoken confirmation. The transcript is not kept: it is
/// health data the adult never chose to store.
final class VoiceConfirmationResult {
  const VoiceConfirmationResult(this.recognition, {this.intake});

  final VoiceRecognition recognition;

  /// Evidence of the dose; present only when it is taken.
  final Intake? intake;

  bool get recorded =>
      recognition == VoiceRecognition.confirmed ||
      recognition == VoiceRecognition.alreadyConfirmed;
}
