import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';
import 'device_list_widget.dart';

class ResultsBadView extends StatelessWidget {
  final QaResult result;
  final List<BadDevice> badDevices;
  final String language;

  const ResultsBadView({
    super.key,
    required this.result,
    required this.badDevices,
    required this.language,
  });

  String _t(String key) => AppTranslations.translate(key, language);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(50),
              decoration: AppDecorations.cardDecoration(
                borderColor: AppColors.redWithOpacity(0.4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dangerous, size: 80, color: AppColors.red),
                  const SizedBox(height: 24),
                  Text(
                    _t('badSensorTitle'),
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t('failedAttempts'),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.whiteWithOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: AppDecorations.statusBadge(AppColors.red),
                    child: Text(
                      _t('badStatus'),
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('attemptInfoBad'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.read<QaBloc>().add(const DiscardDeviceEvent()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _t('discardBtn'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DeviceListWidget(
              title: _t('passedDevicesTitle'),
              devices: context.read<QaBloc>().state.passedDevices,
              isPassed: true,
              language: language,
            ),
            const SizedBox(height: 16),
            DeviceListWidget(
              title: _t('failedDevicesTitle'),
              devices: badDevices,
              isPassed: false,
              language: language,
            ),
            // if (badDevices.isNotEmpty) ...[
            //   const SizedBox(height: 24),
            //   _buildBadDevicesList(),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadDevicesList() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.redWithOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.redWithOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('badListTitle'),
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...badDevices.map((device) => _buildBadDeviceItem(device)),
        ],
      ),
    );
  }

  Widget _buildBadDeviceItem(BadDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteWithOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.redWithOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppColors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  device.macAddress,
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
