import 'dart:io';
import 'package:dio/dio.dart';
import '../models/collaboration.dart';
import 'auth_service.dart';

class CollaborationService {
  static Future<List<Collaboration>> getCollaborations() async {
    try {
      final client = await AuthService.client;
      final response = await client.get('/api/collaborations');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => Collaboration.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching collaborations: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCollaboration(Map<String, dynamic> data) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> acceptCollaboration(int id) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/accept');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> rejectCollaboration(int id) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/reject');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> submitDeliverable(int id, File file, Function(double) onProgress) async {
    try {
      final client = await AuthService.client;
      // Use longer timeouts for large file uploads as per the 128M limit
      client.options.connectTimeout = const Duration(minutes: 5);
      client.options.receiveTimeout = const Duration(minutes: 5);
      client.options.sendTimeout = const Duration(minutes: 10);

      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'deliverable_file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      
      final response = await client.post(
        '/api/collaborations/$id/deliver', 
        data: formData,
        onSendProgress: (sent, total) {
          onProgress(sent / total);
        }
      );
      return {'success': true, 'data': response.data};
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 413) {
        return {'success': false, 'message': 'File too large. Limits are 128MB.'};
      }
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> getFilePreview(int id, {String? intent}) async {
    try {
      final client = await AuthService.client;
      final response = await client.get(
        '/api/collaborations/$id/file',
        queryParameters: intent != null ? {'intent': intent} : null,
      );
      // Backend returns metadata including preview_token and a relative stream URL
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> completeCollaboration(int id) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/complete');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> requestRevision(int id, String notes) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/revision', data: {'notes': notes});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> rejectDelivery(int id, String reason, String notes) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/reject-delivery', data: {
        'reason': reason,
        'notes': notes,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> claimSettlement(int id, String type, int bankAccountId) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/collaborations/$id/claim-settlement', data: {
        'type': type,
        'bank_account_id': bankAccountId,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<List<BankAccount>> getBankAccounts() async {
    try {
      final client = await AuthService.client;
      final response = await client.get('/api/bank-accounts');
      if (response.statusCode == 200) {
        return (response.data as List).map((x) => BankAccount.fromJson(x)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bank accounts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addBankAccount(Map<String, dynamic> data) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/bank-accounts', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> deleteBankAccount(int id) async {
    try {
      final client = await AuthService.client;
      await client.delete('/api/bank-accounts/$id');
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static Future<Map<String, dynamic>> downloadFile(String url, String savePath, Function(double) onProgress) async {
    try {
      final client = await AuthService.client;
      await client.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': _parseError(e)};
    }
  }

  static String _parseError(dynamic e) {
    if (e is DioException) {
      return e.response?.data?['message'] ?? e.message ?? 'Unknown API error';
    }
    return e.toString();
  }
}
