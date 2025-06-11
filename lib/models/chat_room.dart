class ChatRoom {
  final String id;
  final Map<String, bool> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      participants: Map<String, bool>.from(map['participants'] ?? {}),
      lastMessage: map['lastMessage']?['text'],
      lastMessageSenderId: map['lastMessage']?['senderId'],
      lastMessageTime: map['lastMessage']?['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessage']['timestamp'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage != null
          ? {
              'text': lastMessage,
              'senderId': lastMessageSenderId,
              'timestamp': lastMessageTime?.millisecondsSinceEpoch,
            }
          : null,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  String getOtherUserId(String currentUserId) {
    return participants.keys.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherUserName(String currentUserId) {
    return getOtherUserId(currentUserId);
  }

  String getOtherUserAvatar(String currentUserId) {
    return '';
  }
} 