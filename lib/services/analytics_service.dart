import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  static Future<void> initialize() async {
    try {
      // Set options if needed
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      await _facebookAppEvents.setAdvertiserTracking(enabled: true, collectId: true);
      
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
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
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
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
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
    }
  }

  static Future<void> logActivateApp() async {
    try {
      await _facebookAppEvents.activateApp();
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
    }
  }
  
  static Future<void> setUserID(String id) async {
    try {
      await _facebookAppEvents.setUserID(id);
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
    }
  }
}
