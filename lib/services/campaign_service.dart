import 'package:dio/dio.dart';
import 'dart:convert';
import 'auth_service.dart';

class CampaignPagination {
  final List<dynamic> campaigns;
  final int currentPage;
  final int lastPage;
  final int total;

  CampaignPagination({
    required this.campaigns,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class CampaignService {
  static Future<CampaignPagination> fetchCampaigns({
    String? type,
    String? search,
    int page = 1,
    int perPage = 12,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (type != null && type.isNotEmpty) params['campaign_type'] = type;
    if (search != null && search.isNotEmpty) params['q'] = search;

    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/campaigns', queryParameters: params);

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        return CampaignPagination(
          campaigns: data,
          currentPage: json['current_page'] ?? 1,
          lastPage: json['last_page'] ?? 1,
          total: json['total'] ?? 0,
        );
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load campaigns: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchCampaignDetail(String slug) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/campaigns/$slug');
      if (response.statusCode == 200) {
        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data);
        } else if (response.data is String) {
          try {
            return Map<String, dynamic>.from(jsonDecode(response.data));
          } catch (_) {
             throw Exception('Invalid server response format');
          }
        }
        throw Exception('Unexpected response type: ${response.data.runtimeType}');
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load campaign: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchFilters() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/campaigns/filters');
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> applyToCampaign({
    required int campaignId,
    String? coverMessage,
    double? quotedAmount,
  }) async {
    try {
      final dio = await AuthService.client;
      final response = await dio.post('/api/creator/campaign-applications', data: {
        'campaign_id': campaignId,
        'cover_message': coverMessage,
        'quoted_amount': quotedAmount,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      String message = 'Failed to apply';
      if (e is DioException && e.response?.data != null) {
        message = e.response!.data['message'] ?? message;
      }
      return {'success': false, 'message': message};
    }
  }
}
