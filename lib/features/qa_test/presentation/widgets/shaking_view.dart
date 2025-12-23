import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ShakingView extends StatelessWidget {
  final String statusMessage;
  final double progress;
  final bool isShaking;

  const ShakingView({
    super.key,
    required this.statusMessage,
    required this.progress,
    required this.isShaking,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(40),
          decoration: AppDecorations.cardDecoration(
            borderColor: isShaking
                ? AppColors.greenWithOpacity(0.4)
                : AppColors.redWithOpacity(0.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(isShaking),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildStatus(isShaking),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 24),
              _buildWarning(isShaking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool shaking) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(shaking),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: shaking
              ? Offset((value * 10 - 5) * (value < 0.5 ? 1 : -1), 0)
              : Offset.zero,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (shaking ? AppColors.green : AppColors.red).withOpacity(0.3),
                  (shaking ? AppColors.green : AppColors.red).withOpacity(0.0),
                ],
              ),
              border: Border.all(
                color: (shaking ? AppColors.green : AppColors.red).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              shaking ? Icons.vibration : Icons.pan_tool,
              size: 56,
              color: shaking ? AppColors.green : AppColors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Shake Calibration',
      style: AppTextStyles.heading,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatus(bool shaking) {
    return Text(
      statusMessage,
      style: AppTextStyles.body.copyWith(
        color: shaking ? AppColors.green : AppColors.red,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressBar() {
    final remainingSeconds = ((1.0 - progress) * 30).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$remainingSeconds',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' seconds',
              style: TextStyle(
                color: AppColors.whiteWithOpacity(0.5),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.whiteWithOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isShaking ? AppColors.green : AppColors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarning(bool shaking) {
    if (shaking) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redWithOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.redWithOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please shake the device vigorously to calibrate the sensors',
              style: TextStyle(
                color: AppColors.whiteWithOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}