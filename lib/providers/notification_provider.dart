import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  Timer? _timer;

  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _startPolling();
  }

  void _startPolling() {
    refreshCount();
    // Refresh every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      refreshCount();
    });
  }

  Future<void> refreshCount() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/notifications/unread-count');
      if (response.statusCode == 200) {
        final count = response.data['count'] ?? 0;
        if (_unreadCount != count) {
          _unreadCount = count;
          notifyListeners();
        }
      }
    } catch (_) {
      // Silently fail, could be offline or unauthenticated
    }
  }

  void markLocallyAsRead(int count) {
    if (_unreadCount > 0) {
      _unreadCount = (_unreadCount - count).clamp(0, 999);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
