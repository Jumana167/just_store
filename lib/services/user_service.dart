import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // إضافة تقييم جديد
  Future<void> addRating({
    required String ratedUserId,
    required double rating,
    String? comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // التحقق من عدم تقييم نفس المستخدم
    if (currentUser.uid == ratedUserId) {
      throw Exception('Cannot rate yourself');
    }

    // التحقق من عدم تقييم نفس المستخدم مرتين
    final existingRating = await _firestore
        .collection('users')
        .doc(ratedUserId)
        .collection('ratings')
        .where('ratedBy', isEqualTo: currentUser.uid)
        .get();

    if (existingRating.docs.isNotEmpty) {
      throw Exception('You have already rated this user');
    }

    // إضافة التقييم
    await _firestore
        .collection('users')
        .doc(ratedUserId)
        .collection('ratings')
        .add({
      'rating': rating,
      'ratedBy': currentUser.uid,
      'ratedByName': currentUser.displayName ?? 'Anonymous',
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // الحصول على تقييمات المستخدم
  Future<Map<String, dynamic>> getUserRatings(String userId) async {
    final ratingsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .get();

    if (ratingsSnapshot.docs.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratings': [],
      };
    }

    double totalRating = 0;
    final ratings = ratingsSnapshot.docs.map((doc) {
      final data = doc.data();
      totalRating += data['rating'] as double;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();

    return {
      'averageRating': totalRating / ratings.length,
      'totalRatings': ratings.length,
      'ratings': ratings,
    };
  }

  // حذف تقييم
  Future<void> deleteRating(String ratedUserId, String ratingId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // التحقق من أن المستخدم هو من قام بالتقييم
    final ratingDoc = await _firestore
        .collection('users')
        .doc(ratedUserId)
        .collection('ratings')
        .doc(ratingId)
        .get();

    if (!ratingDoc.exists) {
      throw Exception('Rating not found');
    }

    if (ratingDoc.data()?['ratedBy'] != currentUser.uid) {
      throw Exception('You can only delete your own ratings');
    }

    await ratingDoc.reference.delete();
  }

  // تحديث تقييم
  Future<void> updateRating({
    required String ratedUserId,
    required String ratingId,
    required double newRating,
    String? newComment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // التحقق من أن المستخدم هو من قام بالتقييم
    final ratingDoc = await _firestore
        .collection('users')
        .doc(ratedUserId)
        .collection('ratings')
        .doc(ratingId)
        .get();

    if (!ratingDoc.exists) {
      throw Exception('Rating not found');
    }

    if (ratingDoc.data()?['ratedBy'] != currentUser.uid) {
      throw Exception('You can only update your own ratings');
    }

    await ratingDoc.reference.update({
      'rating': newRating,
      if (newComment != null) 'comment': newComment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // رفع وتحديث صورة الملف الشخصي
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // إنشاء مسار فريد للصورة
    final storageRef = _storage.ref().child('profile_images/${user.uid}');
    
    // رفع الصورة
    await storageRef.putFile(imageFile);
    
    // الحصول على رابط الصورة
    final imageUrl = await storageRef.getDownloadURL();
    
    // تحديث رابط الصورة في Firestore
    await _firestore.collection('users').doc(user.uid).update({
      'profileImageUrl': imageUrl,
    });

    return imageUrl;
  }

  // الحصول على رابط صورة الملف الشخصي
  Future<String?> getProfileImageUrl() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['profileImageUrl'];
  }
} 