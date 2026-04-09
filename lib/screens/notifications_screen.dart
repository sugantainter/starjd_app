import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../widgets/starjd_loader.dart';
import 'chat_screen.dart';
import 'campaign_detail_screen.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoading) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _notifications = [];
        _hasMore = true;
      });
    }

    try {
      final dio = await AuthService.client;
      final response = await dio.get('/api/notifications', queryParameters: {'page': _currentPage});
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final lastPage = response.data['last_page'] ?? 1;
        
        setState(() {
          _notifications.addAll(data);
          _hasMore = _currentPage < lastPage;
          _isLoading = false;
          _currentPage++;
        });
      }
    } catch (e) {
      String errorMessage = "Failed to load notifications";
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? e.message ?? errorMessage;
      } else {
        errorMessage = e.toString();
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = await AuthService.client;
      await dio.post('/api/notifications/read-all');
      if (mounted) Provider.of<NotificationProvider>(context, listen: false).refreshCount();
      _loadNotifications(refresh: true);
    } catch (_) {}
  }

  Future<void> _markAsRead(String id) async {
    try {
      final dio = await AuthService.client;
      await dio.post('/api/notifications/$id/read');
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).refreshCount();
        setState(() {
          final idx = _notifications.indexWhere((element) => element['id'] == id);
          if (idx != -1) {
            _notifications[idx]['read_at'] = DateTime.now().toIso8601String();
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => n['read_at'] == null))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text('Mark all read', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const StarJDLoader()
          : _error != null && _notifications.isEmpty
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: () => _loadNotifications(refresh: true),
                      color: theme.primaryColor,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _notifications.length + (_hasMore ? 1 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          if (index == _notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final n = _notifications[index];
                          return _buildNotificationItem(n, isDark);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(dynamic n, bool isDark) {
    final bool isRead = n['read_at'] != null;
    final DateTime createdAt = DateTime.parse(n['created_at']);
    final String timeAgo = DateFormat.jm().format(createdAt.toLocal()); // Fallback formatting
    final String date = DateFormat.MMMd().format(createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isRead 
            ? (isDark ? Colors.white.withOpacity(0.02) : Colors.white)
            : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F7FF)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? (isDark ? Colors.white10 : Colors.grey.shade200) : const Color(0xFFE63946).withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          if (!isRead) _markAsRead(n['id']);
          _handleNotificationClick(n);
        },
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getIconColor(n['type']).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(n['type']), color: _getIconColor(n['type']), size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                n['title'] ?? 'Generic Notification',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              n['description'] ?? '',
              style: TextStyle(
                color: isRead ? Colors.grey.shade600 : Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$date, $timeAgo',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationClick(dynamic n) {
    final data = n['data'] ?? {};
    final type = n['type'];

    if (type == 'chat' && data['sender_id'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            contact: {
              'id': int.tryParse(data['sender_id'].toString()),
              'name': data['sender_name'] ?? 'User',
            },
          ),
        ),
      );
    } else if (type == 'campaign' && (data['campaign_id'] != null || data['slug'] != null)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CampaignDetailScreen(
            slug: (data['slug'] ?? data['campaign_id']).toString(),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 24),
          const Text('No Notifications Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('When you get notifications,\nthey will appear here.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'chat': return Icons.chat_bubble_outline;
      case 'campaign': return Icons.campaign_outlined;
      case 'payment': return Icons.payments_outlined;
      case 'marketing': return Icons.star_border;
      case 'alert': return Icons.error_outline;
      default: return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'chat': return Colors.blue;
      case 'campaign': return const Color(0xFFE63946);
      case 'payment': return Colors.green;
      case 'marketing': return Colors.purple;
      case 'alert': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
