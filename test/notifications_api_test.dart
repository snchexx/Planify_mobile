import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planify_mobile/services/notifications_api.dart';

void main() {
  test('registers the FCM token for the authenticated device', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/notifications/devices');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body), {
        'token': 'a' * 160,
        'platform': 'android',
      });
      return http.Response('', 204);
    });
    addTearDown(client.close);

    final api = NotificationsApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );
    await api.registerDevice(
      accessToken: 'test-token',
      token: 'a' * 160,
      platform: 'android',
    );
    api.close();
  });

  test('parses the result of a test notification request', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/notifications/test');
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response('{"sent":1,"failed":0}', 200);
    });
    addTearDown(client.close);

    final api = NotificationsApi(
      client: client,
      baseUrl: 'http://test.local:8000',
    );
    final result = await api.sendTest(accessToken: 'test-token');

    expect(result.sent, 1);
    expect(result.failed, 0);
    api.close();
  });
}
