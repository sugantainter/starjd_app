import 'dart:convert';
import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/professional_gig.dart';

class ProfessionalService {
  /// Fetch paginated list of marketplace gigs.
  static Future<ProfessionalGigPagination> fetchMarketplaceGigs({
    int? serviceId,
    String? category,
    String? search,
    String sort = 'newest',
    int page = 1,
  }) async {
    final params = <String, dynamic>{
      'sort': sort,
      'page': page,
    };
    if (serviceId != null) params['service_id'] = serviceId;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/gigs', queryParameters: params);

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        final dynamic rawJson;
        try {
          rawJson = rawData is String ? jsonDecode(rawData) : rawData;
        } catch (e) {
          throw Exception('The server returned an invalid response. Please verify the Marketplace API.');
        }

        // Support various pagination formats
        List<dynamic> gigsRaw = [];
        int currentPage = 1;
        int lastPage = 1;
        int total = 0;

        if (rawJson is List) {
          gigsRaw = rawJson;
          total = rawJson.length;
        } else if (rawJson is Map<String, dynamic>) {
          final dynamic dataField = rawJson['data'];
          if (dataField is List) {
            gigsRaw = dataField;
            currentPage = rawJson['current_page'] ?? 1;
            lastPage = rawJson['last_page'] ?? 1;
            total = rawJson['total'] ?? 0;
          } else if (dataField is Map) {
            gigsRaw = dataField['data'] is List ? dataField['data'] : [];
            currentPage = dataField['current_page'] ?? 1;
            lastPage = dataField['last_page'] ?? 1;
            total = dataField['total'] ?? 0;
          }
        }

        return ProfessionalGigPagination(
          gigs: gigsRaw.map((c) => ProfessionalGig.fromJson(c)).toList(),
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
        );
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load marketplace: $e');
    }
  }

  /// Fetch filter options (services) for the marketplace.
  static Future<List<Map<String, dynamic>>> fetchMarketplaceFilters() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/services');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List<dynamic> data = rawData is String ? jsonDecode(rawData) : rawData;
        return data.map((e) => Map<String, dynamic>.from(e)).toList().cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch single professional gig details by slug.
  static Future<Map<String, dynamic>> fetchGigDetail(String slug) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/gigs/$slug');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        return rawData is String ? jsonDecode(rawData) : rawData;
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load gig details: $e');
    }
  }
  /// Get Professional Dashboard Stats
  static Future<Map<String, dynamic>> getProfessionalDashboard() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/professional/dashboard');
      if (response.statusCode == 200) {
        final data = response.data;
        return data is String ? jsonDecode(data) : data;
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  /// Get Current User's Professional Listings
  static Future<List<dynamic>> getProfessionalListings() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/professional/listings');
      if (response.statusCode == 200) {
        final data = response.data;
        return data is String ? jsonDecode(data) : data;
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load listings: $e');
    }
  }

  /// Save or Update a Professional Listing
  static Future<Map<String, dynamic>> saveProfessionalListing(Map<String, dynamic> data) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/listings', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        return resData is String ? jsonDecode(resData) : resData;
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to save listing: $e');
    }
  }

  /// Upload Gig Gallery Image
  static Future<String> uploadGigImage(String filePath) async {
    try {
      final dio = await AuthService.client;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      final response = await dio.post(
        '/api/professional/upload-image',
        data: formData,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final resData = data is String ? jsonDecode(data) : data;
        return resData['url'] as String;
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// AI Suggest Title
  static Future<List<String>> suggestTitleAI(String serviceId) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/ai/suggest-title', data: {'service_id': serviceId});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return List<String>.from(data['suggestions'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// AI Generate Description
  static Future<String> suggestDescriptionAI(String serviceId, String title) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/ai/suggest-description', data: {
        'service_id': serviceId,
        'title': title,
      });
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return data['description']?.toString() ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// AI Suggest Search Tags
  static Future<List<String>> suggestTagsAI(String serviceId) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/ai/suggest-tags', data: {'service_id': serviceId});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return List<String>.from(data['tags'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// AI Suggest Pricing
  static Future<Map<String, dynamic>> suggestPricingAI(String serviceId) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/ai/suggest-pricing', data: {'service_id': serviceId});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return data['pricing'] ?? {};
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// AI Suggest FAQs
  static Future<List<Map<String, dynamic>>> suggestFAQsAI(String serviceId) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/professional/ai/suggest-faqs', data: {'service_id': serviceId});
      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return List<Map<String, dynamic>>.from(data['faqs'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
