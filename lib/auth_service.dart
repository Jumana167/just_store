import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ حفظ بيانات المستخدم في كل من Firestore و Realtime Database
  Future<void> saveUserToFirestore(User user, {String? customName}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'name': customName ??
            user.displayName ??
            _extractNameFromEmail(user.email ?? ''),
        'displayName': customName ??
            user.displayName ??
            _extractNameFromEmail(user.email ?? ''),
        'username': customName ?? user.displayName ?? _extractNameFromEmail(user.email ?? ''),
        'profileImageUrl': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'phoneNumber': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
        'fcmToken': '', // سيتم تحديثه من SignUpScreen
        'favoriteCategories': [],
      };

      // حفظ في Firestore
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      // حفظ في Realtime Database أيضاً
      await FirebaseDatabase.instance.ref('users/${user.uid}').set({
        'name': userData['name'],
        'email': userData['email'],
        'username': userData['username'],
      });

      print('✅ User data saved to both Firestore and Realtime DB');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // استخراج اسم من الإيميل
  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'User';

    final username = email.split('@')[0];
    final cleanName = username
        .replaceAll(RegExp(r'[._-]'), ' ')
        .replaceAll(RegExp(r'\d+'), '') // إزالة الأرقام
        .trim();

    if (cleanName.isEmpty) return 'User';

    // جعل أول حرف من كل كلمة كبير
    return cleanName.split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ✅ Method to send verification code via Firebase HTTP Function
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://us-central1-just-66-f51b6.cloudfunctions.net/sendVerificationCode',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ OTP sent successfully via HTTP function');
        return json.decode(response.body);
      } else {
        debugPrint('❌ Failed to send OTP: ${response.body}');
        throw Exception('Failed to send verification code');
      }
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      throw Exception('Failed to send verification code. Please try again later.');
    }
  }

  static Future<Map<String, dynamic>> sendVerificationCodeStatic(String email) async {
    return await AuthService().sendVerificationCode(email);
  }

  // ✅ Verify code from Firestore
  Future<bool> verifyCode(String email, String code) async {
    try {
      final docSnapshot = await _firestore.collection('otp_codes').doc(email).get();

      if (!docSnapshot.exists) {
        debugPrint('⚠️ No verification code found for this email');
        return false;
      }

      final data = docSnapshot.data();
      final storedCode = data?['code'];
      final expiresAt = data?['expiresAt'] as Timestamp?;

      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        debugPrint('⚠️ Verification code has expired');
        return false;
      }

      return code == storedCode;
    } catch (e) {
      debugPrint('❌ Error verifying code: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ حفظ/تحديث بيانات المستخدم عند تسجيل الدخول
      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!);
      }

      debugPrint('User signed in successfully');
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password - محدث
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // تحديث display name في Firebase Auth
      await userCredential.user!.updateDisplayName(username);
      await userCredential.user!.reload();

      // ✅ حفظ بيانات كاملة للمستخدم
      await saveUserToFirestore(userCredential.user!, customName: username);

      debugPrint('User registered successfully');
      return userCredential;
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // تحديث حالة الاتصال قبل تسجيل الخروج
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName, String photoURL) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);

      // تحديث في Firestore أيضاً
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': displayName,
          'displayName': displayName,
          'profileImageUrl': photoURL,
        });

        // تحديث في Realtime Database
        await FirebaseDatabase.instance.ref('users/${user.uid}').update({
          'name': displayName,
        });
      }

      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}