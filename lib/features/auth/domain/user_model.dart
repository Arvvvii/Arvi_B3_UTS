enum UserRole { user, helpdesk, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true, // Default to true for backward compatibility
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['full_name'] ?? json['name'] ?? '',
      email: json['username'] ?? json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['role']?.toString().toLowerCase() ?? 'user'),
        orElse: () => UserRole.user,
      ),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'is_active': isActive,
    };
  }
}
