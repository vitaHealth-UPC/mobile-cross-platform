import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/contact_channel.dart';
import '../failure_codes.dart';
import '../ports/monitoring_ports.dart';
import '../readmodels/monitoring_readmodels.dart';

/// The caller-selected calendar day and the account-scoped summary projection.
final class GetFamilySummary {
  const GetFamilySummary(this._repository);
  final FamilyMonitoringRepository _repository;

  Future<AppResult<FamilySummary>> call(
    String olderAdultId,
    String name,
    DateTime day,
  ) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return _repository.summary(olderAdultId.trim(), name, day);
  }
}

/// Recent intake history of one adult, read with the caregiver's own authorization.
final class GetFamilyHistory {
  const GetFamilyHistory(this._repository);
  final FamilyMonitoringRepository _repository;

  Future<AppResult<List<IntakeHistoryEntry>>> call(String olderAdultId) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return _repository.history(olderAdultId.trim());
  }
}

/// A missing channel (404) is a normal answer: the screen shows "Contacto no disponible".
/// The name only personalizes the button, so a temporary lookup failure does not block
/// contact. Authorization and invalid-response failures are propagated instead of exposing
/// a previously fetched channel.
final class GetContactOption implements ContactOptionReader {
  const GetContactOption(this._repository);
  final ContactRepository _repository;

  static const _nameFailuresThatDoNotBlock = {
    'NETWORK_UNAVAILABLE',
    MonitoringFailureCodes.notFound,
    MonitoringFailureCodes.requestFailed,
  };

  @override
  Future<AppResult<ContactOption>> call(String olderAdultId) async {
    final adult = olderAdultId.trim();
    if (adult.isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    ContactChannel? channel;
    switch (await _repository.contactChannel(adult)) {
      case AppSuccess(:final value):
        channel = value;
      case AppFailure(:final code):
        if (code != MonitoringFailureCodes.notFound) return AppFailure(code);
    }
    String? firstName;
    switch (await _repository.olderAdultFullName(adult)) {
      case AppSuccess(:final value):
        firstName = _first(value);
      case AppFailure(:final code):
        if (!_nameFailuresThatDoNotBlock.contains(code)) {
          return AppFailure(code);
        }
    }
    return AppSuccess(ContactOption(channel: channel, firstName: firstName));
  }

  static String? _first(String fullName) {
    final first = fullName.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? null : first;
  }
}
