// lib/services/ranking_service.dart
//
// Responsável por:
//   1. Detectar se o mês virou desde o último fechamento
//   2. Calcular o ranking do mês anterior
//   3. Salvar o MonthlyResult
//
// Chamado em _load() do GroupScreen — silencioso se já fechou o mês.

import '../models/contribution_model.dart';
import '../models/group_model.dart';
import '../models/monthly_result_model.dart';
import '../models/ranking_entry.dart';
import 'local_storage_service.dart';

class RankingService {
  final LocalStorageService _storage;

  RankingService(this._storage);

  // ── Ponto de entrada: chame ao abrir o GroupScreen ────────────────────────
  // Verifica se há mês(es) para fechar e salva os resultados pendentes.
  // Retorna true se fechou algum mês (para forçar reload na UI).
  Future<bool> checkAndCloseMonths(GroupModel group) async {
    final currentMonth = _currentMonth();
    final existing     = await _storage.getMonthlyResults(groupId: group.id);
    final closedMonths = existing.map((r) => r.month).toSet();

    // Busca todos os meses com contribuições neste grupo
    final allContribs = await _storage.getContributions();
    final groupContribs = allContribs
        .where((c) => c.groupId == group.id)
        .toList();

    // Meses únicos que têm contribuições (exceto o mês atual)
    final monthsToClose = groupContribs
        .map((c) => c.month)
        .toSet()
        .where((m) => m != currentMonth && !closedMonths.contains(m))
        .toList()
      ..sort(); // ordem cronológica

    if (monthsToClose.isEmpty) return false;

    for (final month in monthsToClose) {
      await _closeMonth(group: group, month: month, contribs: groupContribs);
    }
    return true;
  }

  // ── Fecha um mês específico ───────────────────────────────────────────────
  Future<void> _closeMonth({
    required GroupModel group,
    required String month,
    required List<ContributionModel> contribs,
  }) async {
    // Contribuições do mês alvo
    final monthContribs = contribs
        .where((c) => c.month == month)
        .toList();

    if (monthContribs.isEmpty) return;

    // Monta entradas de ranking para cada membro do grupo
    final entries = <RankingEntry>[];
    for (final member in group.members) {
      ContributionModel? contrib;
      for (final c in monthContribs) {
        if (c.userId == member.id) {
          contrib = c;
          break;
        }
      }
      entries.add(RankingEntry(member: member, contribution: contrib));
    }

    // Ordena: maior progresso primeiro; empate → nome
    entries.sort((a, b) {
      final diff = b.progress.compareTo(a.progress);
      return diff != 0 ? diff : a.member.name.compareTo(b.member.name);
    });

    // Monta snapshots com posição
    final snapshots = entries.asMap().entries.map((e) {
      return RankingSnapshot(
        userId:   e.value.member.id,
        userName: e.value.member.name,
        progress: e.value.progress,
        position: e.key + 1,
      );
    }).toList();

    // Vencedor = maior progresso (só conta se tiver contribuído)
    final winner = entries.isNotEmpty && entries.first.contribution != null
        ? entries.first
        : null;

    final result = MonthlyResultModel(
      id:         _newId(),
      groupId:    group.id,
      month:      month,
      ranking:    snapshots,
      winnerId:   winner?.member.id,
      winnerName: winner?.member.name,
    );

    await _storage.saveMonthlyResult(result);
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
