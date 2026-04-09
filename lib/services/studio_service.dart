import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';
import '../models/studio.dart';

class StudioService {
  static String get _base => Env.apiUrl;

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Fetch paginated list of studios with optional filters.
  /// [category] — category slug (e.g. 'photography')
  /// [search]   — city/name keyword
  /// [sort]     — 'newest' | 'price_low' | 'price_high' | 'rating'
  /// [page]     — page number (1-indexed)
  /// [perPage]  — items per page (max 24)
  static Future<StudioPagination> fetchStudios({
    String? category,
    String? search,
    String sort = 'newest',
    int page = 1,
    int perPage = 12,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'page': '$page',
      'per_page': '$perPage',
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['city'] = search;

    final uri = Uri.parse('$_base/api/studios').replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        return StudioPagination(
          studios: data.map((s) => Studio.fromJson(s)).toList(),
          currentPage: json['current_page'] ?? 1,
          lastPage: json['last_page'] ?? 1,
          total: json['total'] ?? 0,
          perPage: json['per_page'] ?? perPage,
        );
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load studios: $e');
    }
  }

  /// Fetch full detail of a single studio by id or slug.
  static Future<Studio> fetchStudioDetail(String slugOrId) async {
    final uri = Uri.parse('$_base/api/studios/$slugOrId');

    try {
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Studio.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Studio not found');
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load studio detail: $e');
    }
  }

  /// Fetch list of studio categories for filter chips.
  static Future<List<StudioCategory>> fetchCategories() async {
    final uri = Uri.parse('$_base/api/studios/categories');

    try {
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((c) => StudioCategory.fromJson(c)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
