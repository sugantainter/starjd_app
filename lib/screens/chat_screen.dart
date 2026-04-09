import 'package:flutter/material.dart';
import 'dart:async';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    NotificationService.currentChatId = widget.contact['id'];
    _loadMessages();
    _startRealtimeListener();
  }

  void _startRealtimeListener() {
    _messageSubscription = NotificationService.onMessageReceived.listen((message) {
      final data = message.data;
      if (data['type'] == 'chat' && 
          data['sender_id'].toString() == widget.contact['id'].toString()) {
        
        // Append message to history
        setState(() {
          _chatHistory.add({
            'isMe': false,
            'text': data['body'] ?? message.notification?.body ?? '',
            'time': _formatCurrentTime(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ChatService.getMessages(widget.contact['id']);
      setState(() {
        _chatHistory = data;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    NotificationService.currentChatId = null;
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final newMessage = await ChatService.sendMessage(widget.contact['id'], text);
      setState(() {
        _chatHistory.add(newMessage);
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  ImageProvider? _getContactAvatar() {
    final avatar = widget.contact['avatar'];
    if (avatar != null && avatar.toString().startsWith('http')) {
      return NetworkImage(avatar.toString());
    }
    return null;
  }

  bool get _isContactOnline => widget.contact['isOnline'] == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAF9),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                  backgroundImage: _getContactAvatar(),
                  child: _getContactAvatar() == null 
                      ? Icon(Icons.person, size: 20, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)) 
                      : null,
                ),
                if (_isContactOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.contact['name'] ?? 'User',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.contact['isBrand'] == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ]
                    ],
                  ),
                  Text(
                    _isContactOnline ? 'Active now' : 'Last seen recently',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isContactOnline ? const Color(0xFF10B981) : (isDark ? Colors.white30 : const Color(0xFF6B7280)),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
                : _chatHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          final message = _chatHistory[index];
                          final bool isMe = message['isMe'] == true;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                    backgroundImage: _getContactAvatar(),
                                    child: _getContactAvatar() == null 
                                        ?   Icon(Icons.person, size: 14, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)) 
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isMe ? theme.primaryColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                                        bottomRight: Radius.circular(isMe ? 4 : 20),
                                      ),
                                      border: isMe ? null : Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['text'] ?? '',
                                          style: TextStyle(
                                            color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                                            fontSize: 15,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message['time'] ?? '',
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : (isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isMe) const SizedBox(width: 4),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Chat Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
