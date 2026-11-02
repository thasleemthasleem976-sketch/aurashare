import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF0077B6);
  static const Color primaryDeep = Color(0xFF03045E);
  static const Color accent = Color(0xFF4361EE);
  static const Color accentNeon = Color(0xFF4CC9F0);
  static const Color violet = Color(0xFF7209B7);

  // Dark Palette
  static const Color backgroundDark = Color(0xFF0B111E);
  static const Color surfaceDark = Color(0xFF131D2F);
  static const Color cardDark = Color(0xFF1B273D);
  static const Color borderDark = Color(0xFF283854);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Light Palette
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status & Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color offline = Color(0xFF64748B);
  static const Color online = Color(0xFF10B981);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF4361EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF162035), Color(0xFF1A263E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x3300B4D8), Color(0x114361EE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
