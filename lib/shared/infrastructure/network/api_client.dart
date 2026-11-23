import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_response.dart';

/// Reusable HTTP boundary. Caller passes its captured credential explicitly.
final class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this._client,
    this.timeout = const Duration(seconds: 30),
  });

  final Uri baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// Sends an API-relative [path] with an explicitly captured [token], if needed.
  /// Redirects are disabled. Transport and malformed-success failures throw
  /// [ApiTransportException]; a non-JSON error body preserves its HTTP status.
  /// Query values belong in [queryParameters], never concatenated into [path].
  Future<ApiResponse> request(
    String method,
    String path, {
    Object? body,
    String? token,
    Map<String, String> queryParameters = const {},
  }) async {
    if (!path.startsWith('api/v1/') ||
        path.contains('..') ||
        path.contains('?') ||
        path.contains('#')) {
      throw ArgumentError('Invalid API path');
    }
    if (token != null && (token.isEmpty || RegExp(r'\s').hasMatch(token))) {
      throw ArgumentError('Invalid bearer credential');
    }
    try {
      final uri = baseUrl
          .resolve(path)
          .replace(
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
          );
      return await _exchange(method, uri, body, token).timeout(timeout);
    } on TimeoutException {
      throw const ApiTransportException('NETWORK_UNAVAILABLE');
    } on http.ClientException {
      throw const ApiTransportException('NETWORK_UNAVAILABLE');
    } on FormatException {
      throw const ApiTransportException('INVALID_RESPONSE');
    }
  }

  Future<ApiResponse> _exchange(
    String method,
    Uri uri,
    Object? body,
    String? token,
  ) async {
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body));
    }
    final response = await _client.send(request);
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > 1024 * 1024) {
        throw const FormatException('Response too large');
      }
      bytes.addAll(chunk);
    }
    Object? decoded;
    if (bytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(bytes));
      } on FormatException {
        // Authorization status remains authoritative even for an HTML proxy error.
        if (response.statusCode >= 200 && response.statusCode < 300) rethrow;
      }
    }
    return ApiResponse(response.statusCode, decoded);
  }

  /// Releases the HTTP client owned by the application composition.
  void close() => _client.close();
}
