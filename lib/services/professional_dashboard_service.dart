import 'package:dio/dio.dart';
import 'auth_service.dart';

class ProfessionalDashboardService {
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final client = await AuthService.client;
      final response = await client.get('/api/professional/dashboard');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getListings() async {
    try {
      final client = await AuthService.client;
      final response = await client.get('/api/professional/listings');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final client = await AuthService.client;
      final response = await client.get('/api/professional/orders');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveListing(Map<String, dynamic> data) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/listings', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/profile', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
