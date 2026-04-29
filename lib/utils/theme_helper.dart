import 'package:flutter/material.dart';

class ThemeHelper {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color background(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF121212) 
        : const Color(0xFFF5F5F5);
  }

  static Color surface(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF1E1E1E) 
        : Colors.white;
  }

  static Color card(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF2C2C2C) 
        : Colors.white;
  }

  static Color textPrimary(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFFE0E0E0) 
        : const Color(0xFF212121);
  }

  static Color textSecondary(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF9E9E9E) 
        : const Color(0xFF757575);
  }

  static Color divider(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF424242) 
        : const Color(0xFFE0E0E0);
  }

  static Color icon(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFFBDBDBD) 
        : const Color(0xFF757575);
  }

  static Color scaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color appBarBackground(BuildContext context) {
    return isDarkMode(context) 
        ? const Color(0xFF1E1E1E) 
        : Colors.white;
  }
}
