import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planify_mobile/services/activities_api.dart';

void main() {
  test('fetches activities using the authenticated endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url, Uri.parse('http://test.local:8000/activities'));
      expect(request.headers['authorization'], 'Bearer test-token');

      return http.Response(
        jsonEncode([
          {
            'idActividad': 8,
            'nombreActividad': 'Estudiar',
            'descripcion': '',
            'fechaActividad': '2026-11-25',
            'horaActividad': '14:30:00',
            'categoria': 'Estudio',
            'prioridad': 'Alta',
            'recordatorioHabilitado': true,
            'recordatorioMinutosAntes': 25,
            'idUsuario': 2,
          },
        ]),
        200,
      );
    });
    addTearDown(client.close);
    final api = ActivitiesApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );

    final activities = await api.fetchActivities(accessToken: 'test-token');

    expect(activities, hasLength(1));
    expect(activities.single.title, 'Estudiar');
    expect(
      activities.single.notificationAt,
      activities.single.startsAt.subtract(const Duration(minutes: 25)),
    );
  });

  test('posts an activity with the selected metadata', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://test.local:8000/activities'));
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {
        'nombreActividad': 'Leer',
        'descripcion': '',
        'fechaActividad': '2026-11-25',
        'horaActividad': '14:30',
        'categoria': 'Lectura',
        'prioridad': 'Media',
        'recordatorioHabilitado': true,
        'recordatorioMinutosAntes': 35,
      });

      return http.Response(
        jsonEncode({
          'idActividad': 12,
          'nombreActividad': 'Leer',
          'descripcion': '',
          'fechaActividad': '2026-11-25',
          'horaActividad': '14:30:00',
          'categoria': 'Lectura',
          'prioridad': 'Media',
          'recordatorioHabilitado': true,
          'recordatorioMinutosAntes': 35,
          'idUsuario': 2,
        }),
        201,
      );
    });
    addTearDown(client.close);
    final api = ActivitiesApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );

    final activity = await api.createActivity(
      accessToken: 'test-token',
      title: 'Leer',
      description: '',
      date: '2026-11-25',
      time: '14:30',
      category: 'Lectura',
      priority: 'Media',
      reminderEnabled: true,
      reminderMinutesBefore: 35,
    );

    expect(activity.id, 12);
    expect(activity.reminderMinutesBefore, 35);
  });
}
