import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planify_mobile/services/auth_api.dart';

void main() {
  test('posts registration fields to the backend endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://127.0.0.1:8000/auth/register'));
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
      email: ' Ana@Example.COM ',
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

  test('logs in and returns the authenticated session', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('http://127.0.0.1:8000/auth/login'));
      expect(jsonDecode(request.body), {
        'email': 'ana@example.com',
        'password': 'password-segura',
      });

      return http.Response(
        jsonEncode({
          'accessToken': 'test-token',
          'user': {'nombres': 'Ana María'},
        }),
        201,
      );
    });
    addTearDown(client.close);
    final api = AuthApi(client: client);

    final session = await api.login(
      email: ' Ana@Example.COM ',
      password: 'password-segura',
    );

    expect(session.accessToken, 'test-token');
    expect(session.firstName, 'Ana María');
  });

  test('requests a password recovery code using a normalized email', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('http://127.0.0.1:8000/auth/password/forgot'),
      );
      expect(jsonDecode(request.body), {'email': 'ana@example.com'});
      return http.Response(
        '{"message":"Si la cuenta existe, recibirás un código de recuperación."}',
        200,
      );
    });
    addTearDown(client.close);
    final api = AuthApi(client: client);

    await api.requestPasswordReset(email: ' Ana@Example.COM ');
  });

  test('submits the recovery code and new password', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('http://127.0.0.1:8000/auth/password/reset'),
      );
      expect(jsonDecode(request.body), {
        'email': 'ana@example.com',
        'code': '123456',
        'password': 'new-password',
      });
      return http.Response('{"message":"Contraseña restablecida."}', 200);
    });
    addTearDown(client.close);
    final api = AuthApi(client: client);

    await api.resetPassword(
      email: ' Ana@Example.COM ',
      code: '123456',
      password: 'new-password',
    );
  });

  test('explains how to restore a failed server connection', () async {
    final client = MockClient((_) async {
      throw http.ClientException('Connection refused');
    });
    addTearDown(client.close);
    final api = AuthApi(client: client);

    await expectLater(
      api.login(email: 'ana@example.com', password: 'password-segura'),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          contains('adb reverse tcp:8000 tcp:8000'),
        ),
      ),
    );
  });
}
