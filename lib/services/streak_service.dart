// lib/services/streak_service.dart
//
// Calcula a sequência (streak) de meses consecutivos de um usuário
// a partir das contribuições já salvas — sem nenhum dado extra.
//
// Regras:
//   - Conta apenas meses onde amount > 0
//   - Sequência é CONTÍGUA e termina no mês atual (ou mais recente)
//   - Se o usuário pulou um mês → streak volta a 0 e recomeça
//   - O mês atual conta mesmo que ainda não tenha acabado

import 'local_storage_service.dart';

class StreakService {
  final LocalStorageService _storage;

  StreakService(this._storage);

  // ── Calcula o streak do usuário (todos os grupos somados) ─────────────────
  Future<int> calculateStreak(String userId) async {
    final allContribs = await _storage.getContributions();

    // Filtra contribuições do usuário com amount > 0
    final userContribs = allContribs
        .where((c) => c.userId == userId && c.amount > 0)
        .toList();

    if (userContribs.isEmpty) return 0;

    // Coleta os meses únicos em que o usuário contribuiu
    final activeMonths = userContribs
        .map((c) => c.month)
        .toSet()
        .toList()
      ..sort(); // ordem cronológica crescente: ["2024-11", "2024-12", "2025-01"]

    if (activeMonths.isEmpty) return 0;

    // Conta sequência CONTÍGUA retroativa a partir do mês mais recente
    int streak = 1;
    for (int i = activeMonths.length - 1; i > 0; i--) {
      if (_isConsecutive(activeMonths[i - 1], activeMonths[i])) {
        streak++;
      } else {
        break; // sequência quebrada — para a contagem
      }
    }

    return streak;
  }

  // ── Retorna o último mês em que o usuário contribuiu ─────────────────────
  Future<String?> lastActiveMonth(String userId) async {
    final allContribs = await _storage.getContributions();
    final months = allContribs
        .where((c) => c.userId == userId && c.amount > 0)
        .map((c) => c.month)
        .toList()
      ..sort();
    return months.isEmpty ? null : months.last;
  }

  // ── Verifica se dois meses "YYYY-MM" são consecutivos ────────────────────
  // Ex: ("2024-12", "2025-01") → true
  //     ("2024-11", "2025-01") → false (pulou dezembro)
  bool _isConsecutive(String earlier, String later) {
    final e = _parse(earlier);
    final l = _parse(later);
    if (e == null || l == null) return false;

    // Avança 1 mês a partir de `earlier` e compara com `later`
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
