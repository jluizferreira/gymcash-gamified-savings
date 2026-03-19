// lib/models/monthly_result_model.dart
//
// Representa o resultado fechado de um grupo em determinado mês.
// Salvo automaticamente quando o mês vira — nunca é recalculado.

class RankingSnapshot {
  final String userId;
  final String userName;
  final double progress; // 0.0–1.0
  final int position;

  const RankingSnapshot({
    required this.userId,
    required this.userName,
    required this.progress,
    required this.position,
  });

  String get progressLabel => '${(progress * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() => {
        'userId':   userId,
        'userName': userName,
        'progress': progress,
        'position': position,
      };

  factory RankingSnapshot.fromJson(Map<String, dynamic> j) => RankingSnapshot(
        userId:   j['userId']   as String,
        userName: j['userName'] as String,
        progress: (j['progress'] as num).toDouble(),
        position: j['position'] as int,
      );
}

class MonthlyResultModel {
  final String id;
  final String groupId;
  final String month; // "YYYY-MM"
  final List<RankingSnapshot> ranking;
  final String? winnerId;   // null se nenhuma contribuição no mês
  final String? winnerName;

  const MonthlyResultModel({
    required this.id,
    required this.groupId,
    required this.month,
    required this.ranking,
    this.winnerId,
    this.winnerName,
  });

  // Formata o mês para exibição: "2025-03" → "Março 2025"
  String get monthLabel {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }

  Map<String, dynamic> toJson() => {
        'id':         id,
        'groupId':    groupId,
        'month':      month,
        'ranking':    ranking.map((r) => r.toJson()).toList(),
        'winnerId':   winnerId,
        'winnerName': winnerName,
      };

  factory MonthlyResultModel.fromJson(Map<String, dynamic> j) =>
      MonthlyResultModel(
        id:         j['id']         as String,
        groupId:    j['groupId']    as String,
        month:      j['month']      as String,
        ranking:    (j['ranking'] as List<dynamic>)
            .map((r) => RankingSnapshot.fromJson(r as Map<String, dynamic>))
            .toList(),
        winnerId:   j['winnerId']   as String?,
        winnerName: j['winnerName'] as String?,
      );
}
