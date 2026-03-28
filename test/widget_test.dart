// test/widget_test.dart
//
// Smoke test de inicialização do app.
// Verifica que o app renderiza sem exceções — OnboardingScreen
// aparece quando não há usuário salvo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymcash/main.dart';
import 'package:gymcash/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Garante SharedPreferences limpo — sem usuário salvo
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renderiza OnboardingScreen quando não há usuário salvo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GymCashApp(initialScreen: OnboardingScreen()),
    );
    await tester.pump();

    // Verifica que o campo de nome está presente
    expect(find.byType(TextField), findsOneWidget);
    // Verifica o botão de continuar
    expect(find.text('Continuar'), findsOneWidget);
    // Verifica que não há erros de renderização
    expect(tester.takeException(), isNull);
  });

  testWidgets('OnboardingScreen valida nome vazio', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GymCashApp(initialScreen: OnboardingScreen()),
    );
    await tester.pump();

    // Tenta continuar sem digitar nada
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Digite pelo menos um nome'), findsOneWidget);
  });
}
