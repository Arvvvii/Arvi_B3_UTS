import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Mock network delay
    // Mock Role Based Access
    UserRole role = UserRole.user;
    if (email.contains('admin')) {
      role = UserRole.admin;
    } else if (email.contains('helpdesk')) {
      role = UserRole.helpdesk;
    }

    final user = UserModel(
      id: 'usr_123',
      name: email.split('@').first,
      email: email,
      role: role,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'mock_token_${user.id}');
    await prefs.setString('user_role', user.role.toString());

    return user;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(id: 'usr_999', name: name, email: email, role: UserRole.user);
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // simulate reset email sent
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
