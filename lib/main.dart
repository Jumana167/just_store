// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'providers/language_provider.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';
import 'success_page.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'auth_service.dart';

// 🔔 Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 📥 Background message handler - هذا يشتغل لما التطبيق مقفول
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📥 [Background] Message received: ${message.messageId}');
  debugPrint('📥 [Background] Title: ${message.notification?.title}');
  debugPrint('📥 [Background] Body: ${message.notification?.body}');

  // احفظ النوتيفيكيشن في Firestore حتى لو التطبيق مقفول
  try {
    await _saveNotificationToFirestore(message);
  } catch (e) {
    debugPrint('❌ Error saving background notification: $e');
  }
}

// دالة لحفظ النوتيفيكيشن في Firestore
Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
  final data = message.data;
  final notification = message.notification;

  if (data['recipientUid'] != null) {
    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': data['recipientUid'],
      'message': notification?.title ?? data['message'] ?? 'New notification',
      'body': notification?.body ?? data['body'] ?? '',
      'senderName': data['senderName'] ?? 'Unknown',
      'senderImageUrl': data['senderImageUrl'] ?? '',
      'postId': data['postId'],
      'type': data['type'] ?? 'general',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Notification saved to Firestore');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 Firebase Initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // 🔔 Local Notification Initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📱 Local notification tapped: ${response.payload}');
        // يمكنك إضافة navigation هنا
      },
    );

    // إنشاء قناة الإشعارات للأندرويد
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    // إنشاء القناة
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 📥 FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚨 Request Notification Permissions مع تفاصيل أكثر
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notification permissions');
    } else {
      debugPrint('❌ User declined notification permissions');
    }

    // 🔑 Get and Save FCM Token
    await _setupFCMToken();

  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// دالة لإعداد FCM Token
Future<void> _setupFCMToken() async {
  try {
    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      debugPrint('🔑 FCM Token: $fcmToken');
      
      // احفظ الـ token في Firestore للمستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM Token saved for user: ${user.uid}');
      }
    }

    // استمع لتغيير الـ token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // احفظ الـ token الجديد في Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ New FCM Token saved for user: ${user.uid}');
      }
    });

  } catch (e) {
    debugPrint('❌ Error getting FCM token: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupFCMListeners();
  }

  // ✅ إعداد AuthStateListener لحفظ بيانات المستخدمين تلقائياً
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('👤 User logged in: ${user.email}');

        // حفظ/تحديث بيانات المستخدم + FCM Token
        try {
          await _authService.saveUserToFirestore(user);

          // احفظ FCM Token للمستخدم الحالي
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'fcmToken': fcmToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
            debugPrint('✅ FCM Token saved for user: ${user.uid}');
          }

        } catch (error) {
          debugPrint('❌ Error saving user data: $error');
        }
      } else {
        debugPrint('👤 User logged out');
      }
    });
  }

  // 🔔 إعداد FCM Listeners
  void _setupFCMListeners() {
    // معالجة الإشعارات في الواجهة الأمامية
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📲 FCM Message received: [0m${message.messageId}');
      _saveNotificationToFirestore(message); // احفظ الإشعار في Firestore
      // يمكنك هنا أيضًا حذف الإشعارات العربية إذا أردت
      Future.delayed(const Duration(milliseconds: 500), () {
        FirestoreNotificationService.removeArabicNotificationsImmediate();
      });
    });

    // معالجة النقر على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notification clicked: ${message.messageId}');
      // يمكنك إضافة navigation هنا
    });

    // فحص الرسايل اللي جات وقت التطبيق مقفول
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 [Initial] App opened from notification: ${message.messageId}');
        // Handle navigation
      }
    });
  }

  // دالة لعرض الإشعار محلياً
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: const Color(0xFF2196F3), // لون الإشعار
            playSound: true,
            enableVibration: true,
            enableLights: true,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['postId'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء التحقق من حالة المصادقة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'JUST STORE',
            theme: themeProvider.currentTheme,
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // المستخدم مسجل دخول أم لا
        final User? user = snapshot.data;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'JUST STORE',
          theme: themeProvider.currentTheme,

          // ✅ توجيه المستخدم حسب حالة تسجيل الدخول
          home: user != null ? const HomePage() : const SplashScreen(),

          routes: {
            '/home': (context) => const HomePage(),
          },

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],

          locale: languageProvider.currentLocale,

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child!,
            );
          },
        );
      },
    );
  }
}