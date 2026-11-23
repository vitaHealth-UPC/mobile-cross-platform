import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';

/// Caregiver-only request: the caregiver id sent to the server is the captured session owner.
Future<AppResult<T>> caregiverTreatmentRequest<T>(
  SessionStore store,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response) map,
) => authorizedRequest(
  store,
  const {SessionRole.caregiver},
  request,
  (response, _) => response.status >= 200 && response.status < 300
      ? map(response)
      : AppFailure(treatmentStatusCode(response.status)),
);

/// Stable code for statuses that are specific to treatment endpoints.
String treatmentStatusCode(int status) => switch (status) {
  400 => 'REQUEST_VALIDATION_FAILED',
  404 => 'RESOURCE_NOT_FOUND',
  409 => 'CONFLICT',
  _ => 'REQUEST_FAILED',
};
