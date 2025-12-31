import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnimatedIconWidget extends StatefulWidget {
  final IconData icon;
  final AnimationType animationType;

  const AnimatedIconWidget({
    super.key,
    required this.icon,
    this.animationType = AnimationType.rotate,
  });

  @override
  State<AnimatedIconWidget> createState() => _AnimatedIconWidgetState();
}

class _AnimatedIconWidgetState extends State<AnimatedIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationType == AnimationType.rotate
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: widget.animationType == AnimationType.rotate
              ? (Matrix4.identity()..rotateZ(_controller.value * 6.283185307179586))
              : (Matrix4.identity()..scale(1.0 + (_controller.value < 0.5
              ? _controller.value * 0.3
              : (1 - _controller.value) * 0.3))),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.blueWithOpacity(0.1),
          border: Border.all(
            color: AppColors.blueWithOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(widget.icon, size: 60, color: AppColors.blue),
      ),
    );
  }
}

enum AnimationType { rotate, pulse }