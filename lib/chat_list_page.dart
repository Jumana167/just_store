// lib/screens/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'chat_page.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<DocumentSnapshot> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _chatService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _chatService.updateOnlineStatus(false);
    _searchController.dispose();
    super.dispose();
  }

  // Format elapsed time
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekDays[dateTime.weekday - 1];
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  // Get other user info
  Map<String, String> _getOtherUserInfo(ChatRoom chatRoom) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final otherUserId = chatRoom.participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );

    return {
      'id': otherUserId,
      'name': chatRoom.userNames[otherUserId] ?? 'User',
      'avatar': chatRoom.userAvatars[otherUserId] ?? '',
    };
  }

  // Format last message based on type
  String _formatLastMessage(String message, String type) {
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎵 Audio recording';
      case 'file':
        return '📎 File';
      default:
        return message;
    }
  }

  // Search for users
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await _chatService.searchUsers(query);
      setState(() {
        _searchResults = result.docs;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        elevation: 0,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _searchUsers,
          autofocus: true,
        )
            : const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = [];
                } else {
                  _isSearching = true;
                }
              });
            },
          )
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildChatRoomsList(),
    );
  }

  Widget _buildChatRoomsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatRooms(),
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
                Text(
                  'No conversations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a new conversation with sellers!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final chatRooms = snapshot.data!.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();

        return ListView.separated(
          itemCount: chatRooms.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            final otherUser = _getOtherUserInfo(chatRoom);
            final isTyping = chatRoom.typing[otherUser['id']] ?? false;
            final unreadCount = chatRoom.unreadCount[_auth.currentUser!.uid] ?? 0;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                backgroundImage: otherUser['avatar']!.isNotEmpty
                    ? NetworkImage(otherUser['avatar']!)
                    : null,
                child: otherUser['avatar']!.isEmpty
                    ? Text(
                  otherUser['name']![0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              title: Text(
                otherUser['name'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: isTyping
                  ? const Text(
                'Typing...',
                style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              )
                  : Text(
                _formatLastMessage(
                  chatRoom.lastMessage,
                  chatRoom.lastMessageType,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(chatRoom.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0 ? const Color(0xFF3B3B98) : Colors.grey,
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B3B98),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatRoomId: chatRoom.id,
                      recipientId: otherUser['id']!,
                      recipientName: otherUser['name']!,
                      recipientAvatar: otherUser['avatar']!,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: _isSearching
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B3B98)),
        )
            : Text(
          'No users found',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final userData = _searchResults[index].data() as Map<String, dynamic>;
        final userId = userData['uid'] ?? '';
        final username = userData['username'] ?? 'User';
        final avatarUrl = userData['photoURL'] ?? '';

        // Don't show current user in search results
        if (userId == _auth.currentUser!.uid) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
              username[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
                : null,
          ),
          title: Text(username),
          subtitle: const Text('Tap to start a conversation'),
          onTap: () async {
            final chatRoomId = await _chatService.createOrGetChatRoom(
              userId,
              username,
              avatarUrl,
            );

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatRoomId: chatRoomId,
                  recipientId: userId,
                  recipientName: username,
                  recipientAvatar: avatarUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }
}