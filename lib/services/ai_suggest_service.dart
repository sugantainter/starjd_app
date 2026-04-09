import 'package:dio/dio.dart';
import 'auth_service.dart';

class AISuggestService {
  static Future<Map<String, dynamic>> suggestGeneric(String type, Map<String, dynamic> context) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/ai-suggest/generic', data: {
        'type': type,
        'context': context,
      });
      return {'success': true, 'suggestion': cleanAiResponse(response.data['suggestion'].toString())};
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return {'success': false, 'message': 'Daily AI limit reached. Please try again tomorrow.', 'is_limit': true};
      }
      return {'success': false, 'message': e.message ?? 'Failed to get suggestion'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> suggestTitle(int serviceId) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/ai/suggest-title', data: {'service_id': serviceId});
      return {'success': true, 'suggestions': response.data['suggestions']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> suggestDescription(int serviceId, String? title) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/ai/suggest-description', data: {
        'service_id': serviceId,
        'title': title,
      });
      return {'success': true, 'description': cleanAiResponse(response.data['description'].toString())};
    } catch (e) {

      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> suggestTags(int serviceId) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/ai/suggest-tags', data: {'service_id': serviceId});
      return {'success': true, 'tags': response.data['tags']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> suggestPricing(int serviceId) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/ai/suggest-pricing', data: {'service_id': serviceId});
      return {'success': true, 'pricing': response.data['pricing']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> suggestFAQs(int serviceId) async {
    try {
      final client = await AuthService.client;
      final response = await client.post('/api/professional/ai/suggest-faqs', data: {'service_id': serviceId});
      return {'success': true, 'faqs': response.data['faqs']};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Stability Feature: Cleans AI response by stripping markdown code blocks.
  static String cleanAiResponse(String text) {
    // Remove markdown code blocks if present
    final regExp = RegExp(r'^```(?:json)?\n?|\n?```$', multiLine: true);
    return text.replaceAll(regExp, '').trim();
  }
}
