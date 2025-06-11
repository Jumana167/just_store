import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final String? imageUrl;
  final String? senderPhotoUrl;
  final String? recipientPhotoUrl;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    this.imageUrl,
    this.senderPhotoUrl,
    this.recipientPhotoUrl,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      recipientId: map['recipientId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      senderPhotoUrl: map['senderPhotoUrl'],
      recipientPhotoUrl: map['recipientPhotoUrl'],
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'imageUrl': imageUrl,
      'senderPhotoUrl': senderPhotoUrl,
      'recipientPhotoUrl': recipientPhotoUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? text,
    String? imageUrl,
    String? senderPhotoUrl,
    String? recipientPhotoUrl,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      recipientPhotoUrl: recipientPhotoUrl ?? this.recipientPhotoUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
} 