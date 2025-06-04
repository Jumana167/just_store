import 'package:flutter/material.dart';
import '../app_theme.dart';

// قائمة الكاتيجوري الموحدة للتطبيق
const List<Map<String, dynamic>> kAppCategories = [
  {
    'label': 'All',
    'icon': Icons.apps,
    'color': AppTheme.primaryBlue,
    'subcategories': [],
  },
  {
    'label': 'Books',
    'icon': Icons.book,
    'color': AppTheme.info,
    'subcategories': ['Textbooks', 'Novels', 'Academic', 'Other'],
  },
  {
    'label': 'Electronics',
    'icon': Icons.devices_other,
    'color': AppTheme.warning,
    'subcategories': ['Laptops', 'Phones', 'Accessories', 'Other'],
  },
  {
    'label': 'Clothes',
    'icon': Icons.checkroom,
    'color': AppTheme.success,
    'subcategories': ['Men', 'Women', 'Kids', 'Other'],
  },
  {
    'label': 'Engineering Tools',
    'icon': Icons.engineering,
    'color': AppTheme.accentBlue,
    'subcategories': ['Mechanical', 'Electrical', 'Civil', 'Other'],
  },
  {
    'label': 'Dental Equipment',
    'icon': Icons.medical_services,
    'color': AppTheme.error,
    'subcategories': ['Instruments', 'Materials', 'Other'],
  },
  {
    'label': 'Arts & Crafts',
    'icon': Icons.brush,
    'color': AppTheme.mediumGrey,
    'subcategories': ['Paintings', 'Sculptures', 'Handmade', 'Other'],
  },
];
