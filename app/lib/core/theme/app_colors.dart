import 'package:flutter/material.dart';

/// Color palette matching the dark HTML design
class AppColors {
  // Background colors
  static const Color background = Color(0xFF0F172A); // slate-900
  static const Color surface = Color(0xFF1E293B); // slate-800
  
  // Glass morphism backgrounds
  static const Color glass = Color.fromRGBO(30, 41, 59, 0.7); // rgba(30, 41, 59, 0.7)
  static const Color glassLight = Color.fromRGBO(51, 65, 85, 0.5); // rgba(51, 65, 85, 0.5)
  static const Color glassAccent = Color.fromRGBO(99, 102, 241, 0.15); // rgba(99, 102, 241, 0.15)
  
  // Text colors
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFFE2E8F0); // slate-200
  static const Color textTertiary = Color(0xFFCBD5E1); // slate-300
  static const Color textMuted = Color(0xFF94A3B8); // slate-400
  static const Color textDisabled = Color(0xFF64748B); // slate-500
  static const Color textDivider = Color(0xFF475569); // slate-600
  
  // Accent colors
  static const Color indigo = Color(0xFF818CF8); // indigo-400
  static const Color indigoLight = Color(0xFFA5B4FC); // indigo-300
  static const Color indigoDark = Color(0xFF6366F1); // indigo-500
  
  static const Color rose = Color(0xFFFB7185); // rose-400
  static const Color roseLight = Color(0xFFFDA4AF); // rose-300
  
  static const Color emerald = Color(0xFF34D399); // emerald-400
  static const Color emeraldLight = Color(0xFF6EE7B7); // emerald-300
  
  static const Color amber = Color(0xFFFBBF24); // amber-400
  static const Color amberLight = Color(0xFFFCD34D); // amber-300
  
  static const Color purple = Color(0xFFC084FC); // purple-400
  static const Color purpleLight = Color(0xFFD8B4FE); // purple-300
  
  // Borders
  static const Color borderLight = Color.fromRGBO(255, 255, 255, 0.1);
  static const Color borderMedium = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderAccent = Color.fromRGBO(99, 102, 241, 0.3);
  
  // Hover states
  static const Color hoverOverlay = Color.fromRGBO(255, 255, 255, 0.1);
  static const Color hoverSurface = Color.fromRGBO(51, 65, 85, 0.6);
}

