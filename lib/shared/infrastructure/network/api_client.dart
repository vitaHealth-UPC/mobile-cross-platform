import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  }) => _send(path, token, queryParameters, (uri) {
    final request = http.Request(method, uri);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = utf8.encode(jsonEncode(body));
    }
    return request;
  });

  /// POSTs one file as multipart form data, with the same guarantees as
  /// [request].
  Future<ApiResponse> upload(
    String path, {
    required String token,
    required String field,
    required List<int> bytes,
    required String filename,
    required String contentType,
    Map<String, String> queryParameters = const {},
  }) => _send(
    path,
    token,
    queryParameters,
    (uri) => http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      ),
  );

  Future<ApiResponse> _send(
    String path,
    String? token,
    Map<String, String> queryParameters,
    http.BaseRequest Function(Uri uri) build,
  ) async {
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
      final request = build(uri)..followRedirects = false;
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      return await _exchange(request).timeout(timeout);
    } on TimeoutException {
      throw const ApiTransportException('NETWORK_UNAVAILABLE');
    } on http.ClientException {
      throw const ApiTransportException('NETWORK_UNAVAILABLE');
    } on FormatException {
      throw const ApiTransportException('INVALID_RESPONSE');
    }
  }

  Future<ApiResponse> _exchange(http.BaseRequest request) async {
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
