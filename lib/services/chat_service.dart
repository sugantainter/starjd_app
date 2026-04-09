import 'package:dio/dio.dart';
import 'auth_service.dart';

class ChatService {
  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/conversations');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getMessages(int userId) async {
    try {
      final c = await AuthService.client;
      final response = await c.get('/api/messages/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage(int receiverId, String body) async {
    try {
      final c = await AuthService.client;
      final response = await c.post('/api/messages', data: {
        'receiver_id': receiverId,
        'body': body,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    }
    throw Exception('Failed to send message');
  }
}
