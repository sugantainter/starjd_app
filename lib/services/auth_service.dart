import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env/env.dart';

class AuthService {
  static String get baseUrl {
    return Env.apiUrl;
  }

  static late Dio _dio;
  static late PersistCookieJar _cookieJar;
  static bool _initialized = false;

  /// Must be called early in main.dart or lazily upon first use
  static Future<void> init() async {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(
      storage: FileStorage("$appDocPath/.cookies/"),
      ignoreExpires: true,
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
    _initialized = true;
  }

  static Future<Dio> get client async {
    if (!_initialized) await init();
    return _dio;
  }

  static Future<Map<String, String>> getHeaders() async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (!_initialized) await init();
    
    // Attempt to manually fetch cookies for anything still using http or webviews
    List<Cookie> cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    if (cookies.isNotEmpty) {
      headers['cookie'] = cookies.map((c) => '${c.name}=${c.value}').join('; ');
    }
    return headers;
  }

  static String _parseError(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('errors')) {
        final errors = body['errors'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
           final firstKey = errors.keys.first;
           return errors[firstKey][0].toString();
        }
      }
      return body['message'] ?? 'An unknown error occurred';
    }
    return 'An unknown error occurred: $body';
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final c = await client;
      final response = await c.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );

      final responseBody = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (responseBody['user'] != null) {
          await prefs.setString('user', jsonEncode(responseBody['user']));
        }
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': _parseError(responseBody)};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unknown error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final c = await client;
      final response = await c.post(
        '/api/mobile-register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final responseBody = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': _parseError(responseBody)};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unknown error: $e'};
    }
  }

  static Future<Map<String, dynamic>> socialLogin(String provider, String token) async {
    try {
      final c = await client;
      final response = await c.post(
        '/api/auth/$provider/token',
        data: {'token': token},
      );

      final responseBody = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (responseBody['user'] != null) {
          await prefs.setString('user', jsonEncode(responseBody['user']));
        }
        return {'success': true, 'data': responseBody};
      } else {
        return {'success': false, 'message': _parseError(responseBody)};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Unknown error: $e'};
    }
  }

  static Future<bool> checkAuthStatus() async {
    try {
      final c = await client;
      final response = await c.get('/api/me');
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(response.data));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      final c = await client;
      await updateFcmToken(null);
      await c.post('/api/logout');
      if (_initialized) {
          await _cookieJar.deleteAll();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('role_selected'); // Reset so next user must pick role
    } catch (e) {
      // removed debugPrint
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final c = await client;
      final response = await c.post('/api/change-password', data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': _parseError(response.data)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final c = await client;
      final response = await c.delete('/api/account');
      if (response.statusCode == 200) {
        if (_initialized) {
            await _cookieJar.deleteAll();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user');
        await prefs.remove('role_selected');
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': _parseError(response.data)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCreatorProfile(Map<String, dynamic> data) async {
    try {
      final c = await client;
      
      dynamic requestData;
      if (data.containsKey('avatar_file') && data['avatar_file'] is File) {
        final File file = data['avatar_file'];
        final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(data);
        formDataMap.remove('avatar_file');
        
        final fileName = file.path.split('/').last;
        formDataMap['avatar'] = await MultipartFile.fromFile(file.path, filename: fileName);
        requestData = FormData.fromMap(formDataMap);
      } else {
        requestData = data;
      }

      final response = await c.post('/api/creator/onboarding', data: requestData);
      final body = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _parseError(body)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateBrandProfile(Map<String, dynamic> data) async {
    try {
      final c = await client;
      
      dynamic requestData;
      if (data.containsKey('logo_file') && data['logo_file'] is File) {
        final File file = data['logo_file'];
        final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(data);
        formDataMap.remove('logo_file');
        
        final fileName = file.path.split('/').last;
        formDataMap['logo'] = await MultipartFile.fromFile(file.path, filename: fileName);
        requestData = FormData.fromMap(formDataMap);
      } else {
        requestData = data;
      }

      final response = await c.post('/api/brand/onboarding', data: requestData);
      final body = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _parseError(body)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final c = await client;
      
      dynamic requestData;
      if (data.containsKey('avatar_file') && data['avatar_file'] is File) {
        final File file = data['avatar_file'];
        final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(data);
        formDataMap.remove('avatar_file');
        
        final fileName = file.path.split('/').last;
        formDataMap['avatar'] = await MultipartFile.fromFile(file.path, filename: fileName);
        requestData = FormData.fromMap(formDataMap);
      } else {
        requestData = data;
      }

      final response = await c.post('/api/update-profile', data: requestData);
      final body = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (body['user'] != null) {
          await prefs.setString('user', jsonEncode(body['user']));
        }
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _parseError(body)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Set the user's primary role after social/new registration
  static Future<Map<String, dynamic>> setRole(String role) async {
    try {
      final c = await client;
      final response = await c.post('/api/set-role', data: {'role': role});
      final body = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update stored user data with new role
        final prefs = await SharedPreferences.getInstance();
        if (body['user'] != null) {
          await prefs.setString('user', jsonEncode(body['user']));
        }
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _parseError(body)};
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'message': _parseError(e.response?.data)};
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // --- Support Tickets ---

  static Future<Map<String, dynamic>> getTickets() async {
    try {
      final c = await client;
      final response = await c.get('/api/support/tickets');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch tickets'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> raiseTicket(String subject, String message, String priority) async {
    try {
      final c = await client;
      final response = await c.post('/api/support/tickets', data: {
        'subject': subject,
        'message': message,
        'priority': priority,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': _parseError(response.data)};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTicketDetails(int ticketId) async {
    try {
      final c = await client;
      final response = await c.get('/api/support/tickets/$ticketId');
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch ticket details'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendTicketMessage(int ticketId, String message) async {
    try {
      final c = await client;
      final response = await c.post('/api/support/tickets/$ticketId/messages', data: {
        'message': message,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': _parseError(response.data)};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<void> updateFcmToken(String? token) async {
    try {
      final c = await client;
      await c.post('/api/update-fcm-token', data: {'fcm_token': token});
    } catch (e) {
      // removed debugPrint
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  // --- Lookups ---
  static Future<List<dynamic>> getStates() async {
    try {
      final res = await (await client).get('/api/states');
      return res.data as List;
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getCities(int stateId) async {
    try {
      final res = await (await client).get('/api/cities', queryParameters: {'state_id': stateId});
      return res.data as List;
    } catch (e) {
      return [];
    }
  }
}

