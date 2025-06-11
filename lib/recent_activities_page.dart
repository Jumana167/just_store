import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

// PostDetailsPage class definition
class PostDetailsPage extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(postData['name'] ?? 'Product Details'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: (postData['imageUrls'] != null && (postData['imageUrls'] as List).isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          postData['imageUrls'][0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.shopping_bag, size: 100, color: Colors.blue),
                        ),
                      )
                    : (postData['imageUrl'] != null && postData['imageUrl'].toString().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              postData['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.shopping_bag, size: 100, color: Colors.blue),
                            ),
                          )
                        : Icon(Icons.shopping_bag, size: 100, color: Colors.blue),
              ),
            ),
            SizedBox(height: 20),

            // Product Name
            Text(
              postData['name'] ?? 'Unknown Product',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            // Price
            Text(
              'Price: \$${postData['price']?.toString() ?? '0'}',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),

            // Condition
            Row(
              children: [
                Text(
                  'Condition: ',
                  style: TextStyle(fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConditionColor(postData['condition'] ?? 'good').withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    postData['condition'] ?? 'Good',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getConditionColor(postData['condition'] ?? 'good'),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            // Category & Subcategory
            if (postData['category'] != null || postData['subcategory'] != null)
              Row(
                children: [
                  Icon(Icons.category, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    '${postData['category'] ?? ''} ${postData['subcategory'] != null ? '> ${postData['subcategory']}' : ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            SizedBox(height: 15),

            // Location
            if (postData['location'] != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    postData['location'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            SizedBox(height: 20),

            // Description
            Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    postData['description'] ?? 'No description available for this product.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Back Button
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back to Recent Activities',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class RecentActivitiesPage extends StatefulWidget {
  const RecentActivitiesPage({super.key});

  @override
  State<RecentActivitiesPage> createState() => _RecentActivitiesPageState();
}

class _RecentActivitiesPageState extends State<RecentActivitiesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> userProducts = [];
  bool isLoading = true;
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchUserProducts();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      print('✅ Current user ID: $currentUserId');
    } else {
      print('❌ No current user found');
      currentUserId = "";
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && currentUserId.isNotEmpty) {
        _fetchUserProducts();
      }
    });
  }

  Future<void> _fetchUserProducts() async {
    if (currentUserId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      print('🔍 Fetching products for user: $currentUserId');

      // جلب المنتجات من collection 'products'
      final QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .where('createdBy', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      print('📦 Found ${productsSnapshot.docs.length} products');

      final List<Map<String, dynamic>> products = [];

      for (var doc in productsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['type'] = 'product';

        // طباعة بيانات المنتج للتشخيص
        print('📄 Product: ${data['name']} - ${data['price']} - ${data['condition']}');

        products.add(data);
      }

      // يمكن أيضاً جلب المنشورات من collection 'posts' إذا كانت موجودة
      try {
        final QuerySnapshot postsSnapshot = await _firestore
            .collection('posts')
            .where('ownerId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .get();

        print('📝 Found ${postsSnapshot.docs.length} posts');

        for (var doc in postsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['type'] = 'post';
          products.add(data);
        }
      } catch (e) {
        print('⚠️ Posts collection might not exist or no posts found: $e');
      }

      setState(() {
        userProducts = products;
        isLoading = false;
      });

      if (products.isEmpty) {
        print('📭 No products found for this user');
      }

    } catch (e) {
      print('❌ Error fetching user products: $e');
      setState(() => isLoading = false);
      _showError('Error loading your products: $e');
    }
  }

  Future<void> _deleteProduct(String productId, String type) async {
    try {
      print('🗑️ Deleting $type: $productId');

      // تحديد الـ collection المناسب
      String collection = type == 'product' ? 'products' : 'posts';

      // حذف من Firebase
      await _firestore.collection(collection).doc(productId).delete();

      // حذف من القائمة المحلية
      setState(() {
        userProducts.removeWhere((item) => item['id'] == productId);
      });

      _showSuccess('${type == 'product' ? 'Product' : 'Post'} deleted successfully!');
      print('✅ $type deleted successfully');

    } catch (e) {
      print('❌ Error deleting $type: $e');
      _showError('Error deleting ${type}: $e');
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    final itemName = item['name'] ?? 'Unknown item';
    final itemType = item['type'] ?? 'item';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${itemType == 'product' ? 'Product' : 'Post'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$itemName"?'),
            const SizedBox(height: 8),
            Text(
              '⚠️ This action cannot be undone',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // إظهار loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await _deleteProduct(item['id'], item['type']);
                Navigator.pop(context); // إخفاء loading
              } catch (e) {
                Navigator.pop(context); // إخفاء loading
                _showError('Error during deletion: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(
          postId: product['id'],
          postData: product,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays > 1 ? "days" : "day"} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours > 1 ? "hours" : "hour"} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes > 1 ? "minutes" : "minute"} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final numPrice = price is String ? int.tryParse(price) ?? 0 : price;
    return NumberFormat('#,##0', 'en_US').format(numPrice);
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'product':
        return Icons.shopping_bag;
      case 'post':
        return Icons.article;
      default:
        return Icons.inventory;
    }
  }

  Widget _buildProductCard(Map<String, dynamic> item, bool isDark, Color textColor) {
    final name = item['name'] ?? 'Unknown item';
    final price = item['price'] ?? 0;
    final condition = item['condition'] ?? 'good';
    final timestamp = item['createdAt'];
    final category = item['category'] ?? '';
    final subcategory = item['subcategory'] ?? '';
    final type = item['type'] ?? 'product';
    final location = item['location'] ?? '';

    return Card(
      color: isDark ? AppTheme.darkGrey : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _navigateToProductDetails(item),
        leading: CircleAvatar(
          backgroundColor: _getConditionColor(condition),
          child: Icon(
            _getItemIcon(type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Price: \$${_formatPrice(price)}',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (category.isNotEmpty || subcategory.isNotEmpty)
              Text(
                '${category}${subcategory.isNotEmpty ? ' > $subcategory' : ''}',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Condition: ',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  condition,
                  style: TextStyle(
                    color: _getConditionColor(condition),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  Text(' • ', style: TextStyle(color: textColor.withOpacity(0.5))),
                  Icon(Icons.location_on, size: 12, color: Colors.red),
                  Text(
                    ' $location',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(item),
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.white : AppTheme.darkGrey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('My Products', style: TextStyle(color: AppTheme.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _fetchUserProducts,
          ),
        ],
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text('Loading your products...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchUserProducts,
        color: AppTheme.primaryBlue,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.inventory_2, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'My Products',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${userProducts.length}',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: userProducts.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUserId.isEmpty
                            ? 'Please sign in to view your products'
                            : 'No products yet',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUserId.isEmpty
                            ? 'Sign in to see your listed products'
                            : 'Start by adding your first product!',
                        style: TextStyle(
                          color: textColor.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: userProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                        userProducts[index],
                        isDark,
                        textColor
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}