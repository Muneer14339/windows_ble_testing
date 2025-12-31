import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import 'animated_icon_widget.dart';

class CalibrationView extends StatelessWidget {
  final String language;

  const CalibrationView({super.key, required this.language});

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
                child: const AnimatedIconWidget(
                  icon: Icons.tune,
                  animationType: AnimationType.pulse,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _t('calibrationTitle'),
                style: AppTextStyles.heading.copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _t('calibrationSubtitle'),
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.whiteWithOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
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
                _t('calibratingMsg'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.whiteWithOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
