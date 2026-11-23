import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/contact_channel.dart';
import '../mappers/monitoring_mapper.dart';
import '../remote/family_monitoring_api.dart';
import 'monitoring_requests.dart';

/// Contact channel (`GET /older-adults/{id}/contact-channel`) and name
/// (`GET /older-adults/{id}`) of the older adult.
final class RemoteContactRepository implements ContactRepository {
  const RemoteContactRepository({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<ContactChannel>> contactChannel(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.contactChannel(
          olderAdultId,
          session.owner.id,
          session.accessToken,
        ),
        (response, _) => AppSuccess(MonitoringMapper.contact(response.body)),
      );

  @override
  Future<AppResult<String>> olderAdultFullName(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.profile(olderAdultId, session.accessToken),
        (response, _) {
          final person = MonitoringMapper.person(response.body);
          return person.id == olderAdultId
              ? AppSuccess(person.fullName)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
}
