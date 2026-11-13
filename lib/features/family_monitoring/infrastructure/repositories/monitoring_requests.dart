import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/failure_codes.dart';

/// Stable code for statuses that are specific to the monitoring endpoints.
/// [badRequest] names what a `400` means for the endpoint at hand.
String monitoringStatusCode(
  int status, {
  String badRequest = MonitoringFailureCodes.requestFailed,
}) => switch (status) {
  400 => badRequest,
  404 => MonitoringFailureCodes.notFound,
  409 => MonitoringFailureCodes.statusConflict,
  _ => MonitoringFailureCodes.requestFailed,
};

Future<AppResult<T>> _request<T>(
  SessionStore store,
  Set<SessionRole> roles,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response, SessionOwner owner) map,
  String badRequest,
) => authorizedRequest(
  store,
  roles,
  request,
  (response, owner) => response.status >= 200 && response.status < 300
      ? map(response, owner)
      : AppFailure(
          monitoringStatusCode(response.status, badRequest: badRequest),
        ),
);

/// Caregiver-only request: the caregiver id sent to the server is the captured session owner.
Future<AppResult<T>> caregiverMonitoringRequest<T>(
  SessionStore store,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response, SessionOwner owner) map, {
  String badRequest = MonitoringFailureCodes.requestFailed,
}) => _request(store, const {SessionRole.caregiver}, request, map, badRequest);

/// Request of the signed-in older adult, for the personal notes.
Future<AppResult<T>> adultMonitoringRequest<T>(
  SessionStore store,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response, SessionOwner owner) map,
) => _request(
  store,
  const {SessionRole.olderAdult},
  request,
  map,
  MonitoringFailureCodes.requestFailed,
);

/// Several reads that must belong to one caregiver: if the session changes owner between two
/// of them, the rest is discarded instead of mixing the data of two accounts.
final class CaregiverReads {
  CaregiverReads(this._store);
  final SessionStore _store;
  SessionOwner? _owner;

  Future<AppResult<T>> read<T>(
    Future<ApiResponse> Function(StoredSession session) request,
    AppResult<T> Function(ApiResponse response) map,
  ) => caregiverMonitoringRequest(_store, request, (response, owner) {
    final first = _owner ??= owner;
    return first == owner ? map(response) : const AppFailure('SESSION_CHANGED');
  });
}

/// Failures that end a multi-read flow, because retrying or showing partial data would hide
/// that access was lost or that the server answered something unreadable.
const accessLostCodes = {
  'AUTHENTICATION_REQUIRED',
  'ACCESS_DENIED',
  'SESSION_CHANGED',
  'INVALID_RESPONSE',
};

/// Whether [response] is a body-less success.
bool isEmptySuccess(ApiResponse response) => response.status == 204;
