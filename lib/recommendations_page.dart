import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List<DocumentSnapshot>> getContentBasedRecommendations(String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final List<dynamic> viewedTags = userDoc.data()?['viewedTags'] ?? [];

  final snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('tags', arrayContainsAny: viewedTags.take(10).toList())
      .limit(10)
      .get();

  return snapshot.docs;
}

Future<List<DocumentSnapshot>> getCategoryBasedRecommendations(String uid) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final List<dynamic> recentCategories = userDoc.data()?['recentCategories'] ?? [];

  final snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('category', whereIn: recentCategories.take(3))
      .where('createdBy', isNotEqualTo: uid)
      .limit(10)
      .get();

  return snapshot.docs;
}

Future<List<DocumentSnapshot>> getCollaborativeRecommendations(String uid) async {
  final myLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('userId', isEqualTo: uid)
      .get();

  final likedProductIds = myLikesSnapshot.docs.map((doc) => doc['productId']).toSet();

  final peerLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('productId', whereIn: likedProductIds.take(10).toList())
      .get();

  final peerUserIds = peerLikesSnapshot.docs
      .map((doc) => doc['userId'])
      .where((id) => id != uid)
      .toSet();

  final allPeerLikesSnapshot = await FirebaseFirestore.instance
      .collection('likes')
      .where('userId', whereIn: peerUserIds.take(10).toList())
      .get();

  final recommendedProductIds = allPeerLikesSnapshot.docs
      .map((doc) => doc['productId'])
      .where((id) => !likedProductIds.contains(id))
      .toSet();

  final recommendedSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .where(FieldPath.documentId, whereIn: recommendedProductIds.take(10).toList())
      .get();

  return recommendedSnapshot.docs;
}

Future<List<DocumentSnapshot>> getCombinedRecommendations(String uid) async {
  final contentBased = await getContentBasedRecommendations(uid);
  final collaborative = await getCollaborativeRecommendations(uid);
  final categoryBased = await getCategoryBasedRecommendations(uid);

  final all = {...contentBased, ...collaborative, ...categoryBased}.toList();
  all.shuffle();
  return all.take(10).toList();
}

class RecommendationsPage extends StatelessWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for You'),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: getCombinedRecommendations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recommendations available'));
          }
          final products = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: data['imageUrls'] != null && data['imageUrls'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['imageUrls'][0],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text('${data['price']} JD'),
                  onTap: () {
                    // Navigate to product details
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}