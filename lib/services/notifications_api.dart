import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:planify_mobile/config/api_config.dart';

class NotificationsApi {
  NotificationsApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<void> registerDevice({
    required String accessToken,
    required String token,
    required String platform,
  }) async {
    final response = await _send(
      () => _client.post(
        Uri.parse(_baseUrl).resolve('/notifications/devices'),
        headers: _headers(accessToken),
        body: jsonEncode({'token': token, 'platform': platform}),
      ),
    );
    _ensureSuccess(response, action: 'registrar este dispositivo');
  }

  Future<NotificationTestResult> sendTest({required String accessToken}) async {
    final response = await _send(
      () => _client.post(
        Uri.parse(_baseUrl).resolve('/notifications/test'),
        headers: _headers(accessToken),
      ),
    );
    _ensureSuccess(response, action: 'enviar la notificación de prueba');

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> &&
          body['sent'] is int &&
          body['failed'] is int) {
        return NotificationTestResult(
          sent: body['sent'] as int,
          failed: body['failed'] as int,
        );
      }
    } on FormatException {
      throw const NotificationsApiException(
        'El servidor devolvió una respuesta inválida.',
      );
    }

    throw const NotificationsApiException(
      'El servidor devolvió una respuesta inválida.',
    );
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Map<String, String> _headers(String accessToken) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const NotificationsApiException(
        'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw const NotificationsApiException(
        'No se pudo conectar con Planify.',
      );
    }
  }

  void _ensureSuccess(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          throw NotificationsApiException(message);
        }
        if (message is List && message.isNotEmpty) {
          throw NotificationsApiException(message.join('\n'));
        }
      }
    } on FormatException {
      // Use the status-based message below when the response is not JSON.
    }

    throw NotificationsApiException(
      'No se pudo $action (HTTP ${response.statusCode}).',
    );
  }
}

class NotificationTestResult {
  const NotificationTestResult({required this.sent, required this.failed});

  final int sent;
  final int failed;
}

class NotificationsApiException implements Exception {
  const NotificationsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
