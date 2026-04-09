import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import 'chat_screen.dart';
import '../widgets/starjd_loader.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Unread', 'Brands', 'Creators'];
  List<Map<String, dynamic>> _conversations = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startMessageListener();
  }

  void _startMessageListener() {
    _messageSubscription = NotificationService.onMessageReceived.listen((message) {
      final data = message.data;
      if (data['type'] == 'chat') {
        _handleIncomingMessage(data);
        Provider.of<ChatProvider>(context, listen: false).refreshCount();
      }
      Provider.of<NotificationProvider>(context, listen: false).refreshCount();
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final senderId = int.tryParse(data['sender_id'].toString());
    if (senderId == null) return;

    if (mounted) {
      setState(() {
        int existingIndex = _conversations.indexWhere((c) => c['id'] == senderId);
        
        if (existingIndex != -1) {
          // Update existing conversation
          final conv = Map<String, dynamic>.from(_conversations[existingIndex]);
          conv['lastMessage'] = data['body'] ?? 'New message';
          conv['time'] = 'Just now';
          
          if (NotificationService.currentChatId != senderId) {
            conv['unreadCount'] = (conv['unreadCount'] ?? 0) + 1;
          }

          _conversations.removeAt(existingIndex);
          _conversations.insert(0, conv);
        } else {
          _loadConversations();
        }
      });
    }
  }

  Future<void> _loadConversations() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await ChatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load messages')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredConversations {
    List<Map<String, dynamic>> filtered = _conversations;

    // Filter by type/category
    if (_selectedFilterIndex == 1) { // Unread
      filtered = filtered.where((c) => (c['unreadCount'] ?? 0) > 0).toList();
    } else if (_selectedFilterIndex == 2) { // Brands
      filtered = filtered.where((c) => c['isBrand'] == true).toList();
    } else if (_selectedFilterIndex == 3) { // Creators
      filtered = filtered.where((c) => c['isBrand'] != true).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = (c['name'] ?? "").toString().toLowerCase();
        final lastMsg = (c['lastMessage'] ?? "").toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) || 
               lastMsg.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const StarJDLoader();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final count = notificationProvider.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                   IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      Future.delayed(const Duration(seconds: 2), () => notificationProvider.refreshCount());
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.appBarTheme.backgroundColor ?? Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: Icon(Icons.clear, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _filters.asMap().entries.map((entry) {
                int idx = entry.key;
                String val = entry.value;
                bool isSelected = _selectedFilterIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(val),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilterIndex = idx;
                      });
                    },
                    selectedColor: const Color(0xFFE63946).withOpacity(0.1),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFE63946) : (isDark ? Colors.white30 : const Color(0xFF6B7280)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFE63946).withOpacity(0.5) : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const StarJDLoader()
                : _filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text(_searchQuery.isEmpty 
                              ? 'No messages yet' 
                              : 'No matching messages found', 
                              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredConversations.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                        itemBuilder: (context, index) {
                          final msg = _filteredConversations[index];
                          final unreadCount = msg['unreadCount'] ?? 0;
                          final avatarUrl = msg['avatar']?.toString() ?? '';
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          avatarUrl.startsWith('http') 
                                            ? avatarUrl 
                                            : 'https://www.starjd.com$avatarUrl'
                                        )
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? Icon(Icons.person, size: 28, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))
                                      : null,
                                ),
                                if (msg['isOnline'] == true)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isDark ? theme.scaffoldBackgroundColor : Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          msg['name'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 15,
                                            color: theme.textTheme.titleMedium?.color,
                                          ),
                                        ),
                                      ),
                                      if (msg['isBrand'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 14),
                                      ]
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  msg['time'],
                                  style: TextStyle(
                                    color: unreadCount > 0 ? const Color(0xFFE63946) : (isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                                    fontSize: 11,
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                msg['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unreadCount > 0 ? theme.textTheme.bodyLarge?.color : (isDark ? Colors.white30 : const Color(0xFF6B7280)),
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            trailing: unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE63946),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(contact: Map<String, dynamic>.from(msg)),
                                ),
                              );
                              if (updated == true) _loadConversations();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
