// lib/services/chat_service.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_store_clean/models/chat_room.dart';
import 'package:just_store_clean/models/chat_message.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // الحصول على معرف المستخدم الحالي
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // إنشاء أو الحصول على غرفة دردشة
  Future<String> createOrGetChatRoom(String otherUserId) async {
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);
    final chatRoomRef = _database.ref().child('chats/$chatRoomId');

    // التحقق من وجود الغرفة
    final snapshot = await chatRoomRef.get();
    if (!snapshot.exists) {
      // إنشاء غرفة جديدة
      final newChatRoom = ChatRoom(
        id: chatRoomId,
        participants: {
          currentUserId: true,
          otherUserId: true,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await chatRoomRef.set(newChatRoom.toMap());
    }
    return chatRoomId;
  }

  // الحصول على قائمة غرف الدردشة
  Stream<List<ChatRoom>> getChatRooms() {
    final chatRoomsRef = _database.ref().child('chats');
    return chatRoomsRef.onValue.map((event) {
      if (event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .where((entry) {
            final participants = Map<String, bool>.from(entry.value['participants'] ?? {});
            return participants.containsKey(currentUserId);
          })
          .map((entry) => ChatRoom.fromMap(entry.value, entry.key))
          .toList()
        ..sort((a, b) => (b.lastMessageTime ?? DateTime(0))
            .compareTo(a.lastMessageTime ?? DateTime(0)));
    });
  }

  // الحصول على رسائل غرفة الدردشة
  Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    final messagesRef = _database.ref().child('chats/$chatRoomId/messages');
    return messagesRef.onValue.map((event) {
      if (event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) => ChatMessage.fromMap(entry.value, entry.key))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  // إرسال رسالة نصية
  Future<void> sendTextMessage(String chatRoomId, String text, String recipientId) async {
    final messageRef = _database.ref().child('chats/$chatRoomId/messages').push();
    final message = ChatMessage(
      id: messageRef.key!,
      senderId: currentUserId,
      recipientId: recipientId,
      text: text,
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // تحديث آخر رسالة في الغرفة
    await _database.ref().child('chats/$chatRoomId/lastMessage').set({
      'text': text,
      'senderId': currentUserId,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    });

    await _database.ref().child('chats/$chatRoomId/updatedAt').set(
      message.timestamp.millisecondsSinceEpoch,
    );
  }

  // إرسال رسالة مع صورة
  Future<void> sendImageMessage(
    String chatRoomId,
    String imagePath,
    String recipientId,
  ) async {
    // رفع الصورة
    final storageRef = _storage.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = await storageRef.putFile(File(imagePath));
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // إرسال الرسالة
    final messageRef = _database.ref().child('chats/$chatRoomId/messages').push();
    final message = ChatMessage(
      id: messageRef.key!,
      senderId: currentUserId,
      recipientId: recipientId,
      text: 'صورة',
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // تحديث آخر رسالة في الغرفة
    await _database.ref().child('chats/$chatRoomId/lastMessage').set({
      'text': 'صورة',
      'senderId': currentUserId,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    });

    await _database.ref().child('chats/$chatRoomId/updatedAt').set(
      message.timestamp.millisecondsSinceEpoch,
    );
  }

  // تحديث حالة القراءة
  Future<void> markMessagesAsRead(String chatRoomId) async {
    final messagesRef = _database.ref().child('chats/$chatRoomId/messages');
    final snapshot = await messagesRef.get();
    if (!snapshot.exists) return;

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};

    data.forEach((key, value) {
      if (value['recipientId'] == currentUserId && !value['isRead']) {
        updates['$key/isRead'] = true;
      }
    });

    if (updates.isNotEmpty) {
      await messagesRef.update(updates);
    }
  }

  // حذف غرفة الدردشة
  Future<void> deleteChatRoom(String chatRoomId) async {
    final chatRoomRef = _database.ref().child('chats/$chatRoomId');
    final snapshot = await chatRoomRef.get();
    
    if (!snapshot.exists) return;
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final participants = Map<String, bool>.from(data['participants'] ?? {});
    
    if (!participants.containsKey(currentUserId)) {
      throw Exception('You are not a participant in this chat room');
    }

    await chatRoomRef.remove();
  }

  // مساعدة: إنشاء معرف فريد لغرفة الدردشة
  String _getChatRoomId(String userId1, String userId2) {
    final users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }
}
