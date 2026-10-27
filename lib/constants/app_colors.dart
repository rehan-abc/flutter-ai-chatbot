import 'package:flutter/material.dart';

/// App color palette for consistent styling across the application
class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF4A80F0);
  static const Color primaryDark = Color(0xFF2C56B5);
  static const Color primaryLight = Color(0xFFEBF1FF);
  
  // Backgrounds
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;
  
  // Chat Bubble colors
  static const Color userBubble = Color(0xFF4A80F0);
  static const Color userBubbleText = Colors.white;
  static const Color botBubble = Color(0xFFF0F2F6);
  static const Color botBubbleText = Color(0xFF1E293B);

  // Status & Feedback
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);

  // Neutral tones
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}
