import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0A0E27);
  static const secondary = Color(0xFF1A1F3A);
  static const surface = Color(0xFF151B35);
  static const cardGradientStart = Color(0xFF1E2749);
  static const cardGradientEnd = Color(0xFF151B35);

  static const blue = Colors.blue;
  static const green = Colors.green;
  static const orange = Colors.orange;
  static const red = Colors.red;
  static const white = Colors.white;

  static Color blueWithOpacity(double opacity) => blue.withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) => white.withOpacity(opacity);
  static Color greenWithOpacity(double opacity) => green.withOpacity(opacity);
  static Color orangeWithOpacity(double opacity) => orange.withOpacity(opacity);
  static Color redWithOpacity(double opacity) => red.withOpacity(opacity);
}

class AppTextStyles {
  static const title = TextStyle(
    color: AppColors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    letterSpacing: 0.3,
  );

  static const heading = TextStyle(
    color: AppColors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const body = TextStyle(
    fontSize: 16,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

class AppDecorations {
  static BoxDecoration cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor ?? AppColors.blueWithOpacity(0.2),
        width: 2,
      ),
    );
  }

  static BoxDecoration statusBadge(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 2,
      ),
    );
  }
}