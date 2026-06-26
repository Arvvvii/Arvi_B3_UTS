import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      print('--- [DEBUG AUTH_REPOSITORY] Profile Response: $profileResponse');
      if (profileResponse['full_name'] != null) {
        name = profileResponse['full_name'];
      } else if (profileResponse['username'] != null) {
        name = profileResponse['username'];
      }
      if (profileResponse['role'] != null) {
        try {
          role = UserRole.values.firstWhere(
            (e) => e.name.toLowerCase() == profileResponse['role'].toString().toLowerCase()
          );
        } catch (_) {}
      }
    } else {
      print('--- [DEBUG AUTH_REPOSITORY] Profile Response is NULL. RLS Policy issue?');
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
      print('--- [DEBUG AUTH_REPOSITORY] Profile Response: $profileResponse');
      if (profileResponse['full_name'] != null) {
        name = profileResponse['full_name'];
      } else if (profileResponse['username'] != null) {
        name = profileResponse['username'];
      }
      if (profileResponse['role'] != null) {
        try {
          role = UserRole.values.firstWhere(
            (e) => e.name.toLowerCase() == profileResponse['role'].toString().toLowerCase()
          );
        } catch (_) {}
      }
    } else {
      print('--- [DEBUG AUTH_REPOSITORY] Profile Response is NULL. RLS Policy issue?');
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
      data: {
        'full_name': name,
        'username': email,
      }
    );
    
    if (response.user == null) {
      throw Exception('Registration failed');
    }

    try {
      // Auto-create profile in public.profiles table
      // Gunakan UPSERT agar tidak error jika trigger Supabase sudah otomatis membuatnya
      await _supabaseClient.from('profiles').upsert({
        'id': response.user!.id,
        'full_name': name,
        'username': email,
        'role': 'user', // Default role for public registration
      });
    } catch (e) {
      print('--- [DEBUG AUTH_REPOSITORY] Failed to insert profile manually (RLS/Trigger): $e');
      // Kita abaikan error ini karena user sudah terdaftar di auth.users
      // dan kemungkinan besar ada trigger / RLS yang memblokir.
    }

    return UserModel(
      id: response.user!.id,
      name: name,
      email: response.user!.email ?? email,
      role: UserRole.user,
    );
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final String baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode >= 400) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Gagal mereset password');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
