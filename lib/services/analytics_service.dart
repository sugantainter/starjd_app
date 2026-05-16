import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

class AnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  static Future<void> initialize() async {
    try {
      bool trackingEnabled = true;
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        trackingEnabled = (status == TrackingStatus.authorized);
      }

      // Set options
      await _facebookAppEvents.setAutoLogAppEventsEnabled(trackingEnabled);
      await _facebookAppEvents.setAdvertiserTracking(enabled: trackingEnabled, collectId: trackingEnabled);
      
      // removed debugPrint
    } catch (e) {
      // removed debugPrint
    }
  }

  static Future<void> requestATT() async {
    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // Wait for a moment to ensure the app is ready to show the dialog
          await Future.delayed(const Duration(milliseconds: 500));
          await AppTrackingTransparency.requestTrackingAuthorization();
          // Re-initialize to apply the new tracking status
          await initialize();
        }
      }
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
