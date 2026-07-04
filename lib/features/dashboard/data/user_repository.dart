import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:arvi_b3_uts/core/network/dio_client.dart';

/// [FIXED v3.0.0] UserRepository sekarang menggunakan Dio dari dioProvider
/// yang sudah dikonfigurasi dengan:
///   - baseUrl dari dotenv.env['BACKEND_URL'] (bukan API_BASE_URL yang salah)
///   - Token Authorization dari Supabase session via interceptor
///
/// Bug sebelumnya: menggunakan dotenv.env['API_BASE_URL'] yang tidak ada di .env,
/// sehingga fallback ke http://10.0.2.2:8080 (hanya jalan di emulator).
class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/users');

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
      final response = await _dio.get('/users/helpdesk');

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
      final response = await _dio.patch(
        '/users/$userId/status',
        data: {'is_active': isActive},
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

/// [FIXED v3.0.0] Menggunakan Dio dari dioProvider (bukan Dio() baru tanpa config).
/// Ini memastikan base URL dan token Authorization konsisten di seluruh aplikasi.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserRepository(dio);
});
