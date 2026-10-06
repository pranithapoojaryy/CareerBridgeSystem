import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6EC9F5);
  static const Color secondaryColor = Color(0xFF4A90E2);
  static const Color accentColor = Color(0xFFD67BFF); // Purple accent color
  static const Color textColor = Color(0xFF2D3748);
  static const Color backgroundColor = Color(0xFFF7FAFC);

  // Additional properties for login screen
  static BoxDecoration get gradientBackground => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withValues(alpha: 0.1),
        secondaryColor.withValues(alpha: 0.05),
      ],
    ),
  );

  static BoxDecoration get clayDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, color: textColor),
      ),
    );
  }
}
