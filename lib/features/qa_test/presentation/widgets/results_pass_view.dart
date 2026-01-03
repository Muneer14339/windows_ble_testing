import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';
import 'device_list_widget.dart';

class ResultsPassView extends StatelessWidget {
  final QaResult result;
  final String language;

  const ResultsPassView({
    super.key,
    required this.result,
    required this.language,
  });

  String _t(String key, {List<String>? args}) => 
      AppTranslations.translate(key, language, args: args);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(50),
          decoration: AppDecorations.cardDecoration(
            borderColor: AppColors.greenWithOpacity(0.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 80, color: AppColors.green),
              const SizedBox(height: 24),
              Text(
                _t('testPassTitle'),
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Replace line ~48:
              Text(
                '${_t('device')} ${result.macAddress} - ${_t('testedDevicesPass')}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.whiteWithOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: AppDecorations.statusBadge(AppColors.green),
                child: Text(
                  _t('passStatus'),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.read<QaBloc>().add(const TestNextDeviceEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _t('testNextBtn'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
}
