import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/voice_confirmation.dart';
import '../../application/readmodels/voice_confirmation_result.dart';
import '../../application/readmodels/voice_recording.dart';
import '../mappers/intake_mapper.dart';
import '../remote/intake_api.dart';
import 'adult_session_request.dart';

/// Uploads a spoken confirmation with the adult session. A recorded outcome is
/// accepted only with evidence of the same intake and adult, already taken.
final class RemoteVoiceConfirmation implements VoiceConfirmation {
  const RemoteVoiceConfirmation({required this._api, required this._store});

  final IntakeApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<VoiceConfirmationResult>> confirmByVoice(
    String intakeId,
    VoiceRecording recording,
    String language,
  ) => adultSessionRequest(
    _store,
    (session) => _api.confirmByVoice(
      intakeId,
      session.accessToken,
      recording.bytes,
      recording.contentType,
      language,
    ),
    (response, owner) {
      final body = response.body;
      final code = body is Map<String, dynamic> ? body['title'] : null;
      if (response.status == 409 &&
          (code == 'INTAKE_NOT_CONFIRMABLE' ||
              code == 'VOICE_CONFIRMATION_DISABLED')) {
        return AppFailure(code as String);
      }
      if (response.status == 404) return const AppFailure('INTAKE_NOT_FOUND');
      if (response.status == 400) return const AppFailure('INVALID_AUDIO');
      if (response.status != 200 || body is! Map<String, dynamic>) {
        return const AppFailure('REQUEST_FAILED');
      }
      final recognition = switch (body['status']) {
        'CONFIRMED' => VoiceRecognition.confirmed,
        'ALREADY_CONFIRMED' => VoiceRecognition.alreadyConfirmed,
        'NOT_RECOGNIZED' => VoiceRecognition.notRecognized,
        'NOT_VALIDATED' => VoiceRecognition.notValidated,
        'PROVIDER_UNAVAILABLE' => VoiceRecognition.providerUnavailable,
        _ => throw const FormatException(),
      };
      final result = VoiceConfirmationResult(recognition);
      if (!result.recorded) return AppSuccess(result);
      final intake = IntakeMapper.intake(body['intake']);
      return intake.id == intakeId &&
              intake.olderAdultId == owner.id &&
              intake.taken
          ? AppSuccess(VoiceConfirmationResult(recognition, intake: intake))
          : const AppFailure('INVALID_RESPONSE');
    },
  );
}
