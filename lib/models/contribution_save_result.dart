// lib/models/contribution_save_result.dart
//
// Retorno de persistir contribuição; [goalJustReached] indica que a meta foi
// batida nesta gravação e o usuário ainda não tinha sido notificado.

import 'contribution_model.dart';

class ContributionSaveResult {
  const ContributionSaveResult({
    required this.contribution,
    required this.goalJustReached,
  });

  final ContributionModel contribution;
  final bool goalJustReached;
}
