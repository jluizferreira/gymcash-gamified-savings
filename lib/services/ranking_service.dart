// lib/services/ranking_service.dart
//
// Detecta se o mês virou, calcula o ranking do mês anterior e salva o resultado.
// Chamado em _load() do GroupScreen — silencioso se o mês já foi fechado.

import '../models/contribution_model.dart';
import '../models/group_model.dart';
import '../models/monthly_result_model.dart';
import '../models/ranking_entry.dart';
import 'local_storage_service.dart';

class RankingService {
  final LocalStorageService _storage;

  RankingService(this._storage);

  // ── Verifica e fecha meses pendentes ──────────────────────────────────────
  // Retorna true se fechou algum mês (para forçar reload na UI).
  Future<bool> checkAndCloseMonths(GroupModel group) async {
    final currentMonth  = _currentMonth();
    final existing      = await _storage.getMonthlyResults(groupId: group.id);
    final closedMonths  = existing.map((r) => r.month).toSet();

    final allContribs   = await _storage.getContributions(); // sem parâmetro
    final groupContribs = allContribs
        .where((c) => c.groupId == group.id)
        .toList();

    final monthsToClose = groupContribs
        .map((c) => c.month)
        .toSet()
        .where((m) => m != currentMonth && !closedMonths.contains(m))
        .toList()
      ..sort();

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
    final monthContribs = contribs.where((c) => c.month == month).toList();
    if (monthContribs.isEmpty) return;

    final entries = <RankingEntry>[];
    for (final member in group.members) {
      ContributionModel? contrib;
      for (final c in monthContribs) {
        if (c.userId == member.id) { contrib = c; break; }
      }
      entries.add(RankingEntry(member: member, contribution: contrib));
    }

    entries.sort((a, b) {
      final diff = b.progress.compareTo(a.progress);
      return diff != 0 ? diff : a.member.name.compareTo(b.member.name);
    });

    final snapshots = entries.asMap().entries.map((e) {
      return RankingSnapshot(
        userId:   e.value.member.id,
        userName: e.value.member.name,
        progress: e.value.progress,
        position: e.key + 1,
      );
    }).toList();

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

    await _storage.saveMonthlyResult(result); // método agora existe
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
