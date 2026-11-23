import '../../../domain/entities/intake.dart';
import '../dose/dose_state.dart';

/// Observable phases of a voice confirmation (Figma 563:242 and 563:2707).
enum VoicePhase {
  loading,

  /// The dose could not be read.
  failure,
  ready,
  recording,
  processing,

  /// Heard nothing usable, or not a confirmation of this dose.
  notRecognized,

  /// The speech service or the microphone could not be used.
  unavailable,
  permissionDenied,

  /// The adult turned voice confirmation off in preferences.
  disabled,

  /// Recognition needs the server, so it cannot work offline.
  offline,
}

final class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.loading,
    this.intake,
    this.outcome,
    this.next,
    this.errorCode,
  });

  final VoicePhase phase;
  final Intake? intake;

  /// Set once the server recorded the dose; the route then shows the result.
  final ConfirmationOutcome? outcome;
  final Intake? next;
  final String? errorCode;

  /// Only a pending dose can be confirmed; a retry follows any failure.
  bool get canStart =>
      intake?.confirmable == true &&
      outcome == null &&
      const {
        VoicePhase.ready,
        VoicePhase.notRecognized,
        VoicePhase.unavailable,
        VoicePhase.permissionDenied,
        VoicePhase.offline,
      }.contains(phase);

  VoiceState copyWith({
    VoicePhase? phase,
    Intake? intake,
    ConfirmationOutcome? outcome,
    Intake? next,
    String? errorCode,
  }) => VoiceState(
    phase: phase ?? this.phase,
    intake: intake ?? this.intake,
    outcome: outcome ?? this.outcome,
    next: next ?? this.next,
    errorCode: errorCode,
  );
}
