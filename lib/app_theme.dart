// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية للتطبيق
  static const Color primaryBlue = Color(0xFF3B3B98);
  static const Color lightBlue = Color(0xFF1976D2);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF1746A2);
  static const Color gradientStart = Color(0xFF3891D6);
  static const Color gradientEnd = Color(0xFF170557);

  // الألوان المحايدة
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF8FAFB);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color borderGrey = Color(0xFFE0E0E0);

  // الألوان الوظيفية
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5722);
  static const Color info = Color(0xFF2196F3);

  // التدرجات
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [lightBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // النمط الفاتح
  static ThemeData lightTheme = ThemeData(
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
  );

  // النمط المظلم
  static ThemeData darkTheme = ThemeData(
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
  );

  // مساعد لإنشاء MaterialColor من Color
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
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
            color: AppTheme.primaryBlue.withOpacity(0.3),
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