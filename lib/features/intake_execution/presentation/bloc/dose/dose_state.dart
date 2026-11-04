import '../../../domain/entities/intake.dart';

/// Observable phases of the dose detail.
enum DoseStatus { loading, ready, failure }

/// Result of a confirmation attempt, always as the server decided it.
enum ConfirmationOutcome {
  /// Confirmed before the scheduled instant (Figma 563:291).
  confirmed,

  /// Confirmed after the scheduled instant (Figma 563:3770).
  late,

  /// The dose was already taken; no second record was created (563:2760).
  alreadyConfirmed,

  /// The dose was omitted and the omission stays in the history (563:3844).
  omissionPreserved,
}

/// Dose evidence plus the in-flight confirmation and its outcome.
final class DoseState {
  const DoseState({
    this.status = DoseStatus.loading,
    this.intake,
    this.confirming = false,
    this.outcome,
    this.next,
    this.errorCode,
  });

  final DoseStatus status;
  final Intake? intake;
  final bool confirming;

  /// Set once a confirmation attempt ends; the route then shows the result.
  final ConfirmationOutcome? outcome;

  /// Next pending dose after a confirmation, other than this one, if any.
  final Intake? next;

  /// Load failure, or a confirmation that could not be completed.
  final String? errorCode;

  bool get canConfirm =>
      status == DoseStatus.ready &&
      !confirming &&
      outcome == null &&
      intake?.confirmable == true;
}
