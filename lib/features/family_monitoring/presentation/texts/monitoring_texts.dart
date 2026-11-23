import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/alert_status.dart';

/// Failures that mean the session is no longer valid for this screen: the host returns to
/// the sign-in flow.
bool isSessionFailure(String? code) =>
    code == 'AUTHENTICATION_REQUIRED' || code == 'SESSION_CHANGED';

/// Failures that mean the care relationship no longer grants access to this information.
bool isAccessFailure(String? code) =>
    code == 'ACCESS_DENIED' || isSessionFailure(code);

/// Localized message for a failure code of the follow-up reads. [detail] picks the text
/// of a missing alert instead of a missing follow-up.
String monitoringErrorText(
  AppLocalizations text,
  String? code, {
  bool detail = false,
}) => switch (code) {
  'NETWORK_UNAVAILABLE' => text.networkUnavailable,
  'ACCESS_DENIED' ||
  'AUTHENTICATION_REQUIRED' ||
  'SESSION_CHANGED' => text.fmErrorAccess,
  'NOT_FOUND' => detail ? text.fmErrorDetailNotFound : text.fmErrorListNotFound,
  'RATE_LIMITED' => text.rateLimited,
  _ => text.fmErrorUnknown,
};

String alertStatusLabel(AppLocalizations text, AlertStatus status) =>
    switch (status) {
      AlertStatus.open => text.fmStatusOpen,
      AlertStatus.attended => text.fmStatusAttended,
      AlertStatus.closed => text.fmStatusClosed,
    };

String alertStatusTitle(AppLocalizations text, AlertStatus status) =>
    switch (status) {
      AlertStatus.open => text.fmTitleOpen,
      AlertStatus.attended => text.fmTitleAttended,
      AlertStatus.closed => text.fmTitleClosed,
    };

/// Date and time of an instant in the device zone and the app language.
String monitoringDateTime(String locale, DateTime instant) =>
    DateFormat.yMMMd(locale).add_jm().format(instant.toLocal());

/// Hour of an instant in the device zone and the app language.
String monitoringTime(String locale, DateTime instant) =>
    DateFormat.jm(locale).format(instant.toLocal());
