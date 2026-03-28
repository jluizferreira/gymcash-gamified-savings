// test/services/local_storage_service_test.dart
//
// Testes do gateway de persistência — foca em saveContribution e regras de negócio.
// Executa com: flutter test test/services/local_storage_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymcash/models/user_model.dart';
import 'package:gymcash/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('saveContribution — unicidade', () {
    test('cria nova contribuição quando não existe registro', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);

      final all = await storage.getContributions();
      expect(all.length, 1);
      expect(all.first.amount, 100);
    });

    test('atualiza registro existente sem criar duplicata', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 150, goal: 200);

      final all = await storage.getContributions();
      expect(all.length, 1);
      expect(all.first.amount, 150);
    });

    test('cria registros separados para grupos diferentes', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);
      await storage.saveContribution(
          userId: 'u1', groupId: 'g2', amount: 200, goal: 300);

      final all = await storage.getContributions();
      expect(all.length, 2);
    });

    test('cria registros separados para usuários diferentes', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);
      await storage.saveContribution(
          userId: 'u2', groupId: 'g1', amount: 50, goal: 200);

      final all = await storage.getContributions();
      expect(all.length, 2);
    });
  });

  group('saveContribution — goalJustReached', () {
    test('goalJustReached é true quando amount >= goal na primeira vez', () async {
      final storage = LocalStorageService();
      final result = await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 200, goal: 200);

      expect(result.goalJustReached, isTrue);
    });

    test('goalJustReached é false quando amount < goal', () async {
      final storage = LocalStorageService();
      final result = await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);

      expect(result.goalJustReached, isFalse);
    });

    test('goalJustReached é false na segunda vez que atinge a meta', () async {
      final storage = LocalStorageService();
      // Primeira vez — dispara
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 200, goal: 200);
      // Segunda vez — não deve disparar novamente
      final result = await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 250, goal: 200);

      expect(result.goalJustReached, isFalse);
    });

    test('goalJustReached é false quando goal é zero', () async {
      final storage = LocalStorageService();
      final result = await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 0);

      expect(result.goalJustReached, isFalse);
    });
  });

  group('getTotalAccumulated', () {
    test('retorna 0 para usuário sem contribuições', () async {
      final storage = LocalStorageService();
      final total = await storage.getTotalAccumulated('u1');
      expect(total, 0.0);
    });

    test('soma amount de múltiplos grupos e meses', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);
      await storage.saveContribution(
          userId: 'u1', groupId: 'g2', amount: 250, goal: 300);

      final total = await storage.getTotalAccumulated('u1');
      expect(total, 350.0);
    });

    test('não soma contribuições de outros usuários', () async {
      final storage = LocalStorageService();
      await storage.saveContribution(
          userId: 'u1', groupId: 'g1', amount: 100, goal: 200);
      await storage.saveContribution(
          userId: 'u2', groupId: 'g1', amount: 500, goal: 500);

      final total = await storage.getTotalAccumulated('u1');
      expect(total, 100.0);
    });
  });

  group('grupos — CRUD', () {
    test('cria grupo com criador como primeiro membro', () async {
      final storage = LocalStorageService();
      final creator = const UserModel(id: 'u1', name: 'Jefferson');
      final group = await storage.createGroup('Turma A', creator: creator);

      expect(group.name, 'Turma A');
      expect(group.members.length, 1);
      expect(group.members.first.id, 'u1');
    });

    test('adiciona membro ao grupo existente', () async {
      final storage = LocalStorageService();
      final creator = const UserModel(id: 'u1', name: 'Jefferson');
      final group = await storage.createGroup('Turma A', creator: creator);

      final updated = await storage.addMember(group.id, 'Ana');
      expect(updated.members.length, 2);
      expect(updated.members.any((m) => m.name == 'Ana'), isTrue);
    });

    test('remove membro do grupo', () async {
      final storage = LocalStorageService();
      final creator = const UserModel(id: 'u1', name: 'Jefferson');
      final group = await storage.createGroup('Turma A', creator: creator);
      final updated = await storage.addMember(group.id, 'Ana');
      final anaId = updated.members.last.id;

      await storage.removeMember(group.id, anaId);
      final groups = await storage.getGroups();
      expect(groups.first.members.length, 1);
    });

    test('renomeia grupo corretamente', () async {
      final storage = LocalStorageService();
      final creator = const UserModel(id: 'u1', name: 'Jefferson');
      final group = await storage.createGroup('Nome Antigo', creator: creator);

      final renamed = await storage.renameGroup(group.id, 'Nome Novo');
      expect(renamed.name, 'Nome Novo');
    });

    test('exclui grupo', () async {
      final storage = LocalStorageService();
      final creator = const UserModel(id: 'u1', name: 'Jefferson');
      final group = await storage.createGroup('Para Excluir', creator: creator);

      await storage.deleteGroup(group.id);
      final groups = await storage.getGroups();
      expect(groups.isEmpty, isTrue);
    });

    test('lança LocalStorageException ao adicionar membro em grupo inexistente',
        () async {
      final storage = LocalStorageService();
      expect(
        () => storage.addMember('id-fantasma', 'Alguém'),
        throwsA(isA<LocalStorageException>()),
      );
    });
  });

  group('usuário — persistência', () {
    test('salva e recupera usuário', () async {
      final storage = LocalStorageService();
      final user = const UserModel(id: 'u1', name: 'Jefferson');
      await storage.saveUser(user);

      final recovered = await storage.getUser();
      expect(recovered?.id, 'u1');
      expect(recovered?.name, 'Jefferson');
    });

    test('retorna null quando não há usuário salvo', () async {
      final storage = LocalStorageService();
      final user = await storage.getUser();
      expect(user, isNull);
    });

    test('clearUser remove o usuário salvo', () async {
      final storage = LocalStorageService();
      await storage.saveUser(const UserModel(id: 'u1', name: 'Jefferson'));
      await storage.clearUser();

      final user = await storage.getUser();
      expect(user, isNull);
    });
  });
}
