import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/app_logo.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';

class InitialScreen extends StatelessWidget {
  final bool isLoading;
  final String language;

  const InitialScreen({
    super.key,
    this.isLoading = false,
    required this.language,
  });

  String _t(String key) => AppTranslations.translate(key, language);

  // lib/features/qa_test/presentation/widgets/initial_screen.dart

  // lib/features/qa_test/presentation/widgets/initial_screen.dart

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 80, withShadow: true),
            const SizedBox(height: 20),
            _buildRulesCard(),
            const SizedBox(height: 20),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _t('rulesTitle'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRule('1.', _t('rule1')),
          _buildRule('2.', _t('rule2')),
          _buildSubRule(_t('rule2Sub1')),
          _buildSubRule(_t('rule2Sub2')),
          _buildRule('3.', _t('rule3')),
          _buildSubRule(_t('rule3Sub1')),
          _buildSubRule(_t('rule3Sub2')),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _t('rulesNote'),
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRule(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number ',
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () => context.read<QaBloc>().add(const StartTestEvent()),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        disabledBackgroundColor: AppColors.blueWithOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _t('startBtn'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
