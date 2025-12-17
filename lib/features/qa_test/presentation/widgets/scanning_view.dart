import 'package:flutter/material.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/qa_state.dart';

class ScanningView extends StatelessWidget {
  final int targetCount;
  final List<BleDeviceInfo> foundDevices;
  final QaTestPhase phase;
  final String statusMessage;

  const ScanningView({
    super.key,
    required this.targetCount,
    required this.foundDevices,
    required this.phase,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasEnoughHeight = constraints.maxHeight > 600;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 800,
                minHeight: hasEnoughHeight ? constraints.maxHeight - 48 : 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusCard(),
                  if (foundDevices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDevicesList(constraints.maxHeight),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedIcon(),
          const SizedBox(height: 20),
          Text(
            phase == QaTestPhase.scanning
                ? 'Scanning for Devices'
                : 'Connecting to Devices',
            style: AppTextStyles.heading.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            statusMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.whiteWithOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.blueWithOpacity(0.3),
                  AppColors.blueWithOpacity(0.0),
                ],
              ),
            ),
            child: Icon(
              phase == QaTestPhase.scanning ? Icons.radar : Icons.link,
              size: 48,
              color: AppColors.blue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = foundDevices.length / targetCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${foundDevices.length}',
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / $targetCount',
              style: TextStyle(
                color: AppColors.whiteWithOpacity(0.5),
                fontSize: 28,
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
            minHeight: 8,
            backgroundColor: AppColors.whiteWithOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList(double maxHeight) {
    final listHeight = (maxHeight * 0.4).clamp(200.0, 400.0);

    return Container(
      constraints: BoxConstraints(maxHeight: listHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.2),
          width: 2,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        shrinkWrap: true,
        itemCount: foundDevices.length,
        separatorBuilder: (context, index) => Divider(
          color: AppColors.whiteWithOpacity(0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final device = foundDevices[index];
          return _buildDeviceItem(device, index + 1);
        },
      ),
    );
  }

  Widget _buildDeviceItem(BleDeviceInfo device, int number) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppDecorations.statusBadge(AppColors.blue),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.address,
                  style: TextStyle(
                    color: AppColors.whiteWithOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildSignalStrength(device.rssi),
        ],
      ),
    );
  }

  Widget _buildSignalStrength(int rssi) {
    final strength = rssi >= -50 ? 3 : rssi >= -70 ? 2 : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
            (index) => Container(
          width: 3,
          height: 10 + (index * 3),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: index < strength ? AppColors.blue : AppColors.whiteWithOpacity(0.24),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}