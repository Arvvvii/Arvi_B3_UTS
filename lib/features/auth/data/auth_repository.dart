import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<UserModel> login(String email, String password) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Login failed: User is null');
    }

    final String userId = response.user!.id;
    final String userEmail = response.user!.email ?? email;

    // Ambil role dari tabel profiles
    final profileResponse = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    String name = userEmail.split('@').first;
    UserRole role = UserRole.user;

    if (profileResponse != null) {
      if (profileResponse['name'] != null) {
        name = profileResponse['name'];
      }
      if (profileResponse['role'] != null) {
        try {
          role = UserRole.values.firstWhere(
            (e) => e.name == profileResponse['role']
          );
        } catch (_) {}
      }
    }
    
    final user = UserModel(
      id: userId,
      name: name,
      email: userEmail,
      role: role,
    );

    // Save auth token dummy / role dummy mechanism is no longer really needed 
    // since Supabase handles session but let's keep role in prefs if needed later
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', user.role.toString());

    return user;
  }

  Future<UserModel?> restoreSession() async {
    final session = _supabaseClient.auth.currentSession;
    if (session == null || session.user == null) {
      return null;
    }

    final String userId = session.user!.id;
    final String userEmail = session.user!.email ?? '';

    final profileResponse = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    String name = userEmail.split('@').first;
    UserRole role = UserRole.user;

    if (profileResponse != null) {
      if (profileResponse['name'] != null) {
        name = profileResponse['name'];
      }
      if (profileResponse['role'] != null) {
        try {
          role = UserRole.values.firstWhere(
            (e) => e.name == profileResponse['role']
          );
        } catch (_) {}
      }
    }

    final user = UserModel(
      id: userId,
      name: name,
      email: userEmail,
      role: role,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', user.role.toString());

    return user;
  }

  Future<void> logout() async {
    await _supabaseClient.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Registration failed');
    }

    // Auto-create profile in public.profiles table
    await _supabaseClient.from('profiles').insert({
      'id': response.user!.id,
      'full_name': name,
      'username': email,
      'role': 'user', // Default role for public registration
    });

    return UserModel(
      id: response.user!.id,
      name: name,
      email: response.user!.email ?? email,
      role: UserRole.user,
    );
  }

  Future<void> resetPassword(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
