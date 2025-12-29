import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF6C5CE7);      // Purple
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF5849C2);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00CEC9);    // Teal
  static const Color secondaryLight = Color(0xFF81ECEC);
  
  // Accent Colors
  static const Color accent = Color(0xFFFF7675);       // Coral
  static const Color accentYellow = Color(0xFFFDCB6E); // Yellow
  static const Color accentGreen = Color(0xFF00B894);  // Green
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FD);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F8);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  
  // Other
  static const Color divider = Color(0xFFE8ECF4);
  static const Color disabled = Color(0xFFDFE6E9);
  static const Color shimmerBase = Color(0xFFE8ECF4);
  static const Color shimmerHighlight = Color(0xFFF8F9FD);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8E7CF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, Color(0xFF55EFC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF7675), Color(0xFFFFAB91)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Score Colors
  static Color getScoreColor(int score) {
    if (score >= 80) return success;
    if (score >= 60) return accentYellow;
    if (score >= 40) return warning;
    return error;
  }
}
