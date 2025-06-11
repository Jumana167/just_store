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
import 'app_theme.dart';
import 'models/categories.dart';
import 'favorite_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'recommendations_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _username = 'User';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _selectedIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Advanced Search Filters
  final List<String> faculties = [
    'Engineering',
    'Medicine',
    'Dentistry',
    'Pharmacy',
    'Nursing',
    'Agriculture',
    'Veterinary Medicine',
    'Science and Arts',
    'Computer and Information Technology',
    'Applied Medical Sciences',
    'Architecture and Design',
    'Graduate Studies',
  ];
  final List<String> conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
  ];
  final List<String> studyYears = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
    'Fifth Year',
    'Sixth Year',
  ];
  String? filterCategory;
  String? filterFaculty;
  String? filterCondition;
  String? filterYear;
  String? filterSubject;
  double? filterMinPrice;
  double? filterMaxPrice;
  TextEditingController filterSubjectController = TextEditingController();
  TextEditingController filterMinPriceController = TextEditingController();
  TextEditingController filterMaxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsername());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    filterSubjectController.dispose();
    filterMinPriceController.dispose();
    filterMaxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final displayName = user.displayName;
      final emailName = user.email?.split('@').first ?? 'User';
      setState(() {
        _username = (displayName != null && displayName.trim().isNotEmpty) ? displayName : emailName;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _navigateToCategory(String category) {
    setState(() => _selectedCategory = category);
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Already on home
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userName: _username)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSearchBar(),
                  _buildCategorySelector(),
                ],
              ),
            ),
            // Latest Products Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.new_releases, color: AppTheme.primaryBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Products',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildProductGrid(),
            ),
            // Popular Products Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppTheme.primaryBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Popular Products',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildPopularProductsGrid(),
            ),
            // Recommendations Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.recommend, color: AppTheme.primaryBlue, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecommendationsPage()),
                        );
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _buildRecommendationsList(),
            ),
            // Add bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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

  Widget _buildAppBar() {
    final theme = Theme.of(context);
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
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Text(
                _username[0].toUpperCase(),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
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
                    color: theme.textTheme.bodyLarge?.color ?? Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color ?? Colors.grey,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.textTheme.bodyLarge?.color ?? Colors.grey, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
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
                decoration: InputDecoration(
                  hintText: l10n?.searchForProducts ?? 'Search for products...',
                  hintStyle: TextStyle(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.5), fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color ?? Colors.grey),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFF1976D2), size: 20),
                onPressed: () => _showAdvancedSearch(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kAppCategories.length,
        itemBuilder: (context, index) {
          final category = kAppCategories[index];
          final isSelected = _selectedCategory == category['label'];

          return GestureDetector(
            onTap: () {
              _navigateToCategory(category['label']);
            },
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
                          ? LinearGradient(
                        colors: [category['color'], category['color'].withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? category['color'].withOpacity(0.3)
                              : theme.textTheme.bodyLarge?.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      category['icon'],
                      size: 24,
                      color: isSelected ? theme.primaryColor ?? Colors.grey : category['color'] ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.translateCategory(category['label']) ?? category['label'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? category['color'] ?? Colors.grey : theme.textTheme.bodyLarge?.color?.withOpacity(0.6) ?? Colors.grey.withOpacity(0.6),
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          _selectedIndex == 0 ? Icons.grid_view : Icons.home_rounded,
                          _selectedIndex == 0 ? (l10n?.all ?? 'All') : (l10n?.home ?? 'Home'),
                          0
                        ),
                        _buildNavItem(Icons.favorite_rounded, l10n?.favorites ?? 'Favorites', 1),
                      ],
                    ),
                  ),
                  // Center space for FAB
                  const Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(Icons.chat_bubble_rounded, l10n?.messages ?? 'Messages', 2),
                        _buildNavItem(Icons.person_rounded, l10n?.profile ?? 'Profile', 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onBottomNavTapped(index),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? theme.primaryColor ?? Colors.grey : theme.textTheme.bodyLarge?.color?.withOpacity(0.5) ?? Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? theme.primaryColor ?? Colors.grey : theme.textTheme.bodyLarge?.color?.withOpacity(0.5) ?? Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final l10n = AppLocalizations.of(context);
    final query = FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true);
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error loading posts', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        final filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final category = data['category'] ?? '';
          final faculty = data['faculty'] ?? '';
          final subject = data['subject']?.toString().toLowerCase() ?? '';
          final price = double.tryParse(data['price']?.toString() ?? '') ?? 0;
          final condition = data['condition'] ?? '';
          final year = data['studyYear'] ?? '';

          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
          final matchesFilterCategory = filterCategory == null || category == filterCategory;
          final matchesFaculty = filterFaculty == null || faculty == filterFaculty;
          final matchesSubject = filterSubject == null || subject.contains(filterSubject!.toLowerCase());
          final matchesCondition = filterCondition == null || condition == filterCondition;
          final matchesYear = filterYear == null || year == filterYear;
          final matchesMinPrice = filterMinPrice == null || price >= filterMinPrice!;
          final matchesMaxPrice = filterMaxPrice == null || price <= filterMaxPrice!;

          return matchesSearch && matchesCategory && matchesFilterCategory &&
              matchesFaculty && matchesSubject && matchesCondition &&
              matchesYear && matchesMinPrice && matchesMaxPrice;
        }).toList();

        if (filteredPosts.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No posts found',
                    style: TextStyle(fontSize: 18, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try changing your search or category filter',
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = filteredPosts[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildPostCard(doc.id, data, index);
            },
            childCount: filteredPosts.length,
          ),
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
    final l10n = AppLocalizations.of(context);
    final timeAgo = timestamp != null ? _getTimeAgoLocalized(timestamp.toDate(), l10n) : '';
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailsPage(postId: postId, postData: data),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.08) ?? Colors.grey.withOpacity(0.08),
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
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: theme.colorScheme.surface,
                              child: Icon(Icons.image_not_supported, size: 40, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surface,
                            child: Icon(Icons.image, size: 40, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
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
                    top: 8,
                    right: 8,
                    child: FavoriteButton(
                      productId: postId,
                      productData: {
                        'title': data['name'],
                        'image': data['imageUrl'],
                        'price': data['price'],
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$price JD",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: 9, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6)),
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
                        style: TextStyle(fontSize: 9, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    final theme = Theme.of(context);
    switch (condition.toLowerCase()) {
      case 'new':
        return AppTheme.success;
      case 'excellent':
        return AppTheme.info;
      case 'good':
        return const Color(0xFFFF9800);
      case 'fair':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getTimeAgoLocalized(DateTime dateTime, AppLocalizations? l10n) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return l10n?.daysAgo(difference.inDays) ?? '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return l10n?.hoursAgo(difference.inHours) ?? '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return l10n?.minutesAgo(difference.inMinutes) ?? '${difference.inMinutes}m ago';
    } else {
      return l10n?.justNow ?? 'Just now';
    }
  }

  void _showAdvancedSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Advanced Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDropdown('Category', kAppCategories.map((cat) => cat['label'] as String).toList(), filterCategory, (val) => setState(() => filterCategory = val)),
                const SizedBox(height: 12),
                _buildDropdown('Faculty', faculties, filterFaculty, (val) => setState(() => filterFaculty = val)),
                const SizedBox(height: 12),
                _buildDropdown('Condition', conditions, filterCondition, (val) => setState(() => filterCondition = val)),
                const SizedBox(height: 12),
                _buildDropdown('Study Year', studyYears, filterYear, (val) => setState(() => filterYear = val)),
                const SizedBox(height: 12),
                TextField(
                  controller: filterSubjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  onChanged: (val) => filterSubject = val,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filterMinPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min Price'),
                        onChanged: (val) => filterMinPrice = double.tryParse(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: filterMaxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Price'),
                        onChanged: (val) => filterMaxPrice = double.tryParse(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Apply filters
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            filterCategory = null;
                            filterFaculty = null;
                            filterCondition = null;
                            filterYear = null;
                            filterSubject = null;
                            filterMinPrice = null;
                            filterMaxPrice = null;
                            filterSubjectController.clear();
                            filterMinPriceController.clear();
                            filterMaxPriceController.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected, ValueChanged<String?>? onChanged) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: selected,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('All $label'),
        ),
        ...items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: FutureBuilder<List<DocumentSnapshot>>(
        future: getCombinedRecommendations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox();
          }

          final products = snapshot.data!;
          return SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final data = products[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsPage(
                          postId: products[index].id,
                          postData: data,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: data['imageUrl'] != null
                              ? Image.network(
                                  data['imageUrl'],
                                  height: 100,
                                  width: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      width: 140,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error_outline, color: Colors.grey),
                                    );
                                  },
                                )
                              : Container(
                                  height: 100,
                                  width: 140,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['price']} JD',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularProductsGrid() {
    final query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('views', descending: true)
        .limit(6);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('Error loading popular products')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildPostCard(doc.id, data, index);
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }
}
// Helper function for recommendations - يجب إضافته في ملف منفصل أو هنا
Future<List<DocumentSnapshot>> getCombinedRecommendations(String userId) async {
  try {
    // Get user's favorite categories and recent activity
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      // Return recent popular products if no user data
      final recentQuery = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      return recentQuery.docs;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final favoriteCategories = List<String>.from(userData['favoriteCategories'] ?? []);

    if (favoriteCategories.isEmpty) {
      // Return recent products if no favorite categories
      final recentQuery = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      return recentQuery.docs;
    }

    // Get products from favorite categories
    final recommendations = <DocumentSnapshot>[];
    for (final category in favoriteCategories.take(3)) {
      final categoryQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      recommendations.addAll(categoryQuery.docs);
    }

    return recommendations.take(10).toList();
  } catch (e) {
    print('Error getting recommendations: $e');
    return [];
  }
}

// Helper extension for category/condition translation
extension AppLocalizationsCategory on AppLocalizations {
  String translateCategory(String label) {
    switch (label) {
      case 'Books':
        return books;
      case 'Clothes':
        return clothes;
      case 'Electronics':
        return electronics;
      case 'Tools':
        return engineeringTools;
      case 'Medical Equipment':
        return medicalEquipment;
      case 'Medical':
        return dentalEquipment;
      case 'Arts':
        return artsCrafts;
      case 'Lab Coats':
        return labCoats;
      case 'Graduation Robes':
        return graduationRobes;
      case 'Furniture':
        return furniture;
      case 'Other':
        return other;
      case 'All':
        return all;
      default:
        return label;
    }
  }

  String translateCondition(String label) {
    switch (label.toLowerCase()) {
      case 'new':
        return new_;
      case 'excellent':
        return excellent;
      case 'good':
        return good;
      case 'fair':
        return fair;
      case 'used':
        return used;
      case 'like new':
        return likeNew;
      default:
        return label;
    }
  }
}
