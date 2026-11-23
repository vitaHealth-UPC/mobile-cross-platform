/// Explicit invitation and consent intents; logs do not expose invitation text.
sealed class ConsentEvent {
  const ConsentEvent();
  @override
  String toString() => 'ConsentEvent[REDACTED]';
}

/// Loads only the relationship bound to the persisted setup credential.
final class ConsentRequested extends ConsentEvent {
  const ConsentRequested();
}

/// Withdraws an already confirmed relationship after explicit UI confirmation.
final class ConsentWithdrawalRequested extends ConsentEvent {
  const ConsentWithdrawalRequested();
}

/// Exchanges a pasted invitation for consent-onboarding access.
final class InvitationSubmitted extends ConsentEvent {
  const InvitationSubmitted(this.text);
  final String text;
}

/// Records the adult's own affirmative or negative decision.
final class ConsentDecisionSubmitted extends ConsentEvent {
  const ConsentDecisionSubmitted(this.accepted);
  final bool accepted;
}
