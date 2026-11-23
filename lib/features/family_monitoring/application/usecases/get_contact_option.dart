import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/contact_repository.dart';
import '../../domain/value_objects/contact_channel.dart';
import '../failure_codes.dart';
import '../ports/contact_option_reader.dart';
import '../readmodels/contact_option.dart';

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
