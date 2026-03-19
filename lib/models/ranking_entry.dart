// lib/models/ranking_entry.dart
//
// Agrega um membro com sua contribuição do mês para exibição no ranking.

import 'user_model.dart';
import 'contribution_model.dart';

class RankingEntry {
  final UserModel member;
  final ContributionModel? contribution; // null = ainda não contribuiu

  const RankingEntry({required this.member, this.contribution});

  // Progresso de 0.0 a 1.0
  double get progress => contribution?.progress ?? 0.0;

  // Rótulo exibido: "72%" ou "0%"
  String get progressLabel => contribution?.progressLabel ?? '0%';

  // true se atingiu ou superou a meta
  bool get goalReached => progress >= 1.0;

  // true se tem meta definida
  bool get hasGoal => (contribution?.goal ?? 0) > 0;
}
