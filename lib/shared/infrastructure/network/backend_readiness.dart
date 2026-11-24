import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_response.dart';

/// Coordinates a cold start without replaying a business request.
final class BackendReadiness {
  BackendReadiness({
    required this.baseUrl,
    required this.client,
    this.onPreparing,
    this.budget = const Duration(seconds: 120),
    this.probeTimeout = const Duration(seconds: 45),
    this.retryDelay = const Duration(seconds: 5),
    this.maxAttempts = 24,
    this.freshFor = const Duration(minutes: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Uri baseUrl;
  final http.Client client;
  final void Function(bool)? onPreparing;
  final Duration budget, probeTimeout, retryDelay, freshFor;
  final int maxAttempts;
  final DateTime Function() _clock;
  DateTime? _lastContact;
  Future<void>? _pending;

  void noteContact() => _lastContact = _clock();
  void invalidate() => _lastContact = null;

  Future<void> ensureReady() {
    final pending = _pending;
    if (pending != null) return pending;
    final last = _lastContact;
    if (last != null &&
        !_clock().isBefore(last) &&
        _clock().difference(last) < freshFor) {
      return Future.value();
    }
    return _pending = _prepare().whenComplete(() => _pending = null);
  }

  Future<void> _prepare() async {
    onPreparing?.call(true);
    final watch = Stopwatch()..start();
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final left = budget - watch.elapsed;
        if (left <= Duration.zero) break;
        try {
          final request =
              http.Request('GET', baseUrl.resolve('/actuator/health'))
                ..followRedirects = false
                ..headers['Accept'] = 'application/json';
          final ready = await _probe(request)
              .timeout(left < probeTimeout ? left : probeTimeout);
          if (ready) {
            noteContact();
            return;
          }
        } on TimeoutException {
          // Only the read-only probe can be attempted again.
        } on http.ClientException {
          // A transient transport failure can recover on the next probe.
        } on FormatException {
          // A provider's HTML startup page is not an UP receipt.
        }
        final remaining = budget - watch.elapsed;
        if (attempt + 1 < maxAttempts && remaining > retryDelay) {
          await Future<void>.delayed(retryDelay);
        } else {
          break;
        }
      }
      throw const ApiTransportException('NETWORK_UNAVAILABLE');
    } finally {
      onPreparing?.call(false);
    }
  }

  Future<bool> _probe(http.Request request) async {
    final response = await client.send(request);
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > 16 * 1024) return false;
      bytes.addAll(chunk);
    }
    if (response.statusCode != 200) return false;
    final body = jsonDecode(utf8.decode(bytes));
    return body is Map && body['status'] == 'UP';
  }
}
