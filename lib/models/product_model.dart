import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Product {
  final String? id;
  final String name;
  final String price;
  final String description;
  final String category;
  final String contactMethod;
  final String phone;
  final String whatsapp;
  final String imageUrl;
  final Timestamp? timestamp;
  final int likes;
  final int views;
  final String? ownerId;
  final String ownerName;
  final String ownerAvatar;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.contactMethod,
    required this.phone,
    required this.whatsapp,
    required this.imageUrl,
    this.timestamp,
    this.likes = 0,
    this.views = 0,
    this.ownerId,
    required this.ownerName,
    required this.ownerAvatar,
  });

  // Convert from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      contactMethod: data['contactMethod'] ?? '',
      phone: data['phone'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'],
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      ownerId: data['ownerId'],
      ownerName: data['ownerName'] ?? 'Anonymous',
      ownerAvatar: data['ownerAvatar'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'contactMethod': contactMethod,
      'phone': phone,
      'whatsapp': whatsapp,
      'imageUrl': imageUrl,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'likes': likes,
      'views': views,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
    };
  }

  // Create a copy with updated values
  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? description,
    String? category,
    String? contactMethod,
    String? phone,
    String? whatsapp,
    String? imageUrl,
    Timestamp? timestamp,
    int? likes,
    int? views,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      contactMethod: contactMethod ?? this.contactMethod,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
    );
  }

  // Helper methods for Product

  // Format price with currency
  String get formattedPrice => '$price JD';

  // Check if product has image
  bool get hasImage => imageUrl.isNotEmpty;

  // Get formatted timestamp
  String get formattedDate {
    if (timestamp == null) return '';
    final date = timestamp!.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // Check if user is owner
  bool isOwner(String? userId) {
    return ownerId != null && ownerId == userId;
  }
}