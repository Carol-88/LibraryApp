import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color.fromARGB(255, 251, 238, 251);
  static const secondary = Color(0xFFEAD7D1);
  static const accent = Color(0xFFDD99BB);
  static const dark = Color(0xFF7B506F);
  static const background = Color(0xFF1F1A38);
  static const buttons = Color(0xFF65558F);
}

class AppStyles {
  static ThemeData lightTheme({
    required Color backgroundColor,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor ?? AppColors.primary,
        secondary: secondaryColor ?? AppColors.secondary,
        surface: backgroundColor,
        onSurface: Colors.black,
        error: Colors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black54),
        bodySmall: TextStyle(color: Colors.black38),
      ),
    );
  }
}
