// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'providers/language_provider.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';
import 'success_page.dart'; // 📝 إضافة صفحة النجاح
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'auth_service.dart';

// 🔔 Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 📥 Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📥 [Background] Message received: ${message.messageId}');
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
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 📥 FCM Setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🚨 Request Notification Permissions
    await messaging.requestPermission();

    // 🔑 Print FCM Token
    final String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      debugPrint('FCM Token: $fcmToken');
    }

    // 📲 Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.showNotification(
          title: notification.title ?? 'No title',
          body: notification.body ?? 'No message body',
        );
      }
    });
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
  }

  // ✅ إعداد AuthStateListener لحفظ بيانات المستخدمين تلقائياً
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('👤 User logged in: ${user.email}');
        // حفظ/تحديث بيانات المستخدم عند تسجيل الدخول
        _authService.saveUserToFirestore(user).catchError((error) {
          debugPrint('❌ Error saving user data: $error');
        });
      } else {
        debugPrint('👤 User logged out');
      }
    });
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
            '/verify': (context) => const VerifyCodePage(email: 'test@example.com'),
            '/success': (context) => const SuccessPage(), // 🎉 إضافة صفحة النجاح
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