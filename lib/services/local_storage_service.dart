// lib/services/local_storage_service.dart
//
// Gateway único para SharedPreferences. Transações = contribuições
// (ContributionModel): salvar, ler e excluir com mensagens de erro em português.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/contribution_model.dart';
import '../models/contribution_save_result.dart';
import '../models/group_model.dart';
import '../models/monthly_result_model.dart';
import '../models/user_model.dart';

/// Falha ao ler/gravar dados locais; [message] pode ser exibida ao usuário.
class LocalStorageException implements Exception {
  LocalStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalStorageService {
  static const _keyUserName = 'user_name';
  static const _keyUserId = 'user_id';
  static const _keyGroups = 'groups';
  static const _keyContributions = 'contributions';
  static const _keyMonthlyResults = 'monthly_results';

  static const _msgPrefs =
      'Não foi possível acessar o armazenamento local. Tente fechar e abrir o aplicativo novamente.';
  static const _msgWrite =
      'Não foi possível salvar os dados. Verifique o espaço em disco e tente novamente.';

  // ════════════════════════════════════════════════════════════════════════════
  // USUÁRIO
  // ════════════════════════════════════════════════════════════════════════════

  /// Persiste o perfil local do usuário.
  Future<void> saveUser(UserModel user) async {
    try {
      final prefs = await _prefs();
      final okName = await prefs.setString(_keyUserName, user.name.trim());
      final okId = await prefs.setString(_keyUserId, user.id);
      if (!okName || !okId) {
        throw LocalStorageException(_msgWrite);
      }
    } on LocalStorageException {
      rethrow;
    } catch (_) {
      throw LocalStorageException(_msgWrite);
    }
  }

  /// Retorna o usuário salvo ou `null` se não houver cadastro.
  Future<UserModel?> getUser() async {
    try {
      final prefs = await _prefs();
      final name = prefs.getString(_keyUserName);
      final id = prefs.getString(_keyUserId);
      if (name == null || name.isEmpty) return null;
      return UserModel(id: id ?? _newId(), name: name);
    } on LocalStorageException {
      rethrow;
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível ler os dados do perfil. Tente novamente.',
      );
    }
  }

  Future<void> clearUser() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserId);
    } on LocalStorageException {
      rethrow;
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível limpar o perfil. Tente novamente.',
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GRUPOS
  // ════════════════════════════════════════════════════════════════════════════

  /// Lista imutável de grupos (cópia defensiva para quem consome a API).
  Future<List<GroupModel>> getGroups() async {
    final list = await _loadGroupsMutable();
    return List<GroupModel>.unmodifiable(list);
  }

  Future<void> _saveGroups(List<GroupModel> groups) async {
    try {
      final prefs = await _prefs();
      final encoded = jsonEncode(groups.map((g) => g.toJson()).toList());
      final ok = await prefs.setString(_keyGroups, encoded);
      if (!ok) throw LocalStorageException(_msgWrite);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível preparar os grupos para salvar. Tente novamente.',
      );
    } catch (_) {
      throw LocalStorageException(_msgWrite);
    }
  }

  Future<GroupModel> createGroup(String name, {UserModel? creator}) async {
    final groups = await _loadGroupsMutable();
    final initialMembers = creator != null ? [creator] : <UserModel>[];
    final newGroup = GroupModel(
      id: _newId(),
      name: name.trim(),
      members: List<UserModel>.unmodifiable(initialMembers),
    );
    groups.add(newGroup);
    await _saveGroups(groups);
    return newGroup;
  }

  Future<GroupModel> addMember(String groupId, String memberName) async {
    final groups = await _loadGroupsMutable();
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) {
      throw LocalStorageException('Grupo não encontrado.');
    }

    final newMember = UserModel(id: _newId(), name: memberName.trim());
    final alreadyExists =
        groups[idx].members.any((m) => m.id == newMember.id);
    if (alreadyExists) return groups[idx];

    final updated = groups[idx].copyWith(
      members: [...groups[idx].members, newMember],
    );
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = await _loadGroupsMutable();
    groups.removeWhere((g) => g.id == groupId);
    await _saveGroups(groups);

    final contribs = await _loadContributionsMutable();
    contribs.removeWhere((c) => c.groupId == groupId);
    await _saveContributions(contribs);
  }

  Future<GroupModel> removeMember(String groupId, String memberId) async {
    final groups = await _loadGroupsMutable();
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) {
      throw LocalStorageException('Grupo não encontrado.');
    }

    final updated = groups[idx].copyWith(
      members: groups[idx].members.where((m) => m.id != memberId).toList(),
    );
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  /// Atualiza o nome do grupo. [newName] é normalizado com trim; vazio gera erro.
  Future<GroupModel> renameGroup(String groupId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw LocalStorageException('Informe um nome para o grupo.');
    }

    final groups = await _loadGroupsMutable();
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) {
      throw LocalStorageException('Grupo não encontrado.');
    }

    final updated = groups[idx].copyWith(name: trimmed);
    groups[idx] = updated;
    await _saveGroups(groups);
    return updated;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TRANSAÇÕES (CONTRIBUIÇÕES)
  // ════════════════════════════════════════════════════════════════════════════

  /// Todas as transações salvas, em lista imutável.
  Future<List<ContributionModel>> getContributions() async {
    final list = await _loadContributionsMutable();
    return List<ContributionModel>.unmodifiable(list);
  }

  /// Remove uma transação pelo [id]. Lança se o id não existir.
  Future<void> deleteContribution(String id) async {
    final all = await _loadContributionsMutable();
    final before = all.length;
    all.removeWhere((c) => c.id == id);
    if (all.length == before) {
      throw LocalStorageException('Transação não encontrada.');
    }
    await _saveContributions(all);
  }

  /// Busca contribuição de um usuário num grupo no mês indicado (ou mês atual).
  Future<ContributionModel?> getContribution({
    required String userId,
    required String groupId,
    String? month,
  }) async {
    final all = await _loadContributionsMutable();
    final target = month ?? ContributionModel.currentMonth();
    for (final c in all) {
      if (c.userId == userId &&
          c.groupId == groupId &&
          c.month == target) {
        return c;
      }
    }
    return null;
  }

  /// Cria ou atualiza a contribuição do mês corrente (uma por usuário/grupo/mês).
  /// Quando [goal] > 0, `amount >= goal` e ainda não houve notificação, marca
  /// [ContributionModel.isGoalNotified] e devolve [ContributionSaveResult.goalJustReached].
  Future<ContributionSaveResult> saveContribution({
    required String userId,
    required String groupId,
    required double amount,
    required double goal,
  }) async {
    final all = await _loadContributionsMutable();
    final month = ContributionModel.currentMonth();
    final idx = all.indexWhere(
      (c) =>
          c.userId == userId && c.groupId == groupId && c.month == month,
    );

    var goalJustReached = false;
    late ContributionModel contribution;

    if (idx >= 0) {
      contribution = all[idx].copyWith(amount: amount, goal: goal);
      if (goal > 0 &&
          contribution.amount >= goal &&
          !contribution.isGoalNotified) {
        contribution = contribution.copyWith(isGoalNotified: true);
        goalJustReached = true;
      }
      all[idx] = contribution;
    } else {
      contribution = ContributionModel(
        id: _newId(),
        userId: userId,
        groupId: groupId,
        amount: amount,
        goal: goal,
        month: month,
      );
      if (goal > 0 && amount >= goal && !contribution.isGoalNotified) {
        contribution = contribution.copyWith(isGoalNotified: true);
        goalJustReached = true;
      }
      all.add(contribution);
    }

    await _saveContributions(all);
    return ContributionSaveResult(
      contribution: contribution,
      goalJustReached: goalJustReached,
    );
  }

  Future<List<ContributionModel>> getGroupContributions({
    required String groupId,
    String? month,
  }) async {
    final all = await _loadContributionsMutable();
    final target = month ?? ContributionModel.currentMonth();
    final filtered = all
        .where((c) => c.groupId == groupId && c.month == target)
        .toList();
    return List<ContributionModel>.unmodifiable(filtered);
  }

  Future<double> getTotalAccumulated(String userId) async {
    final all = await _loadContributionsMutable();
    return all
        .where((c) => c.userId == userId)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RESULTADOS MENSAIS
  // ════════════════════════════════════════════════════════════════════════════

  Future<List<MonthlyResultModel>> getMonthlyResults({String? groupId}) async {
    final all = await _loadMonthlyResultsMutable();
    if (groupId != null) {
      final filtered = all.where((r) => r.groupId == groupId).toList()
        ..sort((a, b) => b.month.compareTo(a.month));
      return List<MonthlyResultModel>.unmodifiable(filtered);
    }
    return List<MonthlyResultModel>.unmodifiable(all);
  }

  /// Persiste resultado mensal; substitui registro do mesmo grupo/mês se existir.
  Future<void> saveMonthlyResult(MonthlyResultModel result) async {
    final list = await _loadMonthlyResultsMutable();
    list.removeWhere(
      (r) => r.groupId == result.groupId && r.month == result.month,
    );
    list.add(result);
    try {
      final prefs = await _prefs();
      final encoded = jsonEncode(list.map((r) => r.toJson()).toList());
      final ok = await prefs.setString(_keyMonthlyResults, encoded);
      if (!ok) throw LocalStorageException(_msgWrite);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível preparar o histórico mensal para salvar.',
      );
    } catch (_) {
      throw LocalStorageException(_msgWrite);
    }
  }

  Future<List<String>> getUserActiveMonths(String userId) async {
    final all = await _loadContributionsMutable();
    final months = all
        .where((c) => c.userId == userId && c.amount > 0)
        .map((c) => c.month)
        .toSet()
        .toList()
      ..sort();
    return List<String>.unmodifiable(months);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Internos — I/O e parsing
  // ════════════════════════════════════════════════════════════════════════════

  Future<SharedPreferences> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      throw LocalStorageException(_msgPrefs);
    }
  }

  Future<List<GroupModel>> _loadGroupsMutable() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(_keyGroups);
      if (raw == null || raw.isEmpty) return <GroupModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        throw LocalStorageException(
          'O formato dos grupos salvos é inválido.',
        );
      }
      return _parseGroupsList(decoded);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível ler os grupos: dados corrompidos ou incompletos.',
      );
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível carregar os grupos. Tente novamente.',
      );
    }
  }

  List<GroupModel> _parseGroupsList(List<dynamic> list) {
    try {
      return list
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível interpretar um ou mais grupos salvos.',
      );
    }
  }

  Future<List<ContributionModel>> _loadContributionsMutable() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(_keyContributions);
      if (raw == null || raw.isEmpty) return <ContributionModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        throw LocalStorageException(
          'O formato das transações salvas é inválido.',
        );
      }
      return _parseContributionsList(decoded);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível ler as transações: dados corrompidos ou incompletos.',
      );
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível carregar as transações. Tente novamente.',
      );
    }
  }

  List<ContributionModel> _parseContributionsList(List<dynamic> list) {
    try {
      return list
          .map(
            (e) => ContributionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível interpretar uma ou mais transações salvas.',
      );
    }
  }

  Future<void> _saveContributions(List<ContributionModel> list) async {
    try {
      final prefs = await _prefs();
      final encoded = jsonEncode(list.map((c) => c.toJson()).toList());
      final ok = await prefs.setString(_keyContributions, encoded);
      if (!ok) throw LocalStorageException(_msgWrite);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível preparar as transações para salvar.',
      );
    } catch (_) {
      throw LocalStorageException(_msgWrite);
    }
  }

  Future<List<MonthlyResultModel>> _loadMonthlyResultsMutable() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(_keyMonthlyResults);
      if (raw == null || raw.isEmpty) return <MonthlyResultModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        throw LocalStorageException(
          'O formato do histórico mensal salvo é inválido.',
        );
      }
      return _parseMonthlyResultsList(decoded);
    } on LocalStorageException {
      rethrow;
    } on FormatException {
      throw LocalStorageException(
        'Não foi possível ler o histórico mensal: dados corrompidos ou incompletos.',
      );
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível carregar o histórico mensal. Tente novamente.',
      );
    }
  }

  List<MonthlyResultModel> _parseMonthlyResultsList(List<dynamic> list) {
    try {
      return list
          .map(
            (e) => MonthlyResultModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      throw LocalStorageException(
        'Não foi possível interpretar um ou mais resultados mensais salvos.',
      );
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
