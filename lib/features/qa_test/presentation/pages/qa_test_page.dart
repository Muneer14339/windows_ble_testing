import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/app_logo.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';
import '../bloc/qa_state.dart';
import '../widgets/initial_screen.dart';
import '../widgets/scanning_view.dart';
import '../widgets/calibration_view.dart';
import '../widgets/testing_view.dart';
import '../widgets/results_pass_view.dart';
import '../widgets/results_fail_view.dart';
import '../widgets/results_bad_view.dart';
import '../widgets/stop_modal.dart';

class QaTestPage extends StatefulWidget {
  const QaTestPage({super.key});

  @override
  State<QaTestPage> createState() => _QaTestPageState();
}

class _QaTestPageState extends State<QaTestPage> {
  @override
  void initState() {
    super.initState();
    context.read<QaBloc>().add(const InitializeQaEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocConsumer<QaBloc, QaState>(
        listener: (context, state) {
          if (state.phase == QaTestPhase.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: AppColors.red,
              ),
            );
          }

          if (state.toastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.toastMessage!),
                backgroundColor: AppColors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            context.read<QaBloc>().add(const ResetTestEvent());
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.primary,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, state),
                  Expanded(
                    child: _buildContent(context, state),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, QaState state) {
    final t = (String key, {List<String>? args}) =>
        AppTranslations.translate(key, state.currentLanguage, args: args);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App Icon & Title
          const AppLogo(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('appTitle'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getSubtitle(state, t),
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          // Language Toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.read<QaBloc>().add(const ToggleLanguageEvent()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.blueWithOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.blueWithOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  t('langSwitch'),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Stop Button (visible during test)
          if (_shouldShowStopButton(state.phase)) ...[
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showStopModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.redWithOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.redWithOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    t('stopBtn'),
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // lib/features/qa_test/presentation/pages/qa_test_page.dart

  Widget _buildContent(BuildContext context, QaState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: _getScreenWidget(state),
            ),
          ),
        );
      },
    );
  }

  Widget _getScreenWidget(QaState state) {
    switch (state.phase) {
      case QaTestPhase.idle:
      case QaTestPhase.initializing:
        return InitialScreen(
          isLoading: state.phase == QaTestPhase.initializing,
          language: state.currentLanguage,
        );
      case QaTestPhase.scanning:
        return ScanningView(
          foundDevices: state.foundDevices,
          language: state.currentLanguage,
        );
      case QaTestPhase.connecting:
        return ScanningView(
          foundDevices: state.foundDevices,
          language: state.currentLanguage,
          isConnecting: true,
        );
      case QaTestPhase.settling:
        return CalibrationView(language: state.currentLanguage);
      case QaTestPhase.testing:
      case QaTestPhase.evaluating:
        return TestingView(
          phase: state.phase,
          progress: state.progress,
          sampleCount: state.sampleCounts.values.isNotEmpty
              ? state.sampleCounts.values.first
              : 0,
          macAddress: state.connectedDeviceAddress ?? '',
          language: state.currentLanguage,
        );
      case QaTestPhase.completed:
        if (state.currentResult == null) return const SizedBox.shrink();

        if (state.currentResult!.passed) {
          return ResultsPassView(
            result: state.currentResult!,
            language: state.currentLanguage,
          );
        } else {
          return ResultsBadView(
            result: state.currentResult!,
            badDevices: state.badDevices,
            language: state.currentLanguage,
          );
        }
      case QaTestPhase.error:
        return _buildErrorView(state);
    }
  }

  Widget _buildErrorView(QaState state) {
    final t = (String key) =>
        AppTranslations.translate(key, state.currentLanguage);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.redWithOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.redWithOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 56),
              const SizedBox(height: 20),
              Text(
                t('error'),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'An unknown error occurred',
                style: TextStyle(
                  color: AppColors.whiteWithOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<QaBloc>().add(const ResetTestEvent()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  t('testAgainBtn'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(QaState state, String Function(String, {List<String>? args}) t) {
    switch (state.phase) {
      case QaTestPhase.idle:
        return t('headerSubtitle');
      case QaTestPhase.initializing:
        return t('initializing');
      case QaTestPhase.scanning:
        return t('headerSubtitleScanning');
      case QaTestPhase.connecting:
        return t('headerSubtitleConnecting');
      case QaTestPhase.settling:
        return t('headerSubtitleCalibrating');
      case QaTestPhase.testing:
        return t('headerSubtitleCollecting');
      case QaTestPhase.evaluating:
      case QaTestPhase.completed:
        return t('headerSubtitleComplete');
      case QaTestPhase.error:
        return t('error');
    }
  }

  bool _shouldShowStopButton(QaTestPhase phase) {
    return phase != QaTestPhase.idle &&
           phase != QaTestPhase.initializing &&
           phase != QaTestPhase.completed &&
           phase != QaTestPhase.error;
  }

  void _showStopModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<QaBloc>(),
        child: const StopModal(),
      ),
    );
  }
}
