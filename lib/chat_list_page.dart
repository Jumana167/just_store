// lib/screens/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';
import 'app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/chat_room.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.search,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : Text(l10n.messages),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(l10n.errorLoadingMessages),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chatRooms = snapshot.data!;
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMessages,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredRooms = _searchQuery.isEmpty
              ? chatRooms
              : chatRooms.where((room) {
            final otherUser = room.getOtherUserId(_chatService.currentUserId);
            return otherUser.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: filteredRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = filteredRooms[index];
              return ChatRoomTile(
                chatRoom: chatRoom,
                currentUserId: _chatService.currentUserId,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        chatRoomId: chatRoom.id,
                        recipientId: chatRoom.getOtherUserId(_chatService.currentUserId),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatRoomTile({
    Key? key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  // ✅ دالة محسنة للحصول على User ID الصحيح
  String _getCorrectUserId() {
    // ابحث في participants عن المستخدم الآخر
    for (String participantId in chatRoom.participants.keys) {
      if (participantId != currentUserId &&
          participantId.isNotEmpty &&
          participantId != 'unknown') {
        return participantId;
      }
    }

    // إذا Chat Room ID يحتوي على underscore، قسمه
    if (chatRoom.id.contains('_')) {
      final parts = chatRoom.id.split('_');
      if (parts.length == 2) {
        return parts[0] == currentUserId ? parts[1] : parts[0];
      }
    }

    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = _getCorrectUserId();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue,
          child: Text(
            otherUserId != 'unknown' ? '👤' : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        title: otherUserId != 'unknown'
            ? FutureBuilder<String>(
          future: getUserName(otherUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Loading...'),
                ],
              );
            }

            final userName = snapshot.data ?? 'Unknown User';

            // ✅ تحقق محسن من صحة الاسم
            if (userName.length > 30 ||
                userName.startsWith('J') && userName.length > 20 ||
                userName == 'User' ||
                userName.contains('_')) {
              return const Text(
                'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              );
            }

            return Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            );
          },
        )
            : const Text(
          'Unknown User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            chatRoom.lastMessage ?? AppLocalizations.of(context)!.noMessages,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chatRoom.lastMessageTime),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // يمكن إضافة badge للرسائل غير المقروءة هنا
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

// ✅ دالة محسنة ومُصححة لجلب اسم المستخدم
Future<String> getUserName(String userId) async {
  try {
    print('🔍 Getting name for userId: $userId'); // للتشخيص

    // تحقق من أن userId صالح
    if (userId.isEmpty || userId == 'unknown' || userId.length > 50) {
      print('❌ Invalid userId: $userId');
      return 'Unknown User';
    }

    // أولاً: جلب من Firestore (أسرع وأوثق)
    try {
      final firestoreDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (firestoreDoc.exists) {
        final data = firestoreDoc.data()!;
        print('📄 Firestore data for $userId: $data'); // للتشخيص

        // جرب حقول مختلفة للاسم
        final name = data['name'] as String? ??
            data['displayName'] as String? ??
            data['username'] as String?;

        if (name != null && name.isNotEmpty && name != 'User' && name.length < 50) {
          print('✅ Found name in Firestore: $name');
          return name;
        }

        // إذا ما لقيناش اسم جيد، استخدم الإيميل
        final email = data['email'] as String?;
        if (email != null && email.isNotEmpty) {
          final formattedName = _formatEmailAsDisplayName(email);
          print('✅ Using email-based name: $formattedName');
          return formattedName;
        }
      } else {
        print('❌ No Firestore document for userId: $userId');
      }
    } catch (e) {
      print('❌ Firestore error: $e');
    }

    // ثانياً: جرب Realtime Database
    try {
      final realtimeSnapshot = await FirebaseDatabase.instance
          .ref('users/$userId/name')
          .get();

      if (realtimeSnapshot.exists) {
        final name = realtimeSnapshot.value as String?;
        if (name != null && name.isNotEmpty && name.length < 50) {
          print('✅ Found name in Realtime DB: $name');
          return name;
        }
      } else {
        print('❌ No name in Realtime DB for userId: $userId');
      }
    } catch (e) {
      print('❌ Realtime Database error: $e');
    }

    // آخر حل: اسم مبسط من userId
    final fallbackName = 'User ${userId.substring(0, 6)}';
    print('⚠️ Using fallback name: $fallbackName');
    return fallbackName;

  } catch (e) {
    print('❌ General error getting user name for $userId: $e');
    return 'Unknown User';
  }
}

// ✅ تحويل الإيميل لاسم جميل للعرض
String _formatEmailAsDisplayName(String email) {
  try {
    final username = email.split('@')[0];

    // تنظيف الاسم
    final cleanName = username
        .replaceAll(RegExp(r'[._-]'), ' ')
        .replaceAll(RegExp(r'\d+'), '') // إزالة الأرقام
        .trim();

    if (cleanName.isEmpty) {
      return username; // إرجاع الاسم الأصلي إذا فشل التنظيف
    }

    // جعل أول حرف من كل كلمة كبير
    final words = cleanName.split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .toList();

    return words.isNotEmpty ? words.join(' ') : username;

  } catch (e) {
    return email.split('@')[0]; // fallback آمن
  }
}
