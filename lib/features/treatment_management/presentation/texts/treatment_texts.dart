import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/treatment_status.dart';

/// Localized messages for the failure codes of the treatment flows.
String? treatmentErrorText(AppLocalizations text, String? code) =>
    switch (code) {
      null => null,
      'INVALID_DOSAGE' => text.tmErrInvalidDosage,
      'INVALID_FREQUENCY' => text.tmErrInvalidFrequency,
      'EMPTY_SCHEDULE' => text.tmErrEmptySchedule,
      'INVALID_SCHEDULE_TIME' => text.tmErrInvalidTime,
      'INSTRUCTIONS_TOO_LONG' => text.tmErrInstructionsLong,
      'INVALID_REMINDER_DELAY' => text.tmErrReminderDelay,
      'REQUIRED_FIELDS_MISSING' => text.tmErrRequired,
      'INVALID_TREATMENT_CONFIGURATION' ||
      'REQUEST_VALIDATION_FAILED' => text.tmErrIncomplete,
      'RESOURCE_NOT_FOUND' => text.tmErrNotFound,
      'CONFLICT' => text.tmErrConflict,
      'INVALID_RESPONSE' => text.tmErrInvalidResponse,
      'NETWORK_UNAVAILABLE' => text.networkUnavailable,
      'ACCESS_DENIED' => text.accessDenied,
      'RATE_LIMITED' => text.rateLimited,
      _ => text.tmErrGeneric,
    };

String treatmentStatusText(AppLocalizations text, TreatmentStatus status) =>
    switch (status) {
      TreatmentStatus.draft => text.tmStatusDraft,
      TreatmentStatus.active => text.tmStatusActive,
      TreatmentStatus.paused => text.tmStatusPaused,
    };

/// Failures that mean the session is no longer valid for this screen.
bool isSessionFailure(String? code) =>
    code == 'AUTHENTICATION_REQUIRED' || code == 'SESSION_CHANGED';
