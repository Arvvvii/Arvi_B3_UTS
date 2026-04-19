import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';
import 'package:uuid/uuid.dart';

class TicketRepository {
  final String baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<Map<String, String>> _getHeaders() async {
    final session = _supabaseClient.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});
