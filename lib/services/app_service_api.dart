import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';
import '../models/app_service.dart';

class AppServiceApi {
  static String get _base => Env.apiUrl;

  static const Map<String, String> _h = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<List<AppService>> fetchServices() async {
    final uri = Uri.parse('$_base/api/services');
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((s) => AppService.fromJson(s)).toList();
    }
    throw Exception('Failed to load services: ${res.statusCode}');
  }

  static Future<AppServiceDetail> fetchService(String slug) async {
    final uri = Uri.parse('$_base/api/services/$slug');
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return AppServiceDetail.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 404) throw Exception('Service not found');
    throw Exception('Failed to load service: ${res.statusCode}');
  }
}
