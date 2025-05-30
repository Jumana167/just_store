import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product_page.dart';
import 'settings_page.dart';
import 'chat_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'post_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _username = 'User';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inclusive, 'label': 'All', 'gradient': [Color(0xFF1976D2), Color(0xFF42A5F5)]},
    {'icon': Icons.book, 'label': 'Books', 'gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)]},
    {'icon': Icons.school, 'label': 'Lab Coat', 'gradient': [Color(0xFF1565C0), Color(0xFF1976D2)]},
    {'icon': Icons.laptop, 'label': 'Laptop', 'gradient': [Color(0xFF0D47A1), Color(0xFF1976D2)]},
    {'icon': Icons.medical_services, 'label': 'Medical', 'gradient': [Color(0xFF1976D2), Color(0xFF2196F3)]},
    {'icon': Icons.architecture, 'label': 'Engineering', 'gradient': [Color(0xFF0277BD), Color(0xFF03A9F4)]},
    {'icon': Icons.color_lens, 'label': 'Arts', 'gradient': [Color(0xFF0288D1), Color(0xFF29B6F6)]},
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _username = user?.displayName ?? 'User';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchBar(),
                SizedBox(height: 90, child: _buildCategorySelector()),
                Expanded(child: _buildPostsGrid()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
              ),
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1976D2), size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          _buildAppBarButton(Icons.notifications_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
          }),
          const SizedBox(width: 8),
          _buildAppBarButton(Icons.settings_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.search, color: Color(0xFF64B5F6), size: 22),
            ),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search for products...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Color(0xFF1976D2), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['label'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 16),
              width: 70,
              child: Column(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: category['gradient'])
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? category['gradient'][0].withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category['icon'],
                      size: 24,
                      color: isSelected ? Colors.white : const Color(0xFF64B5F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['label'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1976D2) : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', true),
              _buildNavItem(Icons.favorite_rounded, 'Favorites', false),
              const SizedBox(width: 40),
              _buildNavItem(Icons.chat_bubble_rounded, 'Messages', false),
              _buildNavItem(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (label == 'Favorites') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        } else if (label == 'Messages') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
        } else if (label == 'Profile') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userName: _username)));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)])
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF1976D2) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    final query = FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading posts', style: TextStyle(color: Colors.grey)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1976D2)),
          );
        }

        final posts = snapshot.data!.docs;
        final filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toLowerCase() ?? '';
          final category = data['category'] ?? '';
          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No posts found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try changing your search or category filter',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final doc = filteredPosts[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPostCard(doc.id, data, index);
          },
        );
      },
    );
  }

  Widget _buildPostCard(String postId, Map<String, dynamic> data, int index) {
    final name = data['name'] ?? 'Untitled';
    final price = data['price']?.toString() ?? '0';
    final imageUrl = data['imageUrl'] ?? '';
    final condition = data['condition'] ?? 'Good';
    final location = data['location'] ?? 'Unknown';
    final timestamp = data['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : '';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsPage(postId: postId, postData: data),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      )
                          : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    ),
                    // Condition Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getConditionColor(condition),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "\$$price",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color(0xFF4CAF50);
      case 'excellent':
        return const Color(0xFF2196F3);
      case 'good':
        return const Color(0xFFFF9800);
      case 'fair':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}