import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserRepository {
  final Dio _dio;
  final SupabaseClient _supabase;

  UserRepository(this._dio, this._supabase);

  Future<List<UserModel>> getUsers() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';
      final response = await _dio.get(
        '$baseUrl/users',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('--- [ERROR] getUsers: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  Future<List<UserModel>> getHelpdeskUsers() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';
      final response = await _dio.get(
        '$baseUrl/users/helpdesk',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load helpdesk users: ${response.statusCode}');
      }
    } catch (e) {
      print('--- [ERROR] getHelpdeskUsers: $e');
      throw Exception('Failed to load helpdesk users: $e');
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated');
      }

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';
      final response = await _dio.patch(
        '$baseUrl/users/$userId/status',
        data: {'is_active': isActive},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to toggle user status: ${response.statusCode}');
      }
    } catch (e) {
      print('--- [ERROR] toggleUserStatus: $e');
      throw Exception('Failed to toggle user status: $e');
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = Dio();
  return UserRepository(dio, Supabase.instance.client);
});
