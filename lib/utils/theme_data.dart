import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.cardColorLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textColorLight),
      bodyLarge: TextStyle(color: AppColors.textColorLight),
      titleMedium: TextStyle(color: AppColors.textColorLight),
      titleLarge: TextStyle(color: AppColors.textColorLight),
    ),
    dividerColor: Colors.grey.shade300,
    iconTheme: const IconThemeData(color: AppColors.primaryColor),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primaryColorDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardColorDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryColorDark,
      secondary: AppColors.secondaryColorDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColorDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textColorDark),
      bodyLarge: TextStyle(color: AppColors.textColorDark),
      titleMedium: TextStyle(color: AppColors.textColorDark),
      titleLarge: TextStyle(color: AppColors.textColorDark),
    ),
    dividerColor: Colors.grey.shade800,
    iconTheme: const IconThemeData(color: AppColors.primaryColorDark),
  );
}