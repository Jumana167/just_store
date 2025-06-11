import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart'; // استيراد الثيم
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Notification deleted'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting notification: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // دالة لاختبار الإشعارات
  Future<void> _testNotification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ يجب تسجيل الدخول أولاً'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      // إضافة إشعار تجريبي في Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': currentUser.uid,
        'message': 'إشعار تجريبي',
        'body': 'هذا إشعار تجريبي للتأكد من عمل الإشعارات',
        'senderName': 'نظام التطبيق',
        'senderImageUrl': '',
        'type': 'test',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار محلي
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0,
        'إشعار تجريبي',
        'هذا إشعار تجريبي للتأكد من عمل الإشعارات',
        platformChannelSpecifics,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الإشعار التجريبي'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppWidgets.buildAppBar(title: 'Notifications'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: AppTheme.mediumGrey),
              SizedBox(height: 16),
              Text(
                '⚠️ User not logged in.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppWidgets.buildAppBar(
        title: 'Notifications',
        actions: [
          // زر اختبار الإشعارات
          IconButton(
            icon: const Icon(Icons.notifications_active, color: AppTheme.white),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: AppTheme.white),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('uid', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(
                      '❌ Something went wrong.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppWidgets.buildPrimaryButton(
                      text: 'Retry',
                      onPressed: () => setState(() {}),
                      icon: Icons.refresh,
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: AppTheme.mediumGrey),
                  SizedBox(height: 24),
                  Text(
                    '🔔 No notifications found.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'You\'ll see notifications here when you receive them.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: AppTheme.primaryBlue,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                final isRead = data['isRead'] ?? false;

                return Container(
                  decoration: BoxDecoration(
                    gradient: isRead ? null : AppTheme.cardGradient,
                    color: isRead ? AppTheme.white : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.withOpacity(
                            isRead ? AppTheme.borderGrey : AppTheme.primaryBlue,
                            0.2
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isRead ? Border.all(
                      color: AppTheme.borderGrey,
                      width: 1,
                    ) : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(doc.id);
                        }

                        // Navigation للبوست إذا موجود
                        if (data['postId'] != null) {
                          // Navigator.push(context, MaterialPageRoute(...));
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isRead ? AppTheme.borderGrey : AppTheme.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 23,
                                backgroundImage: data['senderImageUrl'] != null &&
                                    data['senderImageUrl'].toString().isNotEmpty
                                    ? NetworkImage(data['senderImageUrl'])
                                    : null,
                                backgroundColor: isRead
                                    ? AppTheme.lightGrey
                                    : AppTheme.withOpacity(AppTheme.white, 0.2),
                                child: data['senderImageUrl'] == null ||
                                    data['senderImageUrl'].toString().isEmpty
                                    ? Icon(
                                  Icons.person,
                                  color: isRead ? AppTheme.mediumGrey : AppTheme.white,
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['message'] ?? 'No message',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                      color: isRead ? AppTheme.darkGrey : AppTheme.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (data['senderName'] != null)
                                    Text(
                                      'From: ${data['senderName']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isRead
                                            ? AppTheme.mediumGrey
                                            : AppTheme.withOpacity(AppTheme.white, 0.8),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimestamp(data['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead
                                          ? AppTheme.mediumGrey
                                          : AppTheme.withOpacity(AppTheme.white, 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Column(
                              children: [
                                if (!isRead)
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: isRead ? AppTheme.mediumGrey : AppTheme.white,
                                  ),
                                  color: AppTheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'read':
                                        _markAsRead(doc.id);
                                        break;
                                      case 'delete':
                                        _showDeleteDialog(doc.id);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isRead)
                                      const PopupMenuItem(
                                        value: 'read',
                                        child: Row(
                                          children: [
                                            Icon(Icons.mark_email_read,
                                                color: AppTheme.success),
                                            SizedBox(width: 8),
                                            Text('Mark as read'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: AppTheme.error),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              color: AppTheme.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
            style: TextStyle(color: AppTheme.mediumGrey),
          ),
          actions: [
            AppWidgets.buildSecondaryButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteNotification(docId);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Clear All Notifications',
            style: TextStyle(
              color: AppTheme.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete all notifications?',
            style: TextStyle(color: AppTheme.mediumGrey),
          ),
          actions: [
            AppWidgets.buildSecondaryButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearAllNotifications();
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: currentUser.uid)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ All notifications cleared'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing notifications: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}