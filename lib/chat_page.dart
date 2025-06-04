// lib/chat_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'text',
      isRead: data['isRead'] ?? false,
    );
  }
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
    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);

    await chatRoomRef.update({
      'unreadCount.$userId': 0,
    });
  }

  void _updateOnlineStatus(bool isOnline) {
    FirebaseFirestore.instance.collection('user_status').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _listenToOnlineStatus() {
    FirebaseFirestore.instance
        .collection('user_status')
        .doc(widget.recipientId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _isOnline = data['isOnline'] ?? false;
          _lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        });
      }
    });
  }

  void _listenToTyping() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final typingData = data['typing'] as Map<String, dynamic>? ?? {};
        final otherUserTyping = typingData[widget.recipientId] ?? false;

        if (_isTyping != otherUserTyping) {
          setState(() {
            _isTyping = otherUserTyping;
          });
        }
      }
    });
  }

  void _updateTypingStatus(bool isTyping) {
    FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).update({
      'typing.$userId': isTyping,
    });
  }

  Future<void> _sendMessage({String? text, String? imageUrl, String type = 'text'}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null) return;

    _messageController.clear();
    _updateTypingStatus(false);

    final messageData = {
      'senderId': userId,
      'text': messageText,
      'imageUrl': imageUrl ?? '',
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'chatId': widget.chatRoomId,
      'isRead': false,
    };

    // Add message to subcollection
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update chat room info
    await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).update({
      'lastMessage': type == 'text' ? messageText : '📷 Photo',
      'lastMessageType': type,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.${widget.recipientId}': FieldValue.increment(1),
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

      setState(() => _isLoadingImage = true);

    try {
      // Upload image to Firebase Storage
      final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(widget.chatRoomId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(file);
        final imageUrl = await uploadTask.ref.getDownloadURL();

      // Send message with image
      await _sendMessage(imageUrl: imageUrl, type: 'image');

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
    final l10n = AppLocalizations.of(context)!;
    if (_isOnline) {
      return l10n.online;
    } else if (_lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSeen!);

      if (difference.inMinutes < 1) {
        return l10n.justNow;
      } else if (difference.inHours < 1) {
        return l10n.minutesAgo(difference.inMinutes);
      } else if (difference.inDays < 1) {
        return l10n.hoursAgo(difference.inHours);
      } else {
        return DateFormat('MMM d').format(_lastSeen!);
      }
    }
    return l10n.offline;
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isMe) {
    final time = (msg['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = time != null ? DateFormat.jm().format(time) : '';
    final messageType = msg['type'] ?? 'text';

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 50 : 10,
        right: isMe ? 10 : 50,
        top: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryBlue : AppTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 5),
                bottomRight: Radius.circular(isMe ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.withOpacity(AppTheme.black, 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (messageType == 'image' && msg['imageUrl'] != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            children: [
                              Center(
                                child: Image.network(
                                  msg['imageUrl'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 40,
                                right: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: AppTheme.white, size: 30),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          msg['imageUrl'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 100,
                              width: 100,
                              color: AppTheme.borderGrey,
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              width: 100,
                              color: AppTheme.borderGrey,
                              child: const Icon(Icons.error_outline, color: AppTheme.mediumGrey),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: messageType == 'image' ? 8 : 0),
                    child: SelectableText(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? AppTheme.white : AppTheme.darkGrey,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 8,
              right: isMe ? 8 : 0,
              top: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg['isRead'] == true ? Icons.done_all : Icons.done,
                    size: 16,
                    color: msg['isRead'] == true ? AppTheme.primaryBlue : AppTheme.mediumGrey,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
          children: [
            CircleAvatar(
                  radius: 20,
              backgroundColor: AppTheme.borderGrey,
              backgroundImage: widget.recipientAvatar.isNotEmpty
                  ? NetworkImage(widget.recipientAvatar)
                  : null,
              child: widget.recipientAvatar.isEmpty
                  ? Text(
                    widget.recipientName.isNotEmpty
                        ? widget.recipientName[0].toUpperCase()
                        : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              )
                  : null,
            ),
                if (_isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.white, width: 2),
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
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isTyping ? l10n.typing : _getOnlineStatus(),
                    style: TextStyle(
                      color: _isTyping ? AppTheme.success : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.callFeatureComingSoon),
                  backgroundColor: AppTheme.primaryBlue,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.white),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.error}: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.error),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.mediumGrey.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMessagesYet,
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppTheme.mediumGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.sendMessageToStart,
                          style: TextStyle(
                            color: AppTheme.mediumGrey.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == userId;

                    return _buildMessage(msg, isMe);
                  },
                );
              },
            ),
          ),
          Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: AppTheme.withOpacity(AppTheme.black, 0.1),
          ),
        ],
      ),
      child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
                      icon: const Icon(Icons.photo, color: AppTheme.primaryBlue),
                      onPressed: _isLoadingImage ? null : _sendImage,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                          focusNode: _textFieldFocus,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: l10n.typeAMessage,
                    hintStyle: const TextStyle(color: AppTheme.mediumGrey),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                    border: InputBorder.none,
                          ),
                          onChanged: (text) {
                            final isCurrentlyTyping = text.isNotEmpty;
                            if (isCurrentlyTyping != _isTyping) {
                              _updateTypingStatus(isCurrentlyTyping);
                            }
                          },
                          onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoadingImage
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white,
                  ),
                )
                    : const Icon(Icons.send),
                color: theme.primaryColor,
                        onPressed: _isLoadingImage ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}