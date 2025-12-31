import 'package:flutter/material.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';

class DeviceListWidget extends StatelessWidget {
  final String title;
  final List<dynamic> devices;
  final bool isPassed;
  final String language;

  const DeviceListWidget({
    super.key,
    required this.title,
    required this.devices,
    required this.isPassed,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isPassed ? AppColors.greenWithOpacity(0.1) : AppColors.redWithOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPassed ? AppColors.greenWithOpacity(0.3) : AppColors.redWithOpacity(0.3)),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isPassed ? AppColors.green : AppColors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...devices.map((device) => _buildDeviceItem(device)),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(dynamic device) {
    final mac = device is QaResult ? device.macAddress : (device as BadDevice).macAddress;
    final name = device is BadDevice ? device.deviceName : 'RA Device';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteWithOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isPassed ? AppColors.greenWithOpacity(0.2) : AppColors.redWithOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.error,
            color: isPassed ? AppColors.green : AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  mac,
                  style: TextStyle(
                    color: AppColors.whiteWithOpacity(0.5),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}