import 'auth_service.dart';
import '../models/creator.dart';

class CreatorService {

  /// Fetch paginated list of creators with optional filters.
  static Future<CreatorPagination> fetchCreators({
    String? category,
    String? platform,
    String? search,
    String sort = 'newest',
    int page = 1,
    int perPage = 12,
  }) async {
    final params = <String, dynamic>{
      'sort': sort,
      'page': page,
      'per_page': perPage,
    };
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (platform != null && platform.isNotEmpty) params['platform'] = platform;
    if (search != null && search.isNotEmpty) params['search'] = search;

    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/creators', queryParameters: params);

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        return CreatorPagination(
          creators: data.map((c) => Creator.fromJson(c)).toList(),
          currentPage: json['current_page'] ?? 1,
          lastPage: json['last_page'] ?? 1,
          total: json['total'] ?? 0,
        );
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load creators: $e');
    }
  }

  /// Fetch full detail of a single creator by slug.
  static Future<Creator> fetchCreatorDetail(String slug) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/creators/$slug');

      if (response.statusCode == 200) {
        return Creator.fromJson(response.data);
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load creator: $e');
    }
  }

  /// Fetch filter options (categories, platforms, genders, languages).
  static Future<CreatorFilters> fetchFilters() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/creators/options/filters');

      if (response.statusCode == 200) {
        return CreatorFilters.fromJson(response.data);
      }
      return const CreatorFilters();
    } catch (_) {
      return const CreatorFilters();
    }
  }
}
