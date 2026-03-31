import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme lightTheme()=>GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF374151)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF6B7280)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
    )
  );

  static TextTheme darkTheme()=> GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium:TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFF9FAFB)),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF3F4F6)),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFD1D5DB)),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFD1D5DB)),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF9CA3AF)),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: Colors.white),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),
      )
  );
}
