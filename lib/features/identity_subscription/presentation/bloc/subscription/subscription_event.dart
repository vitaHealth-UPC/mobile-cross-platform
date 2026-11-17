/// Intent handled by the plan and subscription screen.
sealed class SubscriptionEvent {
  const SubscriptionEvent();
}

/// Loads or retries the current plan and the catalog.
final class SubscriptionRequested extends SubscriptionEvent {
  const SubscriptionRequested();
}

/// Marks a plan other than the current one as the one to change to.
final class SubscriptionPlanSelected extends SubscriptionEvent {
  const SubscriptionPlanSelected(this.code);
  final String code;
}

/// The caregiver confirmed the change in the dialog.
final class SubscriptionChangeConfirmed extends SubscriptionEvent {
  const SubscriptionChangeConfirmed();
}
