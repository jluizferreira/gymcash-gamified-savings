// lib/screens/onboarding_screen.dart
//
// Atualizado: passa o 'id' ao criar UserModel.

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  final _storage    = LocalStorageService();
  bool _saving      = false;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = UserModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _controller.text.trim(),
      );
      await _storage.saveUser(user);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } on LocalStorageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2D1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar seu nome. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: Colors.black, size: 34),
                  ),
                  const SizedBox(height: 32),
                  const Text('Olá!\nComo podemos\nte chamar?',
                      style: TextStyle(color: Colors.white, fontSize: 34,
                          fontWeight: FontWeight.w800, height: 1.2,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Seu nome aparecerá no painel do GymCash.',
                      style: TextStyle(color: Color(0xFF666666), fontSize: 15)),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Seu nome',
                      hintStyle: const TextStyle(color: Color(0xFF444444)),
                      filled: true,
                      fillColor: const Color(0xFF161616),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF222222))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF222222))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF00E676), width: 2)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 2)),
                      focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 2)),
                    ),
                    onFieldSubmitted: (_) => _continue(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite pelo menos um nome';
                      }
                      if (value.trim().length < 2) return 'Nome muito curto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            const Color(0xFF00E676).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5))
                          : const Text('Continuar',
                              style: TextStyle(fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
