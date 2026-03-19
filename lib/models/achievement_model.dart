// lib/models/achievement_model.dart
//
// Define todas as conquistas do app e seu estado de desbloqueio.
// A lista canônica vive em AchievementModel.all — nunca em SharedPreferences.
// O que persiste é apenas o Set de IDs desbloqueados.

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  AchievementModel copyWith({bool? isUnlocked, DateTime? unlockedAt}) =>
      AchievementModel(
        id:          id,
        title:       title,
        description: description,
        emoji:       emoji,
        isUnlocked:  isUnlocked  ?? this.isUnlocked,
        unlockedAt:  unlockedAt  ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'isUnlocked':  isUnlocked,
        'unlockedAt':  unlockedAt?.toIso8601String(),
      };

  // Reconstrói a partir do JSON salvo + definição canônica
  factory AchievementModel.fromSaved({
    required AchievementModel definition,
    required Map<String, dynamic> saved,
  }) =>
      definition.copyWith(
        isUnlocked: saved['isUnlocked'] as bool? ?? false,
        unlockedAt: saved['unlockedAt'] != null
            ? DateTime.tryParse(saved['unlockedAt'] as String)
            : null,
      );

  // ── Lista canônica de conquistas ──────────────────────────────────────────
  static List<AchievementModel> get all => [
        const AchievementModel(
          id:          'first_deposit',
          title:       'Primeiro depósito',
          description: 'Registre sua primeira contribuição',
          emoji:       '💰',
        ),
        const AchievementModel(
          id:          'streak_3',
          title:       'Em chamas',
          description: '3 meses consecutivos de contribuição',
          emoji:       '🔥',
        ),
        const AchievementModel(
          id:          'streak_6',
          title:       'Imparável',
          description: '6 meses consecutivos de contribuição',
          emoji:       '⚡',
        ),
        const AchievementModel(
          id:          'streak_12',
          title:       'Lendário',
          description: '12 meses consecutivos de contribuição',
          emoji:       '👑',
        ),
        const AchievementModel(
          id:          'first_win',
          title:       'Primeiro lugar',
          description: 'Vença um ranking mensal',
          emoji:       '🥇',
        ),
        const AchievementModel(
          id:          'win_3',
          title:       'Hat-trick',
          description: 'Vença 3 rankings mensais',
          emoji:       '🏆',
        ),
        const AchievementModel(
          id:          'goal_reached',
          title:       'Meta batida',
          description: 'Atinja 100% da sua meta em um mês',
          emoji:       '🎯',
        ),
        const AchievementModel(
          id:          'rank_silver',
          title:       'Prata',
          description: 'Alcance a patente Prata (R\$ 100 acumulados)',
          emoji:       '🥈',
        ),
        const AchievementModel(
          id:          'rank_gold',
          title:       'Ouro',
          description: 'Alcance a patente Ouro (R\$ 300 acumulados)',
          emoji:       '✨',
        ),
        const AchievementModel(
          id:          'rank_platinum',
          title:       'Platina',
          description: 'Alcance a patente Platina (R\$ 700 acumulados)',
          emoji:       '💎',
        ),
        const AchievementModel(
          id:          'rank_diamond',
          title:       'Diamante',
          description: 'Alcance a patente Diamante (R\$ 1500 acumulados)',
          emoji:       '💠',
        ),
      ];
}
