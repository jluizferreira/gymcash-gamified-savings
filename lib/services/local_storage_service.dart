// lib/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contribution_model.dart';
import '../models/contribution_save_result.dart';
import '../models/group_model.dart';
import '../models/monthly_result_model.dart';
import '../models/user_model.dart';
import '../utils/id_generator.dart';

class LocalStorageService {
  // ── Chaves ────────────────────────────────────────────────────────────────
  static const _keyUser           = 'user';
  static const _keyContributions  = 'contributions';
  static const _keyGroups         = 'groups';
  static const _keyMonthlyResults = 'monthly_results';

  // ══════════════════════════════════════════════════════════════════════════
  // USUÁRIO
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (!ok) throw const LocalStorageException('Erro ao salvar usuário.');
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTRIBUIÇÕES
  // ══════════════════════════════════════════════════════════════════════════

  /// Retorna todas as contribuições salvas (todos os usuários / grupos).
  Future<List<ContributionModel>> getContributions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyContributions);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retorna a contribuição do [userId] no [groupId] para o mês atual,
  /// ou null se ainda não existir.
  Future<ContributionModel?> getContribution({
    required String userId,
    required String groupId,
  }) async {
    final all   = await getContributions();
    final month = _currentMonth();
    try {
      return all.firstWhere(
        (c) => c.userId == userId && c.groupId == groupId && c.month == month,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna todas as contribuições de um grupo (todos os meses).
  Future<List<ContributionModel>> getGroupContributions({
    required String groupId,
  }) async {
    final all = await getContributions();
    return all.where((c) => c.groupId == groupId).toList();
  }

  /// Salva ou atualiza a contribuição do mês atual.
  /// Retorna [ContributionSaveResult] indicando se a meta foi atingida agora.
  Future<ContributionSaveResult> saveContribution({
    required String userId,
    required String groupId,
    required double amount,
    required double goal,
  }) async {
    try {
      final prefs    = await SharedPreferences.getInstance();
      final monthKey = _currentMonth();
      final all      = await getContributions();

      final index = all.indexWhere((c) =>
          c.userId  == userId &&
          c.groupId == groupId &&
          c.month   == monthKey);

      bool goalJustReached = false;
      ContributionModel contribution;

      if (index != -1) {
        final existing = all[index];
        if (amount >= goal && !existing.isGoalNotified && goal > 0) {
          goalJustReached = true;
        }
        contribution = existing.copyWith(
          amount:          amount,
          goal:            goal,
          isGoalNotified:  goalJustReached ? true : existing.isGoalNotified,
        );
        all[index] = contribution;
      } else {
        goalJustReached = amount >= goal && goal > 0;
        contribution = ContributionModel(
          id:             IdGenerator.newId(),
          userId:         userId,
          groupId:        groupId,
          amount:         amount,
          goal:           goal,
          month:          monthKey,
          isGoalNotified: goalJustReached,
        );
        all.add(contribution);
      }

      final ok = await prefs.setString(
        _keyContributions,
        jsonEncode(all.map((e) => e.toJson()).toList()),
      );
      if (!ok) {
        throw const LocalStorageException('Erro ao persistir contribuição.');
      }

      return ContributionSaveResult(
        contribution:    contribution,
        goalJustReached: goalJustReached,
      );
    } on LocalStorageException {
      rethrow;
    } catch (e) {
      throw LocalStorageException('Falha ao salvar contribuição: $e');
    }
  }

  /// Soma o total acumulado de todas as contribuições do [userId].
  Future<double> getTotalAccumulated(String userId) async {
    final all = await getContributions();
    return all
        .where((c) => c.userId == userId)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }

  /// Alias mantido para compatibilidade com telas existentes.
  Future<double> getTotalAccumulatedAmount(String userId) =>
      getTotalAccumulated(userId);

  // ══════════════════════════════════════════════════════════════════════════
  // GRUPOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<GroupModel>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyGroups);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveGroups(List<GroupModel> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      _keyGroups,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
    if (!ok) throw const LocalStorageException('Erro ao salvar grupos.');
  }

  Future<GroupModel> createGroup(
    String name, {
    required UserModel creator,
  }) async {
    final groups = await getGroups();
    final group  = GroupModel(
      id:      IdGenerator.newId(),
      name:    name.trim(),
      members: [creator],
    );
    groups.add(group);
    await _saveGroups(groups);
    return group;
  }

  Future<GroupModel> addMember(String groupId, String memberName) async {
    final groups = await getGroups();
    final idx    = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw const LocalStorageException('Grupo não encontrado.');

    final newMember = UserModel(
      id:   IdGenerator.newId(),
      name: memberName.trim(),
    );
    final updated = groups[idx].copyWith(
      members: [...groups[idx].members, newMember],
    );
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  Future<void> removeMember(String groupId, String memberId) async {
    final groups = await getGroups();
    final idx    = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;

    final updated = groups[idx].copyWith(
      members: groups[idx].members.where((m) => m.id != memberId).toList(),
    );
    groups[idx] = updated;
    await _saveGroups(groups);
  }

  Future<GroupModel> renameGroup(String groupId, String newName) async {
    final groups = await getGroups();
    final idx    = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw const LocalStorageException('Grupo não encontrado.');

    final updated = groups[idx].copyWith(name: newName.trim());
    groups[idx]   = updated;
    await _saveGroups(groups);
    return updated;
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == groupId);
    await _saveGroups(groups);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RESULTADOS MENSAIS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<MonthlyResultModel>> getMonthlyResults({String? groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyMonthlyResults);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final all  = list
        .map((e) => MonthlyResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (groupId != null) {
      return all.where((r) => r.groupId == groupId).toList();
    }
    return all;
  }

  Future<void> saveMonthlyResult(MonthlyResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final all   = await getMonthlyResults();

    // Idempotência: remove resultado anterior do mesmo grupo/mês antes de inserir
    all.removeWhere(
      (r) => r.groupId == result.groupId && r.month == result.month,
    );
    all.add(result);

    final ok = await prefs.setString(
      _keyMonthlyResults,
      jsonEncode(all.map((r) => r.toJson()).toList()),
    );
    if (!ok) {
      throw const LocalStorageException('Erro ao salvar resultado mensal.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

// ── Exceção tipada para erros de armazenamento ────────────────────────────────
class LocalStorageException implements Exception {
  final String message;
  const LocalStorageException(this.message);

  @override
  String toString() => message;
}
