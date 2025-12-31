import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../bloc/qa_state.dart';

class TestingView extends StatelessWidget {
  final QaTestPhase phase;
  final double progress;
  final int sampleCount;
  final String macAddress;
  final String language;

  const TestingView({
    super.key,
    required this.phase,
    required this.progress,
    required this.sampleCount,
    required this.macAddress,
    required this.language,
  });

  String _t(String key, {List<String>? args}) => 
      AppTranslations.translate(key, language, args: args);

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    final isEvaluating = phase == QaTestPhase.evaluating;

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
              Container(
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
                child: const Icon(Icons.analytics_outlined, size: 60, color: AppColors.blue),
              ),
              const SizedBox(height: 30),
              Text(
                _t('dataCollectionTitle'),
                style: AppTextStyles.heading.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _t('dataCollectionSubtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.whiteWithOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!isEvaluating) ...[
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.whiteWithOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.whiteWithOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _t('samples'),
                        style: TextStyle(
                          color: AppColors.whiteWithOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        macAddress.length > 17
                            ? '${macAddress.substring(macAddress.length - 8)}: $sampleCount'
                            : '$macAddress: $sampleCount',
                        style: TextStyle(
                          color: sampleCount > 0 ? AppColors.green : AppColors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _t('evaluating'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.whiteWithOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
