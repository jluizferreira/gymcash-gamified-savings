// test/services/streak_service_test.dart
//
// Testes unitários do StreakService.
// Executa com: flutter test test/services/streak_service_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymcash/models/contribution_model.dart';
import 'package:gymcash/services/local_storage_service.dart';
import 'package:gymcash/services/streak_service.dart';

// ── Helper: injeta contribuições com meses específicos direto no storage ──────
//
// saveContribution() sempre usa _currentMonth(), então não serve para testar
// meses históricos. Aqui serializamos a lista diretamente no SharedPreferences,
// respeitando o campo `month` de cada ContributionModel.
Future<LocalStorageService> _storageWith(
    List<ContributionModel> contribs) async {
  SharedPreferences.setMockInitialValues({
    'contributions': jsonEncode(
      contribs.map((c) => c.toJson()).toList(),
    ),
  });
  return LocalStorageService();
}

ContributionModel _contrib({
  required String userId,
  required String month,
  double amount = 100,
  double goal = 200,
}) =>
    ContributionModel(
      id: month,
      userId: userId,
      groupId: 'g1',
      amount: amount,
      goal: goal,
      month: month,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakService.calculateStreak', () {
    test('retorna 0 quando não há contribuições', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 0);
    });

    test('retorna 1 para um único mês com contribuição', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01'),
      ]);
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 1);
    });

    test('retorna 3 para três meses consecutivos', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01'),
        _contrib(userId: 'u1', month: '2025-02'),
        _contrib(userId: 'u1', month: '2025-03'),
      ]);
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 3);
    });

    test('interrompe streak ao detectar lacuna', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01'),
        // fevereiro ausente — lacuna
        _contrib(userId: 'u1', month: '2025-03'),
        _contrib(userId: 'u1', month: '2025-04'),
      ]);
      // A sequência mais recente é 03→04 = 2
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 2);
    });

    test('trata virada de ano corretamente (dezembro → janeiro)', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2024-11'),
        _contrib(userId: 'u1', month: '2024-12'),
        _contrib(userId: 'u1', month: '2025-01'),
      ]);
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 3);
    });

    test('ignora contribuições com amount == 0', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01', amount: 0),
        _contrib(userId: 'u1', month: '2025-02'),
      ]);
      // Janeiro tem amount=0, não conta para streak
      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 1);
    });

    test('não contamina streak de outro usuário', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01'),
        _contrib(userId: 'u1', month: '2025-02'),
        _contrib(userId: 'u2', month: '2025-01'),
        _contrib(userId: 'u2', month: '2025-02'),
        _contrib(userId: 'u2', month: '2025-03'),
      ]);
      final streakU1 = await StreakService(storage).calculateStreak('u1');
      final streakU2 = await StreakService(storage).calculateStreak('u2');
      expect(streakU1, 2);
      expect(streakU2, 3);
    });

    test('considera múltiplos grupos do mesmo usuário como mês único', () async {
      // Mesmo mês, grupos diferentes — deve contar como 1 mês no streak
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 50, goal: 100);
      await storage.saveContribution(
          userId: 'u1', groupId: 'g2', amount: 80, goal: 100);

      final streak = await StreakService(storage).calculateStreak('u1');
      expect(streak, 1); // não conta em dobro
    });
  });

  group('StreakService.lastActiveMonth', () {
    test('retorna null quando sem contribuições', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      final last = await StreakService(storage).lastActiveMonth('u1');
      expect(last, isNull);
    });

    test('retorna o mês mais recente com amount > 0', () async {
      final storage = await _storageWith([
        _contrib(userId: 'u1', month: '2025-01'),
        _contrib(userId: 'u1', month: '2025-03'),
        _contrib(userId: 'u1', month: '2025-02'),
      ]);
      final last = await StreakService(storage).lastActiveMonth('u1');
      expect(last, '2025-03');
    });
  });
}
