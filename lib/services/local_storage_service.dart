// lib/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/contribution_model.dart';
import '../models/monthly_result_model.dart';

class LocalStorageService {
  static const _keyUserName     = 'user_name';
  static const _keyUserId       = 'user_id';
  static const _keyGroups       = 'groups';
  static const _keyContributions   = 'contributions';
  static const _keyMonthlyResults   = 'monthly_results';

  // ════════════════════════════════════════════════════════════════════════════
  // USUÁRIO
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, user.name.trim());
    await prefs.setString(_keyUserId,   user.id);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyUserName);
    final id   = prefs.getString(_keyUserId);
    if (name == null || name.isEmpty) return null;
    return UserModel(id: id ?? _newId(), name: name);
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserId);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GRUPOS
  // ════════════════════════════════════════════════════════════════════════════

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
    await prefs.setString(
        _keyGroups, jsonEncode(groups.map((g) => g.toJson()).toList()));
  }

  Future<GroupModel> createGroup(String name, {UserModel? creator}) async {
    final groups        = await getGroups();
    final initialMembers = creator != null ? [creator] : <UserModel>[];
    final newGroup = GroupModel(
        id: _newId(), name: name.trim(), members: initialMembers);
    groups.add(newGroup);
    await _saveGroups(groups);
    return newGroup;
  }

  Future<GroupModel> addMember(String groupId, String memberName) async {
    final groups = await getGroups();
    final idx    = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw Exception('Grupo não encontrado: $groupId');

    final newMember     = UserModel(id: _newId(), name: memberName.trim());
    final alreadyExists = groups[idx].members.any((m) => m.id == newMember.id);
    if (alreadyExists) return groups[idx];

    final updated = groups[idx]
        .copyWith(members: [...groups[idx].members, newMember]);
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.id == groupId);
    await _saveGroups(groups);
    // Limpa contribuições do grupo excluído
    final contribs = await getContributions();
    contribs.removeWhere((c) => c.groupId == groupId);
    await _saveContributions(contribs);
  }

  Future<GroupModel> removeMember(String groupId, String memberId) async {
    final groups = await getGroups();
    final idx    = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw Exception('Grupo não encontrado: $groupId');

    final updated = groups[idx].copyWith(
        members: groups[idx].members.where((m) => m.id != memberId).toList());
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONTRIBUIÇÕES
  // ════════════════════════════════════════════════════════════════════════════

  // ── Carrega todas as contribuições ───────────────────────────────────────
  Future<List<ContributionModel>> getContributions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyContributions);
    if (raw == null || raw.isEmpty) return [];
    final list  = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveContributions(List<ContributionModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyContributions, jsonEncode(list.map((c) => c.toJson()).toList()));
  }

  // ── Busca contribuição de um usuário num grupo no mês atual ───────────────
  Future<ContributionModel?> getContribution({
    required String userId,
    required String groupId,
    String? month,
  }) async {
    final all   = await getContributions();
    final target = month ?? ContributionModel.currentMonth();
    try {
      return all.firstWhere((c) =>
          c.userId == userId && c.groupId == groupId && c.month == target);
    } catch (_) {
      return null;
    }
  }

  // ── Salva ou atualiza contribuição (1 por mês por usuário por grupo) ──────
  Future<ContributionModel> saveContribution({
    required String userId,
    required String groupId,
    required double amount,
    required double goal,
  }) async {
    final all   = await getContributions();
    final month = ContributionModel.currentMonth();
    final idx   = all.indexWhere((c) =>
        c.userId == userId && c.groupId == groupId && c.month == month);

    ContributionModel contribution;

    if (idx >= 0) {
      // Atualiza existente
      contribution = all[idx].copyWith(amount: amount, goal: goal);
      all[idx]     = contribution;
    } else {
      // Cria nova
      contribution = ContributionModel(
        id:      _newId(),
        userId:  userId,
        groupId: groupId,
        amount:  amount,
        goal:    goal,
        month:   month,
      );
      all.add(contribution);
    }

    await _saveContributions(all);
    return contribution;
  }

  // ── Retorna contribuições do mês atual para um grupo inteiro ──────────────
  Future<List<ContributionModel>> getGroupContributions({
    required String groupId,
    String? month,
  }) async {
    final all    = await getContributions();
    final target = month ?? ContributionModel.currentMonth();
    return all
        .where((c) => c.groupId == groupId && c.month == target)
        .toList();
  }

  // ── Total acumulado de um usuário (todos os meses, todos os grupos) ──────
  // Soma todos os `amount` onde userId == userId fornecido.
  // Não duplica: cada contribuição é única por (userId, groupId, month).
  Future<double> getTotalAccumulated(String userId) async {
    final all = await getContributions();
    return all
        .where((c) => c.userId == userId)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }


  // ════════════════════════════════════════════════════════════════════════════
  // RESULTADOS MENSAIS
  // ════════════════════════════════════════════════════════════════════════════

  // ── Carrega todos os resultados ───────────────────────────────────────────
  Future<List<MonthlyResultModel>> getMonthlyResults({String? groupId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyMonthlyResults);
    if (raw == null || raw.isEmpty) return [];
    final list  = jsonDecode(raw) as List<dynamic>;
    final all   = list
        .map((e) => MonthlyResultModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (groupId != null) {
      return all.where((r) => r.groupId == groupId).toList()
        ..sort((a, b) => b.month.compareTo(a.month)); // mais recente primeiro
    }
    return all;
  }

  // ── Salva um resultado mensal (nunca sobrescreve — cada mês é único) ──────
  Future<void> saveMonthlyResult(MonthlyResultModel result) async {
    final prefs   = await SharedPreferences.getInstance();
    final raw     = prefs.getString(_keyMonthlyResults);
    final list    = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as List<dynamic>)
            .map((e) => MonthlyResultModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MonthlyResultModel>[];

    // Garante unicidade: remove versão antiga se existir (idempotente)
    list.removeWhere(
        (r) => r.groupId == result.groupId && r.month == result.month);
    list.add(result);

    await prefs.setString(
        _keyMonthlyResults, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  
  // ── Meses únicos em que um usuário contribuiu (amount > 0) ───────────────
  // Usado pelo StreakService — evita carregar todas as contribuições de fora.
  Future<List<String>> getUserActiveMonths(String userId) async {
    final all = await getContributions();
    return all
        .where((c) => c.userId == userId && c.amount > 0)
        .map((c) => c.month)
        .toSet()
        .toList()
      ..sort();
  }

    // ── ID único ──────────────────────────────────────────────────────────────
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
