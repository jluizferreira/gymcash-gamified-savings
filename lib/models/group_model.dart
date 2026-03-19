// lib/models/group_model.dart

import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final List<UserModel> members;

  const GroupModel({
    required this.id,
    required this.name,
    required this.members,
  });

  // Cópia do grupo com campos alterados (imutabilidade)
  GroupModel copyWith({String? name, List<UserModel>? members}) => GroupModel(
        id: id,
        name: name ?? this.name,
        members: members ?? this.members,
      );

  // ── Serialização JSON ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        members: (json['members'] as List<dynamic>)
            .map((m) => UserModel.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
