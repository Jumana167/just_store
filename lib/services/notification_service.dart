import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // عرض الإشعار المحلي
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'Default Channel',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  // حفظ FCM Token في قاعدة البيانات
  static Future<void> saveFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ FCM Token saved: $token');
      }
    }
  }

  // مسح FCM Token عند تسجيل الخروج
  static Future<void> clearFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': FieldValue.delete(),
      });
    }
  }

  // معالجة الضغط على الإشعار
  static void setupMessageHandlers() {
    // عند فتح التطبيق من إشعار
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessage(message);
      }
    });

    // عند الضغط على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    // هنا تقدر تضيف الانتقال للصفحة المناسبة
    print('Notification clicked: ${message.data}');
  }
}

class FirestoreNotificationService {
  static Timer? _cleanupTimer;

  // دالة محسنة لحذف الإشعارات العربية فوراً
  static Future<void> removeArabicNotificationsImmediate() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🧹 Starting immediate cleanup of Arabic notifications...');

      // حذف فوري لجميع الإشعارات العربية
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;

      for (var doc in query.docs) {
        final data = doc.data();
        final message = data['message'] ?? '';
        final type = data['type'] ?? '';
        
        // حذف أي إشعار يحتوي على النصوص العربية أو نوع post_comment
        if (message.contains('مستخدم علق') || 
            message.contains('علّق على منشورك') ||
            message.contains('أُعجب بمنتجك') ||
            message.contains('مستخدم أُعجب') ||
            message.contains('علق على منشورك') ||
            message.contains('استخدم علق') ||
            type == 'post_comment' ||
            (message.isEmpty && type.isEmpty)) {
          
          batch.delete(doc.reference);
          deletedCount++;
          print('🗑️ Deleting: [0m${message.length > 30 ? message.substring(0, 30) + "..." : message}');
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('✅ Removed $deletedCount Arabic/duplicate notifications');
      } else {
        print('✅ No Arabic notifications found to remove');
      }
    } catch (e) {
      print('❌ Error removing Arabic notifications: $e');
    }
  }

  // دالة للمراقبة المستمرة وحذف الإشعارات العربية
  static void startArabicNotificationCleaner() {
    // إيقاف المؤقت السابق إذا كان موجود
    _cleanupTimer?.cancel();
    
    // تشغيل كل 5 ثوان
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await removeArabicNotificationsImmediate();
    });
    print('🤖 Arabic notification cleaner started');
  }

  // إيقاف المنظف التلقائي
  static void stopArabicNotificationCleaner() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('🛑 Arabic notification cleaner stopped');
  }

  // دالة لمسح الإشعارات العربية المكررة (النسخة القديمة محسنة)
  static Future<void> removeArabicNotifications() async {
    await removeArabicNotificationsImmediate();
  }

  // إرسال إشعار عند الإعجاب بمنتج
  static Future<void> sendProductLikeNotification({
    required String productOwnerUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
    required String productId,
    required String productName,
  }) async {
    if (productOwnerUid == senderUid) return;

    try {
      print('🚀 Starting to send product like notification...');

      // حذف الإشعارات العربية أولاً
      await removeArabicNotificationsImmediate();

      // حفظ الإشعار في قاعدة البيانات
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': productOwnerUid,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderImageUrl': senderImageUrl,
        'type': 'product_like',
        'productId': productId,
        'productName': productName,
        'timestamp': Timestamp.now(),
        'message': '$senderName liked your product "$productName"',
        'read': false,
        'source': 'app',
        'language': 'en',
      });

      print('✅ Product like notification sent to: $productOwnerUid');

      // حذف الإشعارات العربية مرة أخرى
      Future.delayed(const Duration(seconds: 1), () async {
        await removeArabicNotificationsImmediate();
      });

    } catch (e) {
      print('❌ Error sending product like notification: $e');
    }
  }

  // إرسال إشعار عند التعليق على منتج (محسن)
  static Future<void> sendProductCommentNotification({
    required String productOwnerUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
    required String productId,
    required String productName,
    required String commentText,
  }) async {
    if (productOwnerUid == senderUid) return;

    try {
      print('🚀 Starting to send comment notification...');

      // حذف الإشعارات العربية أولاً
      await removeArabicNotificationsImmediate();

      // إرسال الإشعار الصحيح
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': productOwnerUid,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderImageUrl': senderImageUrl,
        'type': 'product_comment',
        'productId': productId,
        'productName': productName,
        'commentText': commentText,
        'timestamp': Timestamp.now(),
        'message': '$senderName commented on your product "$productName"',
        'read': false,
        'source': 'app',
        'language': 'en',
      });

      print('✅ Product comment notification sent to: $productOwnerUid');
      print('🔥 Now calling removeArabicNotifications...');

      // حذف الإشعارات العربية مرة أخرى بعد ثانية
      Future.delayed(const Duration(seconds: 1), () async {
        await removeArabicNotificationsImmediate();
      });

      // حذف إضافي بعد 3 ثوان
      Future.delayed(const Duration(seconds: 3), () async {
        await removeArabicNotificationsImmediate();
      });

      // حذف إضافي بعد 5 ثوان للتأكد التام
      Future.delayed(const Duration(seconds: 5), () async {
        await removeArabicNotificationsImmediate();
      });

    } catch (e) {
      print('❌ Error sending comment notification: $e');
    }
  }

  // إرسال إشعار عند الإعجاب بمنشور
  static Future<void> sendLikeNotification({
    required String postOwnerUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
    required String postId,
  }) async {
    if (postOwnerUid == senderUid) return;

    try {
      print('🚀 Starting to send post like notification...');

      // حذف الإشعارات العربية أولاً
      await removeArabicNotificationsImmediate();

      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': postOwnerUid,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderImageUrl': senderImageUrl,
        'type': 'like',
        'postId': postId,
        'timestamp': Timestamp.now(),
        'message': '$senderName liked your post',
        'read': false,
        'source': 'app',
        'language': 'en',
      });

      print('✅ Post like notification sent to: $postOwnerUid');

      // حذف الإشعارات العربية مرة أخرى
      Future.delayed(const Duration(seconds: 1), () async {
        await removeArabicNotificationsImmediate();
      });

    } catch (e) {
      print('❌ Error sending post like notification: $e');
    }
  }

  // إرسال إشعار عند إرسال رسالة
  static Future<void> sendMessageNotification({
    required String receiverUid,
    required String senderUid,
    required String senderName,
    required String senderImageUrl,
  }) async {
    try {
      print('🚀 Starting to send message notification...');

      // حذف الإشعارات العربية أولاً
      await removeArabicNotificationsImmediate();

      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': receiverUid,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderImageUrl': senderImageUrl,
        'type': 'message',
        'timestamp': Timestamp.now(),
        'message': '$senderName sent you a message',
        'read': false,
        'source': 'app',
        'language': 'en',
      });

      print('✅ Message notification sent to: $receiverUid');

      // حذف الإشعارات العربية مرة أخرى
      Future.delayed(const Duration(seconds: 1), () async {
        await removeArabicNotificationsImmediate();
      });

    } catch (e) {
      print('❌ Error sending message notification: $e');
    }
  }

  // دالة لحذف جميع الإشعارات المكررة والعربية دفعة واحدة
  static Future<void> cleanupAllDuplicateNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🧽 Starting comprehensive cleanup...');

      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;
      Set<String> seenMessages = {};

      for (var doc in notifications.docs) {
        final data = doc.data();
        final message = data['message'] ?? '';
        final type = data['type'] ?? '';
        
        // حذف الإشعارات العربية أو المكررة أو post_comment
        bool shouldDelete = false;
        
        if (message.contains('مستخدم علق') || 
            message.contains('علّق على منشورك') ||
            message.contains('أُعجب بمنتجك') ||
            message.contains('مستخدم أُعجب') ||
            message.contains('علق على منشورك') ||
            type == 'post_comment' ||
            message.isEmpty) {
          shouldDelete = true;
        }
        
        // حذف الإشعارات المكررة
        if (seenMessages.contains(message) && message.isNotEmpty) {
          shouldDelete = true;
        }
        
        if (shouldDelete) {
          batch.delete(doc.reference);
          deletedCount++;
        } else {
          seenMessages.add(message);
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('✅ Comprehensive cleanup: Removed $deletedCount notifications');
      } else {
        print('✅ No duplicate notifications found');
      }
    } catch (e) {
      print('❌ Error in comprehensive cleanup: $e');
    }
  }
}