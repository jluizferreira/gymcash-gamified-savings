// lib/services/achievement_service.dart
//
// Verifica e desbloqueia conquistas com base no estado atual do usuário.
// Chamado após salvar contribuição e ao abrir a HomeScreen.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_model.dart';
import 'local_storage_service.dart';
import 'streak_service.dart';

class AchievementService {
  final LocalStorageService _storage;
  static const _keyAchievements = 'achievements';

  AchievementService(this._storage);

  // ── Carrega conquistas mesclando definições com estado salvo ──────────────
  Future<List<AchievementModel>> getAchievements(String userId) async {
    final saved = await _loadSaved(userId);
    return AchievementModel.all.map((def) {
      final data = saved[def.id];
      if (data == null) return def;
      return AchievementModel.fromSaved(definition: def, saved: data);
    }).toList();
  }

  // ── Verifica e desbloqueia conquistas elegíveis ────────────────────────────
  // Retorna IDs das conquistas recém-desbloqueadas nesta chamada.
  Future<List<String>> checkAndUnlock(String userId) async {
    final streak      = await StreakService(_storage).calculateStreak(userId);
    final total       = await _storage.getTotalAccumulated(userId);
    final allContribs = await _storage.getContributions();       // sem parâmetro
    final allResults  = await _storage.getMonthlyResults();      // sem parâmetro

    final userContribs = allContribs.where((c) => c.userId == userId).toList();
    final userWins     = allResults.where((r) => r.winnerId == userId).length;
    final goalReached  =
        userContribs.any((c) => c.goal > 0 && c.amount >= c.goal);

    final shouldUnlock = <String, bool>{
      'first_deposit': userContribs.any((c) => c.amount > 0),
      'streak_3':      streak >= 3,
      'streak_6':      streak >= 6,
      'streak_12':     streak >= 12,
      'first_win':     userWins >= 1,
      'win_3':         userWins >= 3,
      'goal_reached':  goalReached,
      'rank_silver':   total >= 100,
      'rank_gold':     total >= 300,
      'rank_platinum': total >= 700,
      'rank_diamond':  total >= 1500,
    };

    final saved         = await _loadSaved(userId);
    final newlyUnlocked = <String>[];

    for (final entry in shouldUnlock.entries) {
      if (!entry.value) continue;

      final alreadySaved = saved[entry.key];
      final alreadyDone  = alreadySaved?['isUnlocked'] as bool? ?? false;
      if (alreadyDone) continue;

      saved[entry.key] = {
        'id':         entry.key,
        'isUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      };
      newlyUnlocked.add(entry.key);
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveSaved(userId, saved);
    }

    return newlyUnlocked;
  }

  // ── Conta conquistas desbloqueadas ────────────────────────────────────────
  Future<int> unlockedCount(String userId) async {
    final all = await getAchievements(userId);
    return all.where((a) => a.isUnlocked).length;
  }

  // ── Persistência por userId ───────────────────────────────────────────────
  String _keyFor(String userId) => '${_keyAchievements}_$userId';

  Future<Map<String, Map<String, dynamic>>> _loadSaved(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
  }

  Future<void> _saveSaved(
      String userId, Map<String, Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(userId), jsonEncode(data));
  }
}
