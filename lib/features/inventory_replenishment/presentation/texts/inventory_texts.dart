import '../../../../l10n/generated/app_localizations.dart';

/// Failures that end the session; the host returns to sign-in.
bool isInventorySessionFailure(String? code) =>
    code == 'AUTHENTICATION_REQUIRED' || code == 'SESSION_CHANGED';

/// Localized text for a stable inventory failure code.
String inventoryErrorText(AppLocalizations text, String code) => switch (code) {
  'INVALID_QUANTITY' => text.invInvalidQuantityHint,
  'INVALID_THRESHOLD' => text.invInvalidThreshold,
  'INVALID_LOT' => text.invInvalidLot,
  'MEDICATION_NOT_FOUND' => text.invErrMedicationNotFound,
  'MEDICATION_INACTIVE' => text.invErrMedicationInactive,
  'CONCURRENT_UPDATE' => text.invErrConcurrent,
  'INVALID_RESPONSE' => text.invErrInvalidResponse,
  'NETWORK_UNAVAILABLE' => text.networkUnavailable,
  'ACCESS_DENIED' => text.accessDenied,
  'RATE_LIMITED' => text.rateLimited,
  _ => text.invErrGeneric,
};
