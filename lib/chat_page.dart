// lib/chat_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

// صفحة المحادثة بالمعلمات الجديدة فقط
class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;

  const ChatPage({
    Key? key,
    required this.chatRoomId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientAvatar,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // متغيرات لتتبع الحالات
  bool _isOnline = false;
  bool _isTyping = false;
  bool _isRecipientTyping = false;
  bool _isLoadingImage = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markMessagesAsRead();
    _listenToRecipientStatus();
    _messageController.addListener(_handleTyping);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _resetTypingStatus();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else {
      _updateOnlineStatus(false);
    }
  }

  // تحديث حالة الاتصال
  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // وضع علامة على الرسائل كمقروءة
  Future<void> _markMessagesAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // تحديث عدد الرسائل غير المقروءة
    await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
      'unreadCount.${user.uid}': 0,
    });

    // تحديث حالة القراءة للرسائل
    final unreadMessages = await _firestore
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // الاستماع إلى حالة المستخدم الآخر
  void _listenToRecipientStatus() {
    _firestore
        .collection('users')
        .doc(widget.recipientId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _isOnline = snapshot.data()?['isOnline'] ?? false;
          _lastSeen = (snapshot.data()?['lastSeen'] as Timestamp?)?.toDate();
        });
      }
    });

    // الاستماع إلى حالة الكتابة
    _firestore
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final typing = snapshot.data()?['typing'] as Map<String, dynamic>?;
        if (typing != null) {
          final isRecipientTyping = typing[widget.recipientId] ?? false;
          setState(() {
            _isRecipientTyping = isRecipientTyping;
          });
        }
      }
    });
  }

  // التعامل مع حالة الكتابة
  void _handleTyping() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() => _isTyping = isCurrentlyTyping);
      _updateTypingStatus(isCurrentlyTyping);
    }
  }

  // تحديث حالة الكتابة
  Future<void> _updateTypingStatus(bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
      'typing.${user.uid}': isTyping,
    });
  }

  // إعادة ضبط حالة الكتابة عند مغادرة الدردشة
  void _resetTypingStatus() {
    _updateTypingStatus(false);
  }

  // إرسال رسالة نصية
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = FieldValue.serverTimestamp();

    // إضافة الرسالة إلى مجموعة الرسائل
    await _firestore
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': text,
      'imageUrl': '',
      'timestamp': timestamp,
      'type': 'text',
      'isRead': false,
    });

    // تحديث آخر رسالة في غرفة المحادثة
    await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'lastMessageType': 'text',
      'unreadCount.${widget.recipientId}': FieldValue.increment(1),
    });

    _messageController.clear();
    _scrollToBottom();
  }

  // اختيار وإرسال صورة
  Future<void> _pickAndSendImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _isLoadingImage = true);

      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final imageFile = File(pickedFile.path);
        final timestamp = FieldValue.serverTimestamp();

        // رفع الصورة إلى Firebase Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(widget.chatRoomId)
            .child(fileName);

        // تنفيذ الرفع
        final uploadTask = await storageRef.putFile(imageFile);
        final imageUrl = await uploadTask.ref.getDownloadURL();

        // إضافة الرسالة إلى مجموعة الرسائل
        await _firestore
            .collection('chat_rooms')
            .doc(widget.chatRoomId)
            .collection('messages')
            .add({
          'senderId': user.uid,
          'text': '',
          'imageUrl': imageUrl,
          'timestamp': timestamp,
          'type': 'image',
          'isRead': false,
        });

        // تحديث آخر رسالة في غرفة المحادثة
        await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
          'lastMessage': '📷 Photo',
          'lastMessageTime': timestamp,
          'lastMessageType': 'image',
          'unreadCount.${widget.recipientId}': FieldValue.increment(1),
        });

        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingImage = false);
        }
      }
    }
  }

  // تنسيق حالة الاتصال
  String _formatOnlineStatus() {
    if (_isOnline) {
      return 'Online';
    } else if (_lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(_lastSeen!);
      }
    }
    return 'Offline';
  }

  // التمرير إلى أسفل المحادثة
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.recipientAvatar.isNotEmpty
                  ? NetworkImage(widget.recipientAvatar)
                  : null,
              radius: 16,
              child: widget.recipientAvatar.isEmpty
                  ? Text(
                widget.recipientName[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isRecipientTyping ? 'Typing...' : _formatOnlineStatus(),
                    style: TextStyle(
                      color: _isRecipientTyping ? Colors.greenAccent : Colors.white70,
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
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // Handle call action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B3B98)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as read when viewing them
                _markMessagesAsRead();

                final messages = snapshot.data!.docs.map((doc) => Message.fromFirestore(doc)).toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser!.uid;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final time = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.recipientAvatar.isNotEmpty
                  ? NetworkImage(widget.recipientAvatar)
                  : null,
              child: widget.recipientAvatar.isEmpty
                  ? Text(
                widget.recipientName[0].toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              )
                  : null,
            ),

          if (!isMe) const SizedBox(width: 8),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: message.type == 'image'
                  ? const EdgeInsets.all(3)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF3B3B98) : Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == 'image' && message.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GestureDetector(
                        onTap: () {
                          // Show full image
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Image.network(message.imageUrl),
                            ),
                          );
                        },
                        child: Image.network(
                          message.imageUrl,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 200,
                              height: 150,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error_outline),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  if (message.text.isNotEmpty)
                    Padding(
                      padding: message.type == 'image'
                          ? const EdgeInsets.fromLTRB(13, 8, 13, 5)
                          : EdgeInsets.zero,
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),

          if (isMe)
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo),
              color: const Color(0xFF3B3B98),
              onPressed: _isLoadingImage ? null : _pickAndSendImage,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF3B3B98),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoadingImage
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send),
                color: Colors.white,
                onPressed: _isLoadingImage ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}