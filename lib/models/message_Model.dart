import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String senderId;
  final String text;
  final String imageUrl;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final Map<String, String>? reactions; // إضافة ردود الأفعال

  Message({
    this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.reactions,
  });

  // تحويل من Firestore إلى Message
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;

    // تحويل ردود الأفعال
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = Map<String, String>.from(reactionsData);

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: timestamp?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'text',
      isRead: data['isRead'] ?? false,
      reactions: reactions.isNotEmpty ? reactions : null,
    );
  }

  // تحويل Message إلى Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
      if (reactions != null) 'reactions': reactions,
    };
  }

  // إنشاء نسخة معدلة من الرسالة
  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      reactions: reactions ?? this.reactions,
    );
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, String> userNames;
  final Map<String, String> userAvatars;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageType;
  final Map<String, bool> typing;
  final Map<String, int> unreadCount;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.userNames,
    required this.userAvatars,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageType,
    required this.typing,
    required this.unreadCount,
  });

  // تحويل من Firestore إلى ChatRoom
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // تحويل timestamp
    final createdAt = data['createdAt'] as Timestamp?;
    final lastMessageTime = data['lastMessageTime'] as Timestamp?;

    // تحويل المشاركين
    final participantsData = data['participants'] as List?;
    final participants = participantsData?.map((e) => e.toString()).toList() ?? [];

    // تحويل أسماء المستخدمين
    final userNamesData = data['userNames'] as Map<String, dynamic>? ?? {};
    final userNames = Map<String, String>.from(userNamesData);

    // تحويل صور المستخدمين
    final userAvatarsData = data['userAvatars'] as Map<String, dynamic>? ?? {};
    final userAvatars = Map<String, String>.from(userAvatarsData);

    // تحويل حالة الكتابة
    final typingData = data['typing'] as Map<String, dynamic>? ?? {};
    final typing = Map<String, bool>.from(typingData.map((key, value) =>
        MapEntry(key, value as bool? ?? false)));

    // تحويل عدد الرسائل غير المقروءة
    final unreadCountData = data['unreadCount'] as Map<String, dynamic>? ?? {};
    final unreadCount = Map<String, int>.from(unreadCountData.map((key, value) =>
        MapEntry(key, (value as num?)?.toInt() ?? 0)));

    return ChatRoom(
      id: doc.id,
      participants: participants,
      userNames: userNames,
      userAvatars: userAvatars,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: lastMessageTime?.toDate() ?? DateTime.now(),
      lastMessageType: data['lastMessageType'] ?? 'text',
      typing: typing,
      unreadCount: unreadCount,
    );
  }

  // تحويل ChatRoom إلى Map
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'userNames': userNames,
      'userAvatars': userAvatars,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageType': lastMessageType,
      'typing': typing,
      'unreadCount': unreadCount,
    };
  }

  // الحصول على اسم المستخدم الآخر
  String getOtherUserName(String currentUserId) {
    final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
    return userNames[otherUserId] ?? 'Unknown User';
  }

  // الحصول على صورة المستخدم الآخر
  String getOtherUserAvatar(String currentUserId) {
    final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
    return userAvatars[otherUserId] ?? '';
  }

  // الحصول على معرف المستخدم الآخر
  String getOtherUserId(String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // التحقق من كون المستخدم الآخر يكتب
  bool isOtherUserTyping(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return typing[otherUserId] ?? false;
  }

  // الحصول على عدد الرسائل غير المقروءة للمستخدم الحالي
  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }
}