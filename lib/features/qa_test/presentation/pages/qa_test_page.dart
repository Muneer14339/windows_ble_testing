import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF0A0E27),
      body: BlocConsumer<QaBloc, QaState>(
        listener: (context, state) {
          if (state.phase == QaTestPhase.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, state),
                    Expanded(
                      child: _buildContent(context, state),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A1F3A),
            const Color(0xFF0A0E27),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, QaState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IMU QA Tester',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _getSubtitle(state.phase),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.close, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
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
        );
      case QaTestPhase.completed:
        return ResultsView(results: state.results);
      case QaTestPhase.error:
        return _buildErrorView(state);
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildErrorView(QaState state) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.read<QaBloc>().add(ResetTestEvent()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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