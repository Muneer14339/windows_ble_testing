import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/qa_state.dart';

class TestingView extends StatelessWidget {
  final QaTestPhase phase;
  final String statusMessage;
  final double progress;
  final int connectedDeviceCount;

  const TestingView({
    super.key,
    required this.phase,
    required this.statusMessage,
    required this.progress,
    required this.connectedDeviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(40),
          decoration: AppDecorations.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildStatus(),
              const SizedBox(height: 24),
              _buildDeviceCount(),
              const SizedBox(height: 24),
              if (phase == QaTestPhase.testing) _buildProgressBar(),
              if (phase == QaTestPhase.settling || phase == QaTestPhase.evaluating)
                _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (phase) {
      case QaTestPhase.settling:
        icon = Icons.tune;
        break;
      case QaTestPhase.testing:
        icon = Icons.analytics_outlined;
        break;
      case QaTestPhase.evaluating:
        icon = Icons.assessment_outlined;
        break;
      default:
        icon = Icons.sensors;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blueWithOpacity(0.3),
                  AppColors.blueWithOpacity(0.0),
                ],
              ),
              border: Border.all(
                color: AppColors.blueWithOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 56, color: AppColors.blue),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    String title;
    switch (phase) {
      case QaTestPhase.settling:
        title = 'Sensor Calibration';
        break;
      case QaTestPhase.testing:
        title = 'Data Collection';
        break;
      case QaTestPhase.evaluating:
        title = 'Analyzing Results';
        break;
      default:
        title = 'Testing';
    }

    return Text(
      title,
      style: AppTextStyles.heading,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatus() {
    return Text(
      statusMessage,
      style: AppTextStyles.body.copyWith(
        color: AppColors.whiteWithOpacity(0.7),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDeviceCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppDecorations.statusBadge(AppColors.blue),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.devices, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Text(
            '$connectedDeviceCount Device${connectedDeviceCount != 1 ? 's' : ''} Connected',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 40,
                fontWeight: FontWeight.bold,
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
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Collecting sensor data...',
          style: TextStyle(
            color: AppColors.whiteWithOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          phase == QaTestPhase.settling
              ? 'Stabilizing sensors...'
              : 'Processing data...',
          style: TextStyle(
            color: AppColors.whiteWithOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}