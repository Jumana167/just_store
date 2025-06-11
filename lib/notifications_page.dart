import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart'; // 👈 إضافة هذا الاستيراد
import 'post_details_page.dart'; // 👈 إضافة استيراد صفحة تفاصيل المنتج
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  
  @override
  void initState() {
    super.initState();
    // طباعة FCM Token للتأكد من وجوده
    FirebaseMessaging.instance.getToken().then((token) {
      // ignore: avoid_print
      print('🔑 FCM Token: $token');
    });
    
    // 🧹 تنظيف فوري عند فتح صفحة الإشعارات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupNotifications();
    });
  }

  // دالة تنظيف الإشعارات العربية
  Future<void> _cleanupNotifications() async {
    try {
      await FirestoreNotificationService.removeArabicNotificationsImmediate();
    } catch (e) {
      print('❌ Error cleaning notifications: $e');
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  // دالة مسح جميع الإشعارات
  Future<void> _clearAllNotifications() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: currentUser.uid)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // إغلاق مؤشر التحميل
      Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared successfully')),
        );
      }
      
      print('✅ All notifications cleared');
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error clearing notifications: $e');
    }
  }

  // دالة فلترة الإشعارات لإزالة العربية والمكررة
  List<QueryDocumentSnapshot> _filterNotifications(List<QueryDocumentSnapshot> notifications) {
    return notifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final message = data['message'] ?? '';
      final type = data['type'] ?? '';
      
      // إزالة الإشعارات العربية وpost_comment
      bool isValidNotification = !message.contains('مستخدم علق') &&
             !message.contains('علّق على منشورك') &&
             !message.contains('أُعجب بمنتجك') &&
             !message.contains('مستخدم أُعجب') &&
             !message.contains('علق على منشورك') &&
             !message.contains('استخدم علق') &&
             type != 'post_comment' &&
             message.isNotEmpty;
      
      return isValidNotification;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('⚠️ User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [

          // زر تعليم الكل كمقروء
          IconButton(
            icon: Icon(Icons.done_all, color: Theme.of(context).iconTheme.color),
            tooltip: l10n.markAllAsRead,
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final notifications = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('uid', isEqualTo: currentUser.uid)
                  .where('read', isEqualTo: false)
                  .get();

              for (var doc in notifications.docs) {
                batch.update(doc.reference, {'read': true});
              }
              await batch.commit();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.markAllAsRead)),
                );
              }
            },
          ),
          // زر مسح جميع الإشعارات
          IconButton(
            icon: Icon(Icons.clear_all, color: Theme.of(context).iconTheme.color),
            tooltip: l10n.clearAllNotifications,
            onPressed: () async {
              // تأكيد الحذف
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.clearAllNotifications),
                  content: Text(l10n.deleteNotificationConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(l10n.clearAll),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _clearAllNotifications();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // ignore: avoid_print
            print('❌ Firestore Error: [0m${snapshot.error}');
            return Center(child: Text(l10n.errorLoadingPosts));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allNotifications = snapshot.data?.docs ?? [];
          
          // 🔥 فلترة الإشعارات لإزالة العربية والمكررة
          final notifications = _filterNotifications(allNotifications);
          
          // ignore: avoid_print
          print('📄 Found ${notifications.length} valid notifications (filtered from ${allNotifications.length}) for user: ${currentUser.uid}');

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                  SizedBox(height: 16),
                  Text(
                    '🔔 No notifications',
                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Likes and comments notifications will appear here',
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _cleanupNotifications();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                final isRead = data['read'] ?? false;

                // ignore: avoid_print, unnecessary_brace_in_string_interps
                print('📋 Notification ${index}: ${data['type']} - ${data['message']}');

                return Card(
                  elevation: isRead ? 1 : 3,
                  color: isRead ? Theme.of(context).cardColor : Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(data['type'], context),
                      backgroundImage: data['senderImageUrl'] != null && 
                                     data['senderImageUrl'].toString().isNotEmpty
                          ? NetworkImage(data['senderImageUrl'])
                          : null,
                      child: data['senderImageUrl'] == null || 
                             data['senderImageUrl'].toString().isEmpty
                          ? Icon(
                              _getNotificationIcon(data['type']),
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    title: Text(
                      data['message'] ?? 'No message',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عرض نص التعليق إذا كان موجود
                        if ((data['type'] == 'product_comment' || data['type'] == 'post_comment') && data['commentText'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '"${data['commentText']}"',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          data['timestamp'] != null 
                              ? formatTimestamp(data['timestamp'])
                              : 'Now',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color),
                          onPressed: () async {
                            // تأكيد الحذف
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text('Do you want to delete this notification?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .delete();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      // تعليم الإشعار كمقروء
                      if (!isRead) {
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(doc.id)
                            .update({'read': true});
                      }

                      // الانتقال للصفحة المناسبة
                      // ignore: use_build_context_synchronously
                      _handleNotificationTap(context, data);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
      case 'product_like':
        return Icons.favorite;
      case 'comment':
      case 'product_comment':
      case 'post_comment':
        return Icons.comment;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type, BuildContext context) {
    switch (type) {
      case 'like':
      case 'product_like':
        return Theme.of(context).colorScheme.error;
      case 'comment':
      case 'product_comment':
      case 'post_comment':
        return Theme.of(context).colorScheme.primary;
      case 'message':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final type = data['type'];
    
    try {
      switch (type) {
        case 'product_like':
        case 'product_comment':
          // التنقل لصفحة تفاصيل المنتج
          final productId = data['productId'];
          
          if (productId != null) {
            // إظهار مؤشر التحميل
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              // جلب بيانات المنتج الكاملة من قاعدة البيانات
              final productDoc = await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(productId)
                  .get();
              
              Navigator.pop(context); // إغلاق مؤشر التحميل
              
              if (productDoc.exists) {
                final productData = productDoc.data()!;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsPage(
                      postId: productId,
                      postData: productData,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product not found or may have been deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context); // إغلاق مؤشر التحميل في حالة الخطأ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading product: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          break;
          
        case 'like':
        case 'comment':
        case 'post_comment':
          // التنقل لصفحة تفاصيل المنشور
          final postId = data['postId'];
          
          if (postId != null) {
            // إظهار مؤشر التحميل
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              // جلب بيانات المنشور الكاملة من قاعدة البيانات
              final postDoc = await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .get();
              
              Navigator.pop(context); // إغلاق مؤشر التحميل
              
              if (postDoc.exists) {
                final postData = postDoc.data()!;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsPage(
                      postId: postId,
                      postData: postData,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post not found or may have been deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context); // إغلاق مؤشر التحميل في حالة الخطأ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading post: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          break;
          
        case 'message':
          // التنقل لصفحة المحادثة
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening chat with: ${data['senderName']}'),
              backgroundColor: const Color(0xFF1976D2),
            ),
          );
          // يمكن إضافة التنقل لصفحة المحادثة هنا
          // Navigator.pushNamed(context, '/chat', arguments: data['senderUid']);
          break;
          
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown notification type: $type'),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      print('❌ Error navigating from notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}