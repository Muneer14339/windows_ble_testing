import 'package:flutter/material.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';

class ScanningView extends StatelessWidget {
  final List<BleDeviceInfo> foundDevices;
  final String language;
  final bool isConnecting;

  const ScanningView({
    super.key,
    required this.foundDevices,
    required this.language,
    this.isConnecting = false,
  });

  String _t(String key) => AppTranslations.translate(key, language);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(50),
          decoration: AppDecorations.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 30),
              Text(
                isConnecting ? _t('connectingTitle') : _t('scanningTitle'),
                style: AppTextStyles.heading.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isConnecting ? _t('connectingSubtitle') : _t('scanningSubtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.whiteWithOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (foundDevices.isNotEmpty) ...[
                const SizedBox(height: 30),
                _buildDevicesList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
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
      child: Icon(
        isConnecting ? Icons.link : Icons.radar,
        size: 60,
        color: AppColors.blue,
      ),
    );
  }

  Widget _buildDevicesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueWithOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            _t('foundDevices'),
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...foundDevices.map((device) => _buildDeviceItem(device)),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(BleDeviceInfo device) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.bluetooth, color: AppColors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  device.address,
                  style: TextStyle(
                    color: AppColors.whiteWithOpacity(0.5),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
        ],
      ),
    );
  }
}
