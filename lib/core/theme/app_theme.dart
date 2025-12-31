import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1e2a47);
  static const secondary = Color(0xFF2d3f5f);
  static const surface = Color(0xFF243555);
  static const cardGradientStart = Color(0xFF1e2949);
  static const cardGradientEnd = Color(0xFF1a2238);

  static const blue = Color(0xFF3b82f6);
  static const green = Color(0xFF10b981);
  static const orange = Colors.orange;
  static const red = Color(0xFFef4444);
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
    color: Color(0xFF94a3b8),
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
