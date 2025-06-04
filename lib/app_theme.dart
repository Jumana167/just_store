// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية للتطبيق
  static const Color primaryBlue = Color(0xFF1976D2);  // أزرق فاتح
  static const Color accentBlue = Color(0xFF42A5F5);   // أزرق متوسط
  static const Color success = Color(0xFF4CAF50);      // أخضر للنجاح
  static const Color info = Color(0xFF2196F3);         // أزرق للمعلومات
  static const Color warning = Color(0xFFFFC107);      // أصفر للتحذير
  static const Color error = Color(0xFFF44336);        // أحمر للخطأ
  static const Color white = Color(0xFFFFFFFF);        // أبيض
  static const Color black = Color(0xFF000000);        // أسود
  static const Color darkGrey = Color(0xFF2C3E50);     // رمادي داكن
  static const Color mediumGrey = Color(0xFF7F8C8D);   // رمادي متوسط
  static const Color lightGrey = Color(0xFFF8FAFB);    // رمادي فاتح
  static const Color borderGrey = Color(0xFFE0E0E0);   // رمادي للحدود

  // الألوان المحايدة
  static const Color gradientStart = Color(0xFF3891D6); // بداية التدرج
  static const Color gradientEnd = Color(0xFF170557);   // نهاية التدرج

  // التدرجات
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [primaryBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // النمط الفاتح
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primarySwatch: createMaterialColor(primaryBlue),
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: white),
    ),
    cardTheme: CardTheme(
      color: white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: white,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkGrey,
      onError: white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkGrey),
      bodyMedium: TextStyle(color: darkGrey),
      titleLarge: TextStyle(color: darkGrey),
    ),
  );

  // النمط المظلم
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primarySwatch: createMaterialColor(primaryBlue),
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: white),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2D2D2D),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black26,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: Color(0xFF2D2D2D),
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: white,
      onError: white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: white),
      bodyMedium: TextStyle(color: white),
      titleLarge: TextStyle(color: white),
    ),
  );

  // مساعد لإنشاء MaterialColor من Color
  static MaterialColor createMaterialColor(Color color) {
    final List<int> strengths = <int>[50];
    final Map<int, Color> swatch = {};
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(i * 100);
    }

    for (final strength in strengths) {
      final double ds = 0.5 - (strength / 1000);
      final int r1 = (r + ((ds < 0 ? r : (255 - r)) * ds)).round();
      final int g1 = (g + ((ds < 0 ? g : (255 - g)) * ds)).round();
      final int b1 = (b + ((ds < 0 ? b : (255 - b)) * ds)).round();
      swatch[strength] = Color.fromRGBO(r1, g1, b1, 1);
    }

    return MaterialColor(color.value, swatch);
  }

  // Helper methods for colors
  static Color withOpacity(Color color, double opacity) {
    final int alpha = (opacity * 255).round();
    return Color.fromARGB(alpha, color.red, color.green, color.blue);
  }
}

// مكونات UI مخصصة
class AppWidgets {
  // AppBar موحد
  static AppBar buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      backgroundColor: AppTheme.primaryBlue,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: AppTheme.white),
      elevation: 0,
    );
  }

  // زر أساسي موحد
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    double? width,
    IconData? icon,
  }) {
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.withOpacity(AppTheme.primaryBlue, 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppTheme.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // زر ثانوي موحد
  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
    IconData? icon,
  }) {
    return Container(
      width: width,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}