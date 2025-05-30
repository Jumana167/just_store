// lib/services/chat_service.dart (استبدل الملف القديم بهذا)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  // إنشاء معرف غرفة محادثة من معرفات المستخدمين
  String getChatRoomId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // تحديث حالة الاتصال
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // إنشاء أو الحصول على غرفة محادثة
  Future<String> createOrGetChatRoom(String recipientId, String recipientName, String recipientAvatar) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final currentUser = _auth.currentUser!;
    final currentUserName = currentUser.displayName ?? 'User';
    final currentUserAvatar = currentUser.photoURL ?? '';

    final chatRoomId = getChatRoomId(currentUserId!, recipientId);
    final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'participants': [currentUserId, recipientId],
        'userNames': {
          currentUserId!: currentUserName,
          recipientId: recipientName,
        },
        'userAvatars': {
          currentUserId!: currentUserAvatar,
          recipientId: recipientAvatar,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageType': 'text',
        'typing': {
          currentUserId!: false,
          recipientId: false,
        },
        'unreadCount': {
          currentUserId!: 0,
          recipientId: 0,
        },
      });
    }

    return chatRoomId;
  }

  // الحصول على قائمة المحادثات
  Stream<QuerySnapshot> getChatRooms() {
    if (currentUserId == null) throw Exception('User not logged in');

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // الحصول على رسائل محادثة
  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // البحث عن المستخدمين - الدالة المفقودة
  Future<QuerySnapshot> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return await _firestore.collection('users').limit(1).get();
    }

    return await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .limit(20)
        .get();
  }

  // تحديث حالة الكتابة
  Future<void> updateTypingStatus(String chatRoomId, bool isTyping) async {
    if (currentUserId == null) return;

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'typing.$currentUserId': isTyping,
    });
  }

  // إرسال رسالة نصية
  Future<void> sendTextMessage(String chatRoomId, String text, String recipientId) async {
    if (currentUserId == null) throw Exception('User not logged in');
    if (text.trim().isEmpty) return;

    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'imageUrl': '',
      'timestamp': timestamp,
      'type': 'text',
      'isRead': false,
    });

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': text,
      'lastMessageTime': timestamp,
      'lastMessageType': 'text',
      'unreadCount.$recipientId': FieldValue.increment(1),
    });
  }

  // إرسال صورة
  Future<void> sendImageMessage(String chatRoomId, File imageFile, String recipientId) async {
    if (currentUserId == null) throw Exception('User not logged in');

    final timestamp = FieldValue.serverTimestamp();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage
        .ref()
        .child('chat_images')
        .child(chatRoomId)
        .child(fileName);

    final uploadTask = await storageRef.putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': '',
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'type': 'image',
      'isRead': false,
    });

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': '📷 Photo',
      'lastMessageTime': timestamp,
      'lastMessageType': 'image',
      'unreadCount.$recipientId': FieldValue.increment(1),
    });
  }

  // تعليم الرسائل كمقروءة
  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'unreadCount.$currentUserId': 0,
    });

    final unreadMessages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // حذف رسالة
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // حذف محادثة كاملة
  Future<void> deleteChatRoom(String chatRoomId) async {
    if (currentUserId == null) return;

    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chat_rooms').doc(chatRoomId));
    await batch.commit();
  }

  // الحصول على حالة الكتابة
  Stream<DocumentSnapshot> getTypingStatus(String chatRoomId) {
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }

  // الحصول على حالة الاتصال للمستخدم
  Stream<DocumentSnapshot> getUserOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}