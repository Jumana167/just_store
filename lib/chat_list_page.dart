// lib/screens/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'chat_page.dart';
import 'app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

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
    final otherUserId = chatRoom.getOtherUserId(currentUserId);

    return {
      'id': otherUserId,
      'name': chatRoom.getOtherUserName(currentUserId),
      'avatar': chatRoom.getOtherUserAvatar(currentUserId),
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
  Future<void> _searchUsers() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
          .where('displayName', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = query.docs
            .map((doc) => {
                  'uid': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startChat(Map<String, dynamic> userData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatService = ChatService();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final String chatRoomId = await chatService.createOrGetChatRoom(
        userData['uid'],
        userData['displayName'] ?? 'User',
        userData['photoURL'] ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatRoomId: chatRoomId,
            recipientId: userData['uid'],
            recipientName: userData['displayName'] ?? 'User',
            recipientAvatar: userData['photoURL'] ?? '',
          ),
        ),
      );

      // Clear search after starting chat
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('Please login to view chats'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n?.messages ?? 'Messages'),
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: UserSearchSheet(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final chats = snapshot.data?.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList() ?? [];
          
          // ترتيب النتائج في الكود بدلاً من الـ query
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by searching for users',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatRoom = chats[index];
              final currentUserId = _auth.currentUser?.uid ?? '';
              final otherUserId = chatRoom.getOtherUserId(currentUserId);
              final otherUserName = chatRoom.getOtherUserName(currentUserId);
              final otherUserAvatar = chatRoom.getOtherUserAvatar(currentUserId);
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: otherUserAvatar.isNotEmpty
                      ? NetworkImage(otherUserAvatar)
                      : null,
                  child: otherUserAvatar.isEmpty
                      ? Text(otherUserName[0].toUpperCase())
                      : null,
                ),
                title: Text(otherUserName),
                subtitle: Text(
                  _formatLastMessage(chatRoom.lastMessage, chatRoom.lastMessageType),
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
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                    ),
                    if ((chatRoom.unreadCount[currentUserId] ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          (chatRoom.unreadCount[currentUserId] ?? 0).toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                        recipientId: otherUserId,
                        recipientName: otherUserName,
                        recipientAvatar: otherUserAvatar,
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

class UserSearchSheet extends StatefulWidget {
  const UserSearchSheet({super.key});

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
          .where('displayName', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = query.docs
            .map((doc) => {
                  'uid': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startChat(Map<String, dynamic> userData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatService = ChatService();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final String chatRoomId = await chatService.createOrGetChatRoom(
        userData['uid'],
        userData['displayName'] ?? 'User',
        userData['photoURL'] ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatRoomId: chatRoomId,
            recipientId: userData['uid'],
            recipientName: userData['displayName'] ?? 'User',
            recipientAvatar: userData['photoURL'] ?? '',
          ),
        ),
      );

      // Clear search after starting chat
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _searchController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n?.searchUsersHint ?? 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _searchUsers();
            },
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                if (user['uid'] == currentUser?.uid) return const SizedBox.shrink();
                
                // Fix the condition here - check if photoURL exists and is not empty
                final photoUrl = user['photoURL']?.toString() ?? '';
                final hasValidPhoto = photoUrl.isNotEmpty;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: hasValidPhoto
                        ? NetworkImage(photoUrl)
                        : null,
                    child: !hasValidPhoto
                        ? Text(user['displayName']?[0].toUpperCase() ?? 'U')
                        : null,
                  ),
                  title: Text(user['displayName'] ?? 'User'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      Navigator.pop(context);
                      _startChat(user);
                    },
                  ),
                );
              },
            ),
          )
        else if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n?.noUsersFound ?? 'No users found',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }
}