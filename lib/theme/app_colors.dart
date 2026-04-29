import 'package:flutter/material.dart';

class AppColors {
  // ========== LIGHT MODE ==========
  
  // Màu chủ đạo (Primary)
  static const Color primary = Color(0xFF2E7D32); // Xanh lá cây đậm
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Màu phụ (Secondary)
  static const Color secondary = Color(0xFF81C784); // Xanh lá nhạt
  static const Color accent = Color(0xFFFFC107); // Vàng để nhấn mạnh

  // Màu nền (Background)
  static const Color background = Color(0xFFF5F5F5); // Xám nhạt
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Màu chữ (Text)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Trạng thái (Status)
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // ========== DARK MODE ==========
  
  // Màu nền Dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  
  // Màu chữ Dark
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  
  // Màu border/divider Dark
  static const Color darkBorder = Color(0xFF424242);
  
  // Icon màu nhạt cho dark mode
  static const Color darkIcon = Color(0xFFBDBDBD);
}
