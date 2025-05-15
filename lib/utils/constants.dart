import 'package:flutter/material.dart';



class AppColors {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  static const Color primaryColorDark = Color(0xFF1565C0);
  static const Color secondaryColorDark = Color(0xFF0288D1);
  static const Color accentColorDark = Color(0xFF388E3C);
  static const Color warningColorDark = Color(0xFFFFB300);
  static const Color errorColorDark = Color(0xFFD32F2F);
  static const Color successColorDark = Color(0xFF388E3C);
  static const Color infoColorDark = Color(0xFF1976D2);

  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardColorLight = Colors.white;
  static const Color cardColorDark = Color(0xFF1E1E1E);
  static const Color textColorLight = Colors.black87;
  static const Color textColorDark = Colors.white;


  static const Color scheduledColor = Color(0xFF4CAF50);
  static const Color delayedColor = Color(0xFFFFC107);
  static const Color canceledColor = Color(0xFFF44336);
  static const Color boardingColor = Color(0xFF2196F3);
  static const Color departedColor = Color(0xFF9C27B0);
  static const Color arrivedColor = Color(0xFF795548);
}

class AppTextStyles {
  static const TextStyle headline = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    color: Colors.black87,
  );
}

// Flight Status Colors
Map<String, Color> flightStatusColors = {
  'scheduled': AppColors.scheduledColor,
  'delayed': AppColors.delayedColor,
  'boarding': AppColors.boardingColor,
  'departed': AppColors.departedColor,
  'arrived': AppColors.arrivedColor,
  'canceled': AppColors.canceledColor,
};

// Date Format Utility
String formatDateTime(DateTime dateTime) {
  return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String formatDate(DateTime dateTime) {
  return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

// Form Validators
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }


    return null;
  }
}
// Add class colors
class SeatClassColors {
  static final Color economy = Colors.green;
  static final Color business = Colors.blue;
  static final Color first = Colors.indigo;
  static final Color womanOnly = Colors.pink;
}

// Add a helper function for formatting ticket classes
String formatTicketClass(String ticketClass) {
  switch (ticketClass) {
    case 'economy':
      return 'Economy';
    case 'business':
      return 'Business';
    case 'first':
      return 'First Class';
    case 'woman_only':
      return 'Woman Only';
    default:
      return ticketClass;
  }
}