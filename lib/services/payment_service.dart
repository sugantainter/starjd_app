import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class PaymentService {
  static Future<List<dynamic>> getPlans() async {
    try {
      final c = await AuthService.client;
      final res = await c.get('/api/payment/plans');
      if (res.statusCode == 200) {
        return res.data;
      }
    } catch (e) {
      debugPrint('PaymentService getPlans Error: $e');
      throw Exception('Failed to load plans: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getAvailableCoupons(String applicableTo) async {
    try {
      final c = await AuthService.client;
      final res = await c.get('/api/coupons', queryParameters: {
        'applicable_to': applicableTo,
      });
      if (res.statusCode == 200) {
        return res.data;
      }
    } catch (e) {
      debugPrint('PaymentService getAvailableCoupons Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, double amount, String applicableTo) async {
    try {
      final c = await AuthService.client;
      final res = await c.get('/api/payment/coupon/validate', queryParameters: {
        'code': code,
        'amount': amount,
        'applicable_to': applicableTo,
      });
      if (res.statusCode == 200) {
        return {'valid': true, 'data': res.data['data']};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return {'valid': false, 'message': e.response?.data['message'] ?? 'Invalid coupon'};
      }
    } catch (e) {
      // Ignore
    }
    return {'valid': false, 'message': 'Validation failed'};
  }

  static Future<Map<String, dynamic>> createPayUOrder({
    required String type,
    String? planId,
    int? collaborationId,
    int? bookingId,
    required double amount,
    String? couponCode,
  }) async {
    try {
      final c = await AuthService.client;
      final params = <String, dynamic>{
        'type': type,
        'amount': amount,
      };
      if (planId != null) params['plan_id'] = planId;
      if (collaborationId != null) params['collaboration_id'] = collaborationId;
      if (bookingId != null) params['booking_id'] = bookingId;
      if (couponCode != null && couponCode.isNotEmpty) {
        params['coupon_code'] = couponCode;
      }

      final res = await c.post('/api/payment/payu/create', data: params);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'data': res.data};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final err = e.response?.data['message'] ?? 'Payment generation error';
        return {'success': false, 'message': err};
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      // Ignore
    }
    return {'success': false, 'message': 'Unknown checkout error'};
  }
}
