import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planify_mobile/services/auth_api.dart';

void main() {
  test('posts registration fields to the backend endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://192.168.137.1:8000/auth/register'));
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'identificacion': '1234567890',
        'nombres': 'Ana María',
        'apellidos': 'Pérez Gómez',
        'email': 'ana@example.com',
        'password': 'password-segura',
      });

      return http.Response('{"accessToken":"token"}', 201);
    });
    addTearDown(client.close);
    final api = AuthApi(client: client);

    await api.register(
      identificacion: '1234567890',
      nombres: 'Ana María',
      apellidos: 'Pérez Gómez',
      email: 'ana@example.com',
      password: 'password-segura',
    );
  });

  test(
    'shows a useful message when the backend rejects registration',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"statusCode":409,"message":"El correo ya está registrado"}',
          409,
        ),
      );
      addTearDown(client.close);
      final api = AuthApi(client: client);

      await expectLater(
        api.register(
          identificacion: '1234567890',
          nombres: 'Ana',
          apellidos: 'Pérez',
          email: 'ana@example.com',
          password: 'password-segura',
        ),
        throwsA(
          isA<AuthApiException>().having(
            (error) => error.message,
            'message',
            'El correo ya está registrado',
          ),
        ),
      );
    },
  );
}
