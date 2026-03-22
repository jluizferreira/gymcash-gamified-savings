// lib/models/contribution_model.dart

class ContributionModel {
  final String id;
  final String userId;
  final String groupId;
  final double amount; // valor guardado no mês
  final double goal;   // meta individual
  final String month;  // formato: "YYYY-MM"
  /// Indica se o usuário já foi notificado sobre a meta (ex.: toast/diálogo).
  final bool isGoalNotified;

  const ContributionModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.goal,
    required this.month,
    this.isGoalNotified = false,
  });

  // Progresso de 0.0 a 1.0+ (pode passar de 100%)
  double get progress => goal > 0 ? (amount / goal).clamp(0.0, 1.0) : 0.0;

  // Exibe como porcentagem inteira: "72%"
  String get progressLabel => '${(progress * 100).toStringAsFixed(0)}%';

  // Cópia com campos alterados
  ContributionModel copyWith({
    double? amount,
    double? goal,
    bool? isGoalNotified,
  }) =>
      ContributionModel(
        id:               id,
        userId:           userId,
        groupId:          groupId,
        amount:           amount ?? this.amount,
        goal:             goal ?? this.goal,
        month:            month,
        isGoalNotified:   isGoalNotified ?? this.isGoalNotified,
      );

  // ── Serialização JSON ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id':               id,
        'userId':           userId,
        'groupId':          groupId,
        'amount':           amount,
        'goal':             goal,
        'month':            month,
        'isGoalNotified':   isGoalNotified,
      };

  factory ContributionModel.fromJson(Map<String, dynamic> json) =>
      ContributionModel(
        id:               json['id'] as String,
        userId:           json['userId'] as String,
        groupId:          json['groupId'] as String,
        amount:           (json['amount'] as num).toDouble(),
        goal:             (json['goal'] as num).toDouble(),
        month:            json['month'] as String,
        isGoalNotified:   json['isGoalNotified'] as bool? ?? false,
      );

  // Retorna o mês atual no formato "YYYY-MM"
  static String currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
