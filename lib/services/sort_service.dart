// lib/services/sort_service.dart
//
// Persiste e aplica a preferência de ordenação da lista de grupos.
// Suporta: alfabética (A→Z) e mais recentes (ordem de criação, invertida).

import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_model.dart';

/// Critérios de ordenação disponíveis para a lista de grupos.
enum GroupSortOrder {
  /// Ordem de criação — mais recentes primeiro (padrão).
  recent,

  /// Ordem alfabética crescente pelo nome.
  alphabetical,
}

class SortService {
  static const _key = 'group_sort_order';

  /// Carrega a preferência salva. Retorna [GroupSortOrder.recent] se não há
  /// nenhuma preferência salva ainda.
  Future<GroupSortOrder> loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);
    return raw == GroupSortOrder.alphabetical.name
        ? GroupSortOrder.alphabetical
        : GroupSortOrder.recent;
  }

  /// Persiste a preferência escolhida pelo usuário.
  Future<void> saveOrder(GroupSortOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, order.name);
  }

  /// Retorna uma nova lista ordenada conforme [order].
  /// Não modifica a lista original.
  List<GroupModel> sort(List<GroupModel> groups, GroupSortOrder order) {
    final copy = List<GroupModel>.from(groups);
    switch (order) {
      case GroupSortOrder.alphabetical:
        copy.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case GroupSortOrder.recent:
        // Ordem de inserção invertida — último criado aparece primeiro.
        // Como o storage preserva a ordem de inserção, basta reverter.
        return copy.reversed.toList();
    }
    return copy;
  }
}
