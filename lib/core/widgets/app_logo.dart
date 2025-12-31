import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withShadow;

  const AppLogo({
    super.key,
    this.size = 40,
    this.withShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: withShadow
            ? [
          BoxShadow(
            color: AppColors.blueWithOpacity(0.3),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.1,
          ),
        ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/images/logos/icon_3.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}