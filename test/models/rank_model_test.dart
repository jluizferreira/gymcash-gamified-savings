// test/models/rank_model_test.dart
//
// Testes unitários para RankModel e ContributionModel.
// Executa com: flutter test test/models/rank_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gymcash/models/rank_model.dart';
import 'package:gymcash/models/contribution_model.dart';

void main() {
  group('RankModel.fromTotal', () {
    test('retorna Bronze para total 0', () {
      expect(RankModel.fromTotal(0).id, 'bronze');
    });

    test('retorna Bronze para total abaixo de 100', () {
      expect(RankModel.fromTotal(99.99).id, 'bronze');
    });

    test('retorna Prata exatamente em 100', () {
      expect(RankModel.fromTotal(100).id, 'silver');
    });

    test('retorna Ouro exatamente em 300', () {
      expect(RankModel.fromTotal(300).id, 'gold');
    });

    test('retorna Platina exatamente em 700', () {
      expect(RankModel.fromTotal(700).id, 'platinum');
    });

    test('retorna Diamante exatamente em 1500', () {
      expect(RankModel.fromTotal(1500).id, 'diamond');
    });

    test('retorna Diamante para valores acima de 1500', () {
      expect(RankModel.fromTotal(99999).id, 'diamond');
    });
  });

  group('RankModel.nextRank', () {
    test('Bronze tem próxima patente Prata', () {
      final bronze = RankModel.fromTotal(0);
      expect(RankModel.nextRank(bronze)?.id, 'silver');
    });

    test('Diamante não tem próxima patente', () {
      final diamond = RankModel.fromTotal(1500);
      expect(RankModel.nextRank(diamond), isNull);
    });
  });

  group('RankModel.progressToNext', () {
    test('retorna 0.0 no início do Bronze', () {
      expect(RankModel.progressToNext(0), 0.0);
    });

    test('retorna 0.5 na metade do caminho Bronze → Prata', () {
      // Bronze: 0, Prata: 100 → metade = 50
      expect(RankModel.progressToNext(50), 0.5);
    });

    test('retorna 1.0 quando no Diamante (topo)', () {
      expect(RankModel.progressToNext(1500), 1.0);
    });

    test('retorna valor entre 0 e 1 para qualquer patente intermediária', () {
      final progress = RankModel.progressToNext(200);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });
  });

  group('ContributionModel.progress', () {
    ContributionModel make({required double amount, required double goal}) =>
        ContributionModel(
          id: '1',
          userId: 'u1',
          groupId: 'g1',
          amount: amount,
          goal: goal,
          month: '2025-01',
        );

    test('retorna 0 quando goal é zero', () {
      expect(make(amount: 100, goal: 0).progress, 0.0);
    });

    test('retorna 0.5 quando amount é metade da goal', () {
      expect(make(amount: 50, goal: 100).progress, 0.5);
    });

    test('retorna 1.0 quando amount igual a goal', () {
      expect(make(amount: 200, goal: 200).progress, 1.0);
    });

    test('retorna maior que 1.0 quando amount supera goal', () {
      expect(make(amount: 300, goal: 200).progress, greaterThan(1.0));
    });

    test('progressLabel formata corretamente', () {
      expect(make(amount: 150, goal: 200).progressLabel, '75%');
      expect(make(amount: 200, goal: 200).progressLabel, '100%');
      expect(make(amount: 0, goal: 0).progressLabel, '0%');
    });
  });

  group('ContributionModel serialização', () {
    test('toJson e fromJson são inversos', () {
      final original = ContributionModel(
        id: 'abc123',
        userId: 'u1',
        groupId: 'g1',
        amount: 350.50,
        goal: 500.00,
        month: '2025-03',
        isGoalNotified: true,
      );

      final json = original.toJson();
      final restored = ContributionModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.amount, original.amount);
      expect(restored.goal, original.goal);
      expect(restored.month, original.month);
      expect(restored.isGoalNotified, original.isGoalNotified);
    });
  });
}
