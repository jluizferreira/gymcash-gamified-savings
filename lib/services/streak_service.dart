// lib/services/streak_service.dart
//
// Calcula a sequência (streak) de meses consecutivos do usuário
// a partir das contribuições salvas.

import 'local_storage_service.dart';

class StreakService {
  final LocalStorageService _storage;

  StreakService(this._storage);

  // ── Calcula o streak do usuário (todos os grupos somados) ─────────────────
  Future<int> calculateStreak(String userId) async {
    final allContribs = await _storage.getContributions(); // sem parâmetro

    final userContribs = allContribs
        .where((c) => c.userId == userId && c.amount > 0)
        .toList();

    if (userContribs.isEmpty) return 0;

    final activeMonths = userContribs
        .map((c) => c.month)
        .toSet()
        .toList()
      ..sort();

    if (activeMonths.isEmpty) return 0;

    int streak = 1;
    for (int i = activeMonths.length - 1; i > 0; i--) {
      if (_isConsecutive(activeMonths[i - 1], activeMonths[i])) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ── Retorna o último mês em que o usuário contribuiu ─────────────────────
  Future<String?> lastActiveMonth(String userId) async {
    final allContribs = await _storage.getContributions(); // sem parâmetro
    final months = allContribs
        .where((c) => c.userId == userId && c.amount > 0)
        .map((c) => c.month)
        .toList()
      ..sort();
    return months.isEmpty ? null : months.last;
  }

  bool _isConsecutive(String earlier, String later) {
    final e = _parse(earlier);
    final l = _parse(later);
    if (e == null || l == null) return false;
    final next = DateTime(e.year, e.month + 1);
    return next.year == l.year && next.month == l.month;
  }

  DateTime? _parse(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null) return null;
    return DateTime(y, m);
  }
}
