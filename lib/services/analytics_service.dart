import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  static Future<void> initialize() async {
    try {
      // Set options if needed
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      await _facebookAppEvents.setAdvertiserTracking(enabled: true, collectId: true);
      
      debugPrint('Meta Analytics initialized successfully');
    } catch (e) {
      debugPrint('Meta Analytics initialization failed: $e');
    }
  }

  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Logged event: $name with parameters: $parameters');
    } catch (e) {
      debugPrint('Failed to log event $name: $e');
    }
  }

  static Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters,
      );
      debugPrint('Logged purchase: $amount $currency');
    } catch (e) {
      debugPrint('Failed to log purchase: $e');
    }
  }

  static Future<void> logActivateApp() async {
    try {
      await _facebookAppEvents.activateApp();
      debugPrint('Logged app activation');
    } catch (e) {
      debugPrint('Failed to log app activation: $e');
    }
  }
  
  static Future<void> setUserID(String id) async {
    try {
      await _facebookAppEvents.setUserID(id);
      debugPrint('Set User ID: $id');
    } catch (e) {
      debugPrint('Failed to set User ID: $e');
    }
  }
}
