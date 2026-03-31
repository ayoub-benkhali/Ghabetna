import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

ThemeData buildTheme(Brightness brightness){
  final isDark=brightness==Brightness.dark;

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: isDark?AppColors.darkBg:AppColors.lightBg,
    textTheme: isDark?AppTypography.darkTheme():AppTypography.lightTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: brightness,
      surface: isDark?AppColors.darkSurface:AppColors.lightSurface
    ),
    cardTheme: CardThemeData(
      elevation: isDark? 0 : 1,
      color: isDark? AppColors.darkSurface:AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:isDark?AppColors.darkBorder:AppColors.lightBorder,
          width:1
        )
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark?AppColors.darkBg:AppColors.lightSurface,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(
        color: isDark?Colors.white:AppColors.darkForest
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark? AppColors.darkSurface: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryGreen,width: 2)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger,width: 1)
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,fontWeight: FontWeight.w600,letterSpacing: 0.3
        )
      )
    ),
    dividerTheme: DividerThemeData(
      color: isDark? AppColors.darkBorder:AppColors.lightBorder,
      thickness: 1
    )
  );
}
