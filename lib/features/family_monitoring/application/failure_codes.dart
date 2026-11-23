/// Stable failure codes of the follow-up flows; presentation maps them to localized text.
/// Transport and session codes (`NETWORK_UNAVAILABLE`, `ACCESS_DENIED`,
/// `AUTHENTICATION_REQUIRED`, `SESSION_CHANGED`, `RATE_LIMITED`, `INVALID_RESPONSE`) are the
/// shared ones; these are the ones that belong to this context.
abstract final class MonitoringFailureCodes {
  static const notFound = 'NOT_FOUND';
  static const requestFailed = 'REQUEST_FAILED';
  static const invalidReference = 'INVALID_REFERENCE';
  static const statusConflict = 'ALERT_STATUS_CONFLICT';
  static const statusNotAccepted = 'ALERT_STATUS_NOT_ACCEPTED';
  static const noteBlank = 'NOTE_BLANK';
  static const noteTooLong = 'NOTE_TOO_LONG';
  static const noteRejected = 'INVALID_NOTE';
}
