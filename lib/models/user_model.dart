// lib/models/user_model.dart
//
// Expandido: agora tem 'id' além do 'name'.
// Compatível com o onboarding existente — id é gerado automaticamente.

class UserModel {
  final String id;
  final String name;

  const UserModel({required this.id, required this.name});

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  // ── Serialização JSON (para salvar no SharedPreferences) ──────────────────
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
