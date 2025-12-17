import 'package:flutter/material.dart';
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E2749),
              const Color(0xFF151B35),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 32),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildStatus(),
            const SizedBox(height: 32),
            _buildDeviceCount(),
            const SizedBox(height: 32),
            if (phase == QaTestPhase.testing) _buildProgressBar(),
            if (phase == QaTestPhase.settling || phase == QaTestPhase.evaluating)
              _buildLoadingIndicator(),
          ],
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.0),
                ],
              ),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 64, color: Colors.blue),
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatus() {
    return Text(
      statusMessage,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 18,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDeviceCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.devices, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Text(
            '$connectedDeviceCount Device${connectedDeviceCount != 1 ? 's' : ''} Connected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Collecting sensor data...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          phase == QaTestPhase.settling
              ? 'Stabilizing sensors...'
              : 'Processing data...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}