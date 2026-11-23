import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/readmodels/accessibility_change.dart';

/// REST requests for accessibility and notification preferences, with a captured bearer.
final class PreferencesApi {
  const PreferencesApi(this._client);
  final ApiClient _client;

  String _base(String userId) => 'api/v1/users/${Uri.encodeComponent(userId)}';

  Future<ApiResponse> get(String userId, String token) =>
      _client.request('GET', '${_base(userId)}/preferences', token: token);

  /// Sends one accessibility field to its own endpoint.
  Future<ApiResponse> update(
    String userId,
    AccessibilityChange change,
    String token,
  ) {
    final (segment, body) = switch (change) {
      TextSizeChange(:final value) => ('text-size', {'textSize': value.wire}),
      HighContrastChange(:final value) => ('contrast', {'enabled': value}),
      DarkThemeChange(:final value) => ('dark-theme', {'enabled': value}),
      ReducedMotionChange(:final value) => (
        'reduced-motion',
        {'enabled': value},
      ),
      VoiceConfirmationChange(:final value) => (
        'voice-confirmation',
        {'enabled': value},
      ),
      ReadingAssistanceChange(:final value) => (
        'reading-assistance',
        {'enabled': value},
      ),
    };
    return _client.request(
      'PUT',
      '${_base(userId)}/preferences/$segment',
      token: token,
      body: body,
    );
  }

  Future<ApiResponse> updateNotifications(
    String userId,
    Map<String, Object?> body,
    String token,
  ) => _client.request(
    'PUT',
    '${_base(userId)}/notification-preferences',
    token: token,
    body: body,
  );

  Future<ApiResponse> updatePolicy(
    String userId,
    Map<String, Object?> body,
    String token,
  ) => _client.request(
    'PUT',
    '${_base(userId)}/notification-preferences/policy',
    token: token,
    body: body,
  );
}
