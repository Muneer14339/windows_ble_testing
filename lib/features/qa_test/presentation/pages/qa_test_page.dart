import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';
import '../bloc/qa_state.dart';
import '../widgets/device_input_card.dart';
import '../widgets/scanning_view.dart';
import '../widgets/testing_view.dart';
import '../widgets/results_view.dart';

class QaTestPage extends StatefulWidget {
  const QaTestPage({super.key});

  @override
  State<QaTestPage> createState() => _QaTestPageState();
}

class _QaTestPageState extends State<QaTestPage> {
  @override
  void initState() {
    super.initState();
    context.read<QaBloc>().add(InitializeQaEvent());
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
        },
        builder: (context, state) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.primary,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, state),
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

  Widget _buildAppBar(BuildContext context, QaState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blueWithOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.blueWithOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IMU QA Tester',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _getSubtitle(state.phase),
                  style: TextStyle(
                    color: AppColors.whiteWithOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (state.phase != QaTestPhase.idle &&
              state.phase != QaTestPhase.completed)
            _buildCancelButton(context),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<QaBloc>().add(CancelTestEvent()),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.redWithOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.redWithOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: AppColors.red, size: 18),
              SizedBox(width: 6),
              Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, QaState state) {
    switch (state.phase) {
      case QaTestPhase.idle:
      case QaTestPhase.initializing:
        return DeviceInputCard(
          isLoading: state.phase == QaTestPhase.initializing,
        );
      case QaTestPhase.scanning:
      case QaTestPhase.connecting:
        return ScanningView(
          targetCount: state.targetDeviceCount,
          foundDevices: state.foundDevices,
          phase: state.phase,
          statusMessage: state.statusMessage,
        );
      case QaTestPhase.settling:
      case QaTestPhase.testing:
      case QaTestPhase.evaluating:
        return TestingView(
          phase: state.phase,
          statusMessage: state.statusMessage,
          progress: state.progress,
          connectedDeviceCount: state.connectedDevices.length,
          deviceSampleCounts: state.sampleCounts.isNotEmpty ? state.sampleCounts : null,
        );
      case QaTestPhase.completed:
        return ResultsView(results: state.results);
      case QaTestPhase.error:
        return _buildErrorView(state);
    }
  }

  Widget _buildErrorView(QaState state) {
    return Center(
      child: SingleChildScrollView(
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
              const Text(
                'Error',
                style: TextStyle(
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
                onPressed: () => context.read<QaBloc>().add(ResetTestEvent()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(QaTestPhase phase) {
    switch (phase) {
      case QaTestPhase.idle:
        return 'Ready to start testing';
      case QaTestPhase.initializing:
        return 'Initializing system...';
      case QaTestPhase.scanning:
        return 'Scanning for devices';
      case QaTestPhase.connecting:
        return 'Establishing connections';
      case QaTestPhase.settling:
        return 'Calibrating sensors';
      case QaTestPhase.testing:
        return 'Running test sequence';
      case QaTestPhase.evaluating:
        return 'Analyzing results';
      case QaTestPhase.completed:
        return 'Test complete';
      case QaTestPhase.error:
        return 'Error occurred';
    }
  }
}