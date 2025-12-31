import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';
import 'device_list_widget.dart';

class ResultsFailView extends StatelessWidget {
  final QaResult result;
  final int attemptNumber;
  final String language;

  const ResultsFailView({
    super.key,
    required this.result,
    required this.attemptNumber,
    required this.language,
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
          decoration: AppDecorations.cardDecoration(
            borderColor: AppColors.redWithOpacity(0.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 80, color: AppColors.red),
              const SizedBox(height: 24),
              Text(
                _t('testFailTitle'),
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${_t('testedDevicesFail')} $attemptNumber',
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
                  _t('failStatus'),
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                language == 'zh' 
                    ? '第 $attemptNumber 次尝试失败'
                    : 'Failed on attempt $attemptNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              _buildFailureDetails(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.read<QaBloc>().add(const RetryTestEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '${_t('retryBtn')} (${attemptNumber + 1}/3)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // build method mein Column ke children mein add karo after button
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
                devices: context.read<QaBloc>().state.badDevices,
                isPassed: false,
                language: language,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redWithOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.redWithOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.failureReason.label,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (result.saturationCount > 0)
                _buildMetric('Saturations', '${result.saturationCount}'),
              if (result.spikeCount > 0)
                _buildMetric('Spikes', '${result.spikeCount}'),
              _buildMetric('Max Raw', '${result.maxAbsRaw}'),
              _buildMetric('Max Δ', '${result.maxDelta}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteWithOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.whiteWithOpacity(0.5),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
