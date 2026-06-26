import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:uuid/uuid.dart';

class TicketRepository {
  final String baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<Map<String, String>> _getHeaders() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken ?? '';
    
    // DEBUG LOG
    print('--- [DEBUG TICKET_REPOSITORY] ---');
    print('Sending Token: $token');
    print('---------------------------------');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ===================================================================
  // TICKET CRUD
  // ===================================================================

  Future<List<TicketModel>> getTickets({int page = 1, int limit = 10, String? filterRole}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => TicketModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<TicketModel?> getTicketById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets/$id'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return TicketModel.fromJson(body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createTicket(TicketModel ticket) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: await _getHeaders(),
        body: jsonEncode(ticket.toJson()),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to create ticket: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while creating ticket: $e');
    }
  }

  Future<void> updateTicket(TicketModel ticket) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tickets/${ticket.id}'),
        headers: await _getHeaders(),
        body: jsonEncode(ticket.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update ticket: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while updating ticket: $e');
    }
  }

  /// [NEW v2.0.0] Hapus tiket (Admin only).
  /// Backend akan mengembalikan 403 jika role bukan admin.
  Future<void> deleteTicket(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tickets/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete ticket: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while deleting ticket: $e');
    }
  }

  // ===================================================================
  // ATTACHMENT (Supabase Storage — tidak berubah)
  // ===================================================================

  Future<String> uploadTicketAttachment(File file) async {
    final String fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
    try {
      await _supabaseClient.storage
          .from('ticket-attachments')
          .upload(fileName, file);

      final publicUrl = _supabaseClient.storage
          .from('ticket-attachments')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file to storage: $e');
    }
  }

  // ===================================================================
  // COMMENTS (NEW v2.0.0 — Endpoint dari Golang backend)
  // ===================================================================

  /// [NEW v2.0.0] Ambil semua komentar untuk sebuah tiket.
  Future<List<CommentModel>> getComments(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$ticketId/comments'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => CommentModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while loading comments: $e');
    }
  }

  /// [NEW v2.0.0] Tambah komentar pada tiket.
  Future<CommentModel> createComment(String ticketId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets/$ticketId/comments'),
        headers: await _getHeaders(),
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return CommentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create comment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error while creating comment: $e');
    }
  }

  // ===================================================================
  // HISTORY / TRACKING (NEW v2.0.0 — BR-005)
  // ===================================================================

  /// [NEW v2.0.0] Ambil riwayat aksi tiket untuk fitur Tracking.
  Future<List<TicketHistoryModel>> getTicketHistories(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$ticketId/histories'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((e) => TicketHistoryModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load histories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while loading histories: $e');
    }
  }

  // ===================================================================
  // DASHBOARD STATS (NEW v2.0.0)
  // ===================================================================

  /// [NEW v2.0.0] Ambil statistik tiket yang sudah di-filter RBAC oleh backend.
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return DashboardStatsModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while loading stats: $e');
    }
  }

  // ===================================================================
  // PROFILES (tidak berubah)
  // ===================================================================

  Future<List<Map<String, dynamic>>> getStaffByRole(String roleName) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id, full_name, role')
          .eq('role', roleName.toLowerCase());
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch staff from profiles: $e');
    }
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});
