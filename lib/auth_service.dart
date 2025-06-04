import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      debugPrint('User signed in successfully');
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': '',
        'favoriteCategories': [],
      });

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
      debugPrint('User profile updated successfully');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
}