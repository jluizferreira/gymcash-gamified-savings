// lib/models/contribution_model.dart

class ContributionModel {
  final String id;
  final String userId;
  final String groupId;
  final double amount;
  final double goal;
  final String month; // Formato "YYYY-MM"
  final bool isGoalNotified;

  ContributionModel({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.goal,
    required this.month,
    this.isGoalNotified = false,
  });

  // --- GETTER DE INSTÂNCIA: mês formatado desta contribuição ---
  String get currentMonthLabel {
    final parts = month.split('-');
    if (parts.length < 2) return month;
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final monthInt = int.tryParse(parts[1]) ?? 1;
    return months[monthInt - 1];
  }

  // --- MÉTODO ESTÁTICO: retorna o mês atual formatado ---
  static String currentMonth() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[now.month - 1];
  }

  /// Progresso de 0.0 a 1.0 (usado pelo RankingEntry e barra de progresso).
  double get progress => goal > 0 ? (amount / goal).clamp(0.0, double.infinity) : 0.0;

  String get progressLabel {
    if (goal <= 0) return "0%";
    final percent = (amount / goal) * 100;
    return "${percent.toStringAsFixed(0)}%";
  }

  // --- MÉTODOS DE SERIALIZAÇÃO ---

  ContributionModel copyWith({
    String? id,
    String? userId,
    String? groupId,
    double? amount,
    double? goal,
    String? month,
    bool? isGoalNotified,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      goal: goal ?? this.goal,
      month: month ?? this.month,
      isGoalNotified: isGoalNotified ?? this.isGoalNotified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'groupId': groupId,
        'amount': amount,
        'goal': goal,
        'month': month,
        'isGoalNotified': isGoalNotified,
      };

  factory ContributionModel.fromJson(Map<String, dynamic> json) =>
      ContributionModel(
        id: json['id'],
        userId: json['userId'],
        groupId: json['groupId'],
        amount: (json['amount'] as num).toDouble(),
        goal: (json['goal'] as num).toDouble(),
        month: json['month'],
        isGoalNotified: json['isGoalNotified'] ?? false,
      );
}
