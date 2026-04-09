import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class ChatProvider extends ChangeNotifier {
  int _unreadMessageCount = 0;
  Timer? _timer;

  int get unreadMessageCount => _unreadMessageCount;

  ChatProvider() {
    _startPolling();
  }

  void _startPolling() {
    refreshCount();
    _timer = Timer.periodic(const Duration(seconds: 45), (timer) {
      refreshCount();
    });
  }

  Future<void> refreshCount() async {
    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/messages/unread-count');
      if (response.statusCode == 200) {
        final count = response.data['count'] ?? 0;
        if (_unreadMessageCount != count) {
          _unreadMessageCount = count;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void setUnreadCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
