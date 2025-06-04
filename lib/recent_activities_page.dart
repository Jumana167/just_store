import 'package:flutter/material.dart';
import 'app_theme.dart';

class RecentActivitiesPage extends StatefulWidget {
  const RecentActivitiesPage({super.key});

  @override
  State<RecentActivitiesPage> createState() => _RecentActivitiesPageState();
}

class _RecentActivitiesPageState extends State<RecentActivitiesPage> {
  List<String> orderHistory = List.generate(6, (index) => 'Order #${index + 1}');
  List<String> productHistory = List.generate(6, (index) => 'Product #${index + 1}');

  void _confirmDelete({required String item, required bool isOrder}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete "$item"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isOrder) {
                  orderHistory.remove(item);
                } else {
                  productHistory.remove(item);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
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
        title: const Text('Recent Activities', style: TextStyle(color: AppTheme.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              '🧾 Order History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            ...orderHistory.map((item) => Card(
                  color: isDark ? AppTheme.darkGrey : AppTheme.lightGrey,
                  child: ListTile(
                    title: Text(item, style: TextStyle(color: textColor)),
                    trailing: Icon(Icons.delete, color: AppTheme.error),
                    onTap: () => _confirmDelete(item: item, isOrder: true),
                  ),
                )),
            const SizedBox(height: 30),
            const Text(
              '📦 Products History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),
            ...productHistory.map((item) => Card(
                  color: isDark ? AppTheme.darkGrey : AppTheme.lightGrey,
                  child: ListTile(
                    title: Text(item, style: TextStyle(color: textColor)),
                    trailing: Icon(Icons.delete, color: AppTheme.error),
                    onTap: () => _confirmDelete(item: item, isOrder: false),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
