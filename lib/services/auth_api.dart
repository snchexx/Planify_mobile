import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:planify_mobile/config/api_config.dart';

class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<void> register({
    required String identificacion,
    required String nombres,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    final Uri endpoint = Uri.parse(_baseUrl).resolve('/auth/register');
    final http.Response response;

    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'identificacion': identificacion,
              'nombres': nombres,
              'apellidos': apellidos,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException(
        'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Verifica que esté activo y que el teléfono esté en la misma red.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _errorMessage(response, action: 'crear la cuenta'),
      );
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Uri endpoint = Uri.parse(_baseUrl).resolve('/auth/login');
    final http.Response response;

    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const AuthApiException(
        'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'No se pudo conectar con el servidor. Verifica que esté activo y que el teléfono esté en la misma red.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_errorMessage(response, action: 'iniciar sesión'));
    }

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> &&
          body['accessToken'] is String &&
          (body['accessToken'] as String).isNotEmpty &&
          body['user'] is Map<String, dynamic>) {
        final user = body['user'] as Map<String, dynamic>;
        final firstName = user['nombres'];
        if (firstName == null || firstName is String) {
          return AuthSession(
            accessToken: body['accessToken'] as String,
            firstName: firstName as String?,
          );
        }
      }
    } on FormatException {
      throw const AuthApiException(
        'El servidor devolvió una respuesta inválida.',
      );
    }

    throw const AuthApiException(
      'El servidor devolvió una respuesta inválida.',
    );
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  String _errorMessage(http.Response response, {required String action}) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.join('\n');
        }
      }
    } on FormatException {
      // Use the status-based message below when the response is not JSON.
    }

    return 'No se pudo $action (HTTP ${response.statusCode}).';
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, this.firstName});

  final String accessToken;
  final String? firstName;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
