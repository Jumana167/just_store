// lib/chat_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'models/chat_message.dart';
import 'services/chat_service.dart';
import 'package:firebase_database/firebase_database.dart';

// تعريف نموذج Message للاستخدام الداخلي
class Message {
  final String? id;
  final String senderId;
  final String text;
  final String imageUrl;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });
}

// صفحة المحادثة
class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final _chatService = ChatService();

  bool _isOnline = false;
  DateTime? _lastSeen;
  bool _isTyping = false;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markMessagesAsRead();
    _updateOnlineStatus(true);
    _listenToTyping();
    _listenToOnlineStatus();
  }

  @override
  void dispose() {
    _updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _updateOnlineStatus(false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.chatRoomId);
  }

  void _updateOnlineStatus(bool isOnline) {
    // حذف استخدام FirebaseDatabase هنا
  }

  void _listenToOnlineStatus() {
    // حذف استخدام FirebaseDatabase هنا
  }

  void _listenToTyping() {
    // حذف استخدام FirebaseDatabase هنا
  }

  void _updateTypingStatus(bool isTyping) {
    // حذف استخدام FirebaseDatabase هنا
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null) return;

    _messageController.clear();
    _updateTypingStatus(false);

    if (imageUrl != null) {
      await _chatService.sendImageMessage(
        widget.chatRoomId,
        imageUrl,
        widget.recipientId,
      );
    } else {
      await _chatService.sendTextMessage(
        widget.chatRoomId,
        messageText,
        widget.recipientId,
      );
    }

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => _isLoadingImage = true);

    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.chatRoomId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(file);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSendImage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getOnlineStatus() {
    if (_isOnline) {
      return 'Online';
    } else if (_lastSeen != null) {
      return 'Last seen ${DateFormat.jm().format(_lastSeen!)}';
    }
    return 'Offline';
  }

  // دالة لجلب اسم المستخدم من Realtime Database
  Future<String> getUserName(String userId) async {
    final snapshot = await FirebaseDatabase.instance.ref('users/$userId/name').get();
    if (snapshot.exists) {
      return snapshot.value as String;
    }
    return userId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.recipientAvatar.isNotEmpty
                  ? NetworkImage(widget.recipientAvatar)
                  : null,
              child: widget.recipientAvatar.isEmpty
                  ? Text(widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : '?')
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: getUserName(widget.recipientId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(width: 80, height: 16, child: LinearProgressIndicator());
                    }
                    return Text(snapshot.data ?? widget.recipientName);
                  },
                ),
                Text(
                  _getOnlineStatus(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatMessages(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorLoadingMessages));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryBlue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  message.imageUrl!,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            Text(
                              DateFormat.jm().format(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${widget.recipientName} is typing...',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _isLoadingImage ? null : _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _textFieldFocus,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (text) {
                      _updateTypingStatus(text.isNotEmpty);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}