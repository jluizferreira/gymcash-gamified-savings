// lib/models/rank_model.dart
//
// Patentes baseadas no total acumulado do usuário.

class RankModel {
  final String id;
  final String title;
  final String emoji;
  final double minAmount; // valor mínimo para atingir esta patente
  final int colorValue;   // cor principal da patente

  const RankModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.minAmount,
    required this.colorValue,
  });

  // ── Tabela de patentes em ordem crescente ─────────────────────────────────
  static const List<RankModel> ranks = [
    RankModel(id: 'bronze',   title: 'Bronze',   emoji: '🥉',
        minAmount: 0,    colorValue: 0xFFCD7F32),
    RankModel(id: 'silver',   title: 'Prata',    emoji: '🥈',
        minAmount: 100,  colorValue: 0xFFC0C0C0),
    RankModel(id: 'gold',     title: 'Ouro',     emoji: '✨',
        minAmount: 300,  colorValue: 0xFFFFD700),
    RankModel(id: 'platinum', title: 'Platina',  emoji: '💎',
        minAmount: 700,  colorValue: 0xFF00E5FF),
    RankModel(id: 'diamond',  title: 'Diamante', emoji: '💠',
        minAmount: 1500, colorValue: 0xFF00B0FF),
  ];

  // ── Calcula a patente atual dado um total acumulado ───────────────────────
  static RankModel fromTotal(double total) {
    // Percorre do maior para o menor e retorna o primeiro que o total atinge
    for (final rank in ranks.reversed) {
      if (total >= rank.minAmount) return rank;
    }
    return ranks.first; // Bronze como fallback
  }

  // ── Próxima patente (null se já é Diamante) ───────────────────────────────
  static RankModel? nextRank(RankModel current) {
    final idx = ranks.indexWhere((r) => r.id == current.id);
    if (idx < 0 || idx >= ranks.length - 1) return null;
    return ranks[idx + 1];
  }

  // ── Progresso até a próxima patente (0.0–1.0) ────────────────────────────
  static double progressToNext(double total) {
    final current = fromTotal(total);
    final next    = nextRank(current);
    if (next == null) return 1.0; // já no topo
    final range = next.minAmount - current.minAmount;
    final done  = total - current.minAmount;
    return (done / range).clamp(0.0, 1.0);
  }
}
