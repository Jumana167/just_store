import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteButton extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  // Shared map for synchronization across the app
  static final Map<String, ValueNotifier<bool>> favoriteStatusNotifiers = {};

  const FavoriteButton({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  User? user;
  late ValueNotifier<bool> isFavoriteNotifier;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    // Use the same notifier for every instance of the same product
    isFavoriteNotifier = FavoriteButton.favoriteStatusNotifiers.putIfAbsent(
      widget.productId,
      () => ValueNotifier<bool>(false),
    );

    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(widget.productId)
          .get();

      if (mounted) {
        isFavoriteNotifier.value = doc.exists;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.productId);

    try {
      if (isFavoriteNotifier.value) {
        await favRef.delete();
        isFavoriteNotifier.value = false;
        _showMessage('Removed from Favorites');
      } else {
        final title = widget.productData['title'] ?? widget.productData['name'] ?? 'No Title';
        final image = widget.productData['image'] ?? widget.productData['imageUrl'] ?? '';
        final price = widget.productData['price']?.toString() ?? '0';

        await favRef.set({
          'productId': widget.productId,
          'title': title,
          'image': image,
          'price': price,
          'timestamp': Timestamp.now(),
        });

        isFavoriteNotifier.value = true;
        _showMessage('Added to Favorites');
      }
    } catch (e) {
      debugPrint('Favorite toggle failed: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isFavoriteNotifier,
      builder: (context, isFav, _) {
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
          ),
          onPressed: _toggleFavorite,
        );
      },
    );
  }
} 