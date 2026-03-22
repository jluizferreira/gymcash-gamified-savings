// lib/main.dart

import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/local_storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = LocalStorageService();
  UserModel? savedUser;
  try {
    savedUser = await storage.getUser();
  } catch (e, st) {
    debugPrint('GymCash → falha ao ler usuário: $e\n$st');
    savedUser = null;
  }

  debugPrint('GymCash → usuário salvo: ${savedUser?.name ?? "nenhum"}');

  runApp(
    GymCashApp(
      initialScreen: savedUser != null
          ? HomeScreen(user: savedUser)
          : const OnboardingScreen(),
    ),
  );
}

class GymCashApp extends StatelessWidget {
  final Widget initialScreen;
  const GymCashApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymCash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF161616),
        ),
      ),
      home: initialScreen,
    );
  }
}
