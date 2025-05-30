// clothes_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clothes_details_page.dart';

class ClothesPage extends StatefulWidget {
  const ClothesPage({super.key});

  @override
  State<ClothesPage> createState() => _ClothesPageState();
}

class _ClothesPageState extends State<ClothesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Clothes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _search = val),
              decoration: InputDecoration(
                hintText: 'Search clothes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('category', isEqualTo: 'Clothes')
                    .orderBy('timestamp', descending: true) // ترتيب حسب التاريخ
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checkroom, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No clothes found.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // فلترة البيانات مباشرة من المستندات
                  final filtered = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final description = data['description']?.toString().toLowerCase() ?? '';
                    final searchLower = _search.toLowerCase();
                    return name.contains(searchLower) || description.contains(searchLower);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No clothes match your search.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClothesDetailsPage(
                                  image: data['imageUrl'] ?? '',
                                  title: data['name'] ?? '',
                                  description: data['description'] ?? '',
                                  price: data['price'] ?? '',
                                  phoneNumber: data['phone'] ?? '',
                                  recipientId: data['ownerId'] ?? '',
                                  recipientName: data['ownerName'] ?? 'Seller',
                                  recipientAvatar: data['ownerAvatar'] ?? '',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // صورة الملابس
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (data['imageUrl'] ?? '').isNotEmpty
                                      ? Image.network(
                                    data['imageUrl'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported),
                                        ),
                                  )
                                      : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.checkroom, size: 40),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // تفاصيل الملابس
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unnamed Item',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['description'] ?? 'No description',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '${data['price'] ?? '0'} JD',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'by ${data['ownerName'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // أيقونة العرض
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}