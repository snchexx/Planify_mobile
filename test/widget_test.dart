import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planify_mobile/main.dart';
import 'package:planify_mobile/services/auth_api.dart';

void main() {
  testWidgets('shows the presentation image and login form', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PlanifyApp());

    expect(find.byKey(const Key('presentation-image')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('presentation-image'))).dy,
      lessThan(40),
    );
    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Recordar mi cuenta'), findsOneWidget);
    final loginTabSize = tester.getSize(find.byKey(const Key('login-tab')));
    final registerTabSize = tester.getSize(
      find.byKey(const Key('register-tab')),
    );
    expect(loginTabSize.height, greaterThanOrEqualTo(48));
    expect((loginTabSize.width - registerTabSize.width).abs(), lessThan(1));
    final modeButtonsCenter =
        (tester.getTopLeft(find.byKey(const Key('login-tab'))).dx +
            tester.getTopRight(find.byKey(const Key('register-tab'))).dx) /
        2;
    expect(modeButtonsCenter, closeTo(187.5, 1));
    final tabToFormGap =
        tester.getTopLeft(find.text('Correo electrónico')).dy -
        tester.getBottomLeft(find.byKey(const Key('login-tab'))).dy;
    expect(tabToFormGap, lessThan(65));
    final emailToPasswordGap =
        tester.getTopLeft(find.text('Contraseña')).dy -
        tester.getBottomLeft(find.byKey(const Key('email-field'))).dy;
    expect(emailToPasswordGap, lessThan(65));
    expect(
      tester.getBottomLeft(find.byKey(const Key('submit-button'))).dy,
      greaterThan(760),
    );
  });

  testWidgets('switches to account creation fields', (tester) async {
    await tester.pumpWidget(const PlanifyApp());
    await tester.tap(find.byKey(const Key('register-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Identificación'), findsOneWidget);
    expect(find.text('Nombres'), findsOneWidget);
    expect(find.text('Apellidos'), findsOneWidget);
    expect(find.byKey(const Key('register-password-field')), findsOneWidget);
    expect(find.text('Recordar mi cuenta'), findsNothing);
    expect(find.byKey(const Key('presentation-image')), findsOneWidget);

    final tabToFormGap =
        tester.getTopLeft(find.text('Identificación')).dy -
        tester.getBottomLeft(find.byKey(const Key('register-tab'))).dy;
    final identificationToNameGap =
        tester.getTopLeft(find.text('Nombres')).dy -
        tester.getBottomLeft(find.byKey(const Key('identification-field'))).dy;
    expect(tabToFormGap, greaterThanOrEqualTo(24));
    expect(identificationToNameGap, greaterThanOrEqualTo(18));
  });

  testWidgets('submits registration and returns to login after success', (
    tester,
  ) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'accessToken': 'test-token',
          'user': {'id': 1},
        }),
        201,
      );
    });
    addTearDown(client.close);
    final authApi = AuthApi(client: client, baseUrl: 'http://test.local:8000');

    await tester.pumpWidget(
      MaterialApp(home: AuthDesignScreen(authApi: authApi)),
    );
    await tester.tap(find.byKey(const Key('register-tab')));
    await tester.pumpAndSettle();

    Future<void> fillField(String id, String value) async {
      final field = find.byKey(Key('$id-field'));
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await fillField('identification', '1234567890');
    await fillField('first-name', 'Ana');
    await fillField('last-name', 'Pérez');
    await fillField('register-email', 'ana@example.com');
    await fillField('register-password', 'password-segura');
    await tester.ensureVisible(find.byKey(const Key('submit-button')));
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Cuenta creada. Ya puedes iniciar sesión.'),
      findsOneWidget,
    );
    expect(find.text('Recordar mi cuenta'), findsOneWidget);
    final loginEmailField = tester.widget<TextFormField>(
      find.byKey(const Key('email-field')),
    );
    expect(loginEmailField.controller?.text, 'ana@example.com');
  });

  testWidgets('successful login opens the home screen', (tester) async {
    final client = MockClient((request) async {
      expect(request.url, Uri.parse('http://test.local:8000/auth/login'));
      return http.Response(
        jsonEncode({
          'accessToken': 'test-token',
          'user': {'nombres': 'Ana María'},
        }),
        201,
      );
    });
    addTearDown(client.close);
    final authApi = AuthApi(client: client, baseUrl: 'http://test.local:8000');

    await tester.pumpWidget(
      MaterialApp(home: AuthDesignScreen(authApi: authApi)),
    );
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'password-segura',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-button')));
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(find.byKey(const Key('today-summary')), findsOneWidget);
    expect(find.byKey(const Key('upcoming-activities')), findsOneWidget);
    expect(find.byKey(const Key('assistant-card-image')), findsOneWidget);
    expect(find.text('¿Necesitas ayuda?'), findsOneWidget);
    expect(find.text('Chatear con IA'), findsOneWidget);
    final assistantCard = tester.widget<ClipRRect>(
      find.byKey(const Key('assistant-card')),
    );
    expect(assistantCard.borderRadius, BorderRadius.circular(16));
    expect(find.byKey(const Key('home-hero')), findsOneWidget);
    final introBottom = tester
        .getBottomLeft(
          find.text(
            'Aquí tienes un resumen de tus actividades y recordatorios de hoy.',
          ),
        )
        .dy;
    final summaryTop = tester
        .getTopLeft(find.byKey(const Key('today-summary')))
        .dy;
    expect(summaryTop - introBottom, greaterThanOrEqualTo(8));
    final heroClip = tester.widget<ClipRRect>(
      find.byKey(const Key('home-hero-clip')),
    );
    expect(heroClip.borderRadius, BorderRadius.circular(20));
    final summaryOverlap = tester.widget<Transform>(
      find.byKey(const Key('summary-overlap')),
    );
    expect(summaryOverlap.transform.getTranslation().y, -12);
    expect(find.text('Solicitar\nAgente IA'), findsOneWidget);
  });
}
