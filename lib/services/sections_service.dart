import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';
import '../models/home_sections.dart';

class SectionsService {
  static String get _base => Env.apiUrl;

  static const Map<String, String> _h = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<HomeSections> fetchSections() async {
    final uri = Uri.parse('$_base/api/sections');
    try {
      final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return HomeSections.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return const HomeSections();
  }
}
