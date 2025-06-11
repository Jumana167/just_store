import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'theme_provider.dart';
import 'providers/language_provider.dart';
import 'profile_page.dart';
import 'terms_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'about_app_page.dart';
import 'rate_app_page.dart';
import 'home_page.dart';
import 'chat_list_page.dart';
import 'app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsOn = true;
  final int _unreadMessages = 5;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String? _userName;
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
    _loadFCMToken();
    _loadUserName();
  }

  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsOn = prefs.getBool('notificationsOn') ?? true;
    });

    if (notificationsOn) {
      _showTestNotification();
    }
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsOn', value);
  }

  Future<void> _showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      '🔔 Notifications Enabled',
      'You will now receive app notifications!',
      notificationDetails,
    );
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoading = true);
    try {
      // جلب FCM Token من Firebase
      final token = await FirebaseMessaging.instance.getToken();
      
      // جلب FCM Token المحفوظ في Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final savedToken = userDoc.data()?['fcmToken'];
        
        setState(() {
          _fcmToken = 'Current Token: $token\n\nSaved Token: $savedToken';
        });
      }
    } catch (e) {
      setState(() {
        _fcmToken = 'Error loading token: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateFCMToken() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // جلب FCM Token جديد
        final token = await FirebaseMessaging.instance.getToken();
        
        // حفظ Token في Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });

        // تحديث الواجهة
        await _loadFCMToken();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تحديث FCM Token بنجاح'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? 'User';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppWidgets.buildAppBar(title: l10n.settings),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSettingsTile(Icons.person, l10n.profile, AppTheme.success, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userName: _userName ?? l10n.userName),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderGrey),
          const SizedBox(height: 8),
          Text(
            l10n.generalSettings,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mediumGrey),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6, color: AppTheme.warning),
            title: Text(l10n.darkMode),
            subtitle: Text(l10n.darkModeSubtitle),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleTheme(val),
            activeColor: AppTheme.primaryBlue,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppTheme.warning),
            title: Text(l10n.notifications),
            value: notificationsOn,
            onChanged: (val) {
              setState(() {
                notificationsOn = val;
              });
              _saveNotifications(val);
              val ? _showTestNotification() : _cancelAllNotifications();
            },
            activeColor: AppTheme.primaryBlue,
          ),
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.warning),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: languageProvider.currentLocale.languageCode,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: Text(l10n.arabic),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  languageProvider.changeLanguage(Locale(value));
                }
              },
            ),
          ),
          const Divider(color: AppTheme.borderGrey),
          _buildSettingsTile(
            Icons.description,
            l10n.termsConditions,
            AppTheme.info,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.lock,
            l10n.privacyPolicy,
            AppTheme.error,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.star,
            l10n.rateApp,
            AppTheme.primaryBlue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RateAppPage()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.share,
            l10n.shareApp,
            Colors.pink,
            () {
              Share.share(
                'Check out this awesome app Just Store!\nhttps://JUSTSTORE.com/juststore',
                subject: 'Just Store App 🌟',
              );
            },
          ),
          _buildSettingsTile(
            Icons.info_outline,
            l10n.about,
            AppTheme.accentBlue,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutAppPage()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.primaryBlue,
        selectedItemColor: AppTheme.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userName: _userName ?? '')),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(
            label: '',
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_unreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadMessages',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      IconData icon,
      String title,
      Color iconColor,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.mediumGrey),
        onTap: onTap,
      ),
    );
  }
}