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

  test('patches an existing activity with its updated fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url, Uri.parse('http://test.local:8000/activities/12'));
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {
        'nombreActividad': 'Leer capítulos',
        'descripcion': 'Capítulos 3 y 4',
        'fechaActividad': '2026-11-26',
        'horaActividad': '16:00',
        'categoria': 'Estudio',
        'prioridad': 'Alta',
        'recordatorioHabilitado': true,
        'recordatorioMinutosAntes': 45,
      });

      return http.Response(
        jsonEncode({
          'idActividad': 12,
          'nombreActividad': 'Leer capítulos',
          'descripcion': 'Capítulos 3 y 4',
          'fechaActividad': '2026-11-26',
          'horaActividad': '16:00:00',
          'categoria': 'Estudio',
          'prioridad': 'Alta',
          'recordatorioHabilitado': true,
          'recordatorioMinutosAntes': 45,
          'idUsuario': 2,
        }),
        200,
      );
    });
    addTearDown(client.close);
    final api = ActivitiesApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );

    final activity = await api.updateActivity(
      id: 12,
      accessToken: 'test-token',
      title: 'Leer capítulos',
      description: 'Capítulos 3 y 4',
      date: '2026-11-26',
      time: '16:00',
      category: 'Estudio',
      priority: 'Alta',
      reminderEnabled: true,
      reminderMinutesBefore: 45,
    );

    expect(activity.title, 'Leer capítulos');
    expect(activity.reminderMinutesBefore, 45);
  });

  test('deletes an activity through its authenticated endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url, Uri.parse('http://test.local:8000/activities/12'));
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response('', 204);
    });
    addTearDown(client.close);
    final api = ActivitiesApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );

    await expectLater(
      api.deleteActivity(id: 12, accessToken: 'test-token'),
      completes,
    );
  });

  test('explains how to restore a failed USB connection', () async {
    final client = MockClient((_) async {
      throw http.ClientException('Connection refused');
    });
    addTearDown(client.close);
    final api = ActivitiesApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );

    await expectLater(
      api.fetchActivities(accessToken: 'test-token'),
      throwsA(
        isA<ActivitiesApiException>().having(
          (error) => error.message,
          'message',
          contains('adb reverse tcp:8000 tcp:8000'),
        ),
      ),
    );
  });
}
