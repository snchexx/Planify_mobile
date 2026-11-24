import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:planify_mobile/config/api_config.dart';

class PlanifyActivity {
  const PlanifyActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.category,
    required this.priority,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
  });

  factory PlanifyActivity.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('La actividad no tiene un formato válido.');
    }

    return PlanifyActivity(
      id: _requiredInt(json, 'idActividad'),
      title: _requiredString(json, 'nombreActividad'),
      description: _requiredString(json, 'descripcion'),
      date: _requiredString(json, 'fechaActividad'),
      time: _requiredString(json, 'horaActividad'),
      category: _optionalString(json, 'categoria'),
      priority: _optionalString(json, 'prioridad'),
      reminderEnabled: _optionalBool(json, 'recordatorioHabilitado'),
      reminderMinutesBefore: _optionalInt(json, 'recordatorioMinutosAntes'),
    );
  }

  final int id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String? category;
  final String? priority;
  final bool? reminderEnabled;
  final int? reminderMinutesBefore;

  DateTime get startsAt {
    final dateParts = date.split('T').first.split('-').map(int.parse).toList();
    final timeParts = time.split(':').map(int.parse).toList();
    return DateTime(
      dateParts[0],
      dateParts[1],
      dateParts[2],
      timeParts[0],
      timeParts[1],
    );
  }

  DateTime get notificationAt {
    if (reminderEnabled == true && reminderMinutesBefore != null) {
      return startsAt.subtract(Duration(minutes: reminderMinutesBefore!));
    }
    return startsAt;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('La respuesta no contiene un "$key" válido.');
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('La respuesta no contiene un "$key" válido.');
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }
    throw FormatException('La respuesta contiene un "$key" inválido.');
  }

  static bool? _optionalBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is bool) {
      return value as bool?;
    }
    throw FormatException('La respuesta contiene un "$key" inválido.');
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('La respuesta contiene un "$key" inválido.');
  }
}

class ActivitiesApi {
  ActivitiesApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<List<PlanifyActivity>> fetchActivities({
    required String accessToken,
  }) async {
    final response = await _send(
      () => _client.get(
        Uri.parse(_baseUrl).resolve('/activities'),
        headers: _headers(accessToken),
      ),
    );
    _ensureSuccess(response, action: 'cargar las actividades');

    try {
      final body = jsonDecode(response.body);
      if (body is! List) {
        throw const FormatException(
          'El servidor devolvió una lista de actividades inválida.',
        );
      }
      return body.map(PlanifyActivity.fromJson).toList();
    } on FormatException catch (error) {
      throw ActivitiesApiException(error.message);
    }
  }

  Future<PlanifyActivity> createActivity({
    required String accessToken,
    required String title,
    required String description,
    required String date,
    required String time,
    required String category,
    required String priority,
    required bool reminderEnabled,
    required int? reminderMinutesBefore,
  }) async {
    final payload = <String, Object>{
      'nombreActividad': title,
      'descripcion': description,
      'fechaActividad': date,
      'horaActividad': time,
      'categoria': category,
      'prioridad': priority,
      'recordatorioHabilitado': reminderEnabled,
    };
    if (reminderMinutesBefore != null) {
      payload['recordatorioMinutosAntes'] = reminderMinutesBefore;
    }

    final response = await _send(
      () => _client.post(
        Uri.parse(_baseUrl).resolve('/activities'),
        headers: _headers(accessToken),
        body: jsonEncode(payload),
      ),
    );
    _ensureSuccess(response, action: 'guardar la actividad');

    try {
      return PlanifyActivity.fromJson(jsonDecode(response.body));
    } on FormatException catch (error) {
      throw ActivitiesApiException(error.message);
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ActivitiesApiException(
        'El servidor tardó demasiado en responder. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ActivitiesApiException(
        'No se pudo conectar con el servidor. Verifica que esté activo.',
      );
    }
  }

  Map<String, String> _headers(String accessToken) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  void _ensureSuccess(http.Response response, {required String action}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ActivitiesApiException(_errorMessage(response, action: action));
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

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

class ActivitiesApiException implements Exception {
  const ActivitiesApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
