import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/qa_bloc.dart';
import '../bloc/qa_event.dart';

class ResultsView extends StatelessWidget {
  final List<QaResult> results;

  const ResultsView({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final passCount = results.where((r) => r.status == QaStatus.pass).length;
    final warnCount = results.where((r) => r.status == QaStatus.warn).length;
    final failCount = results.where((r) => r.status == QaStatus.fail).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    _buildSummaryCard(passCount, warnCount, failCount),
                    const SizedBox(height: 24),
                    _buildResultsList(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildSummaryCard(int pass, int warn, int fail) {
    final total = results.length;
    final overallStatus = fail > 0
        ? QaStatus.fail
        : warn > 0
        ? QaStatus.warn
        : QaStatus.pass;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppDecorations.cardDecoration(borderColor: overallStatus.color.withOpacity(0.3)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overallStatus.icon,
            size: 64,
            color: overallStatus.color,
          ),
          const SizedBox(height: 20),
          const Text(
            'Test Complete',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tested $total device${total != 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.whiteWithOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildStatusBadge('Pass', pass, AppColors.green),
              _buildStatusBadge('Warn', warn, AppColors.orange),
              _buildStatusBadge('Fail', fail, AppColors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppDecorations.statusBadge(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.blueWithOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Device Results',
              style: AppTextStyles.heading.copyWith(fontSize: 20),
            ),
          ),
          Divider(color: AppColors.whiteWithOpacity(0.12), height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.whiteWithOpacity(0.12),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultItem(result, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(QaResult result, int number) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: AppDecorations.statusBadge(result.status.color),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: result.status.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.deviceId,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppDecorations.statusBadge(result.status.color),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      result.status.icon,
                      color: result.status.color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      result.status.label,
                      style: TextStyle(
                        color: result.status.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip('Gravity', '${result.gravityMeanG.toStringAsFixed(3)}g'),
              _buildMetricChip('MAC', '${result.macDeg.toStringAsFixed(3)}°'),
              _buildMetricChip('Noise σ', '${result.noiseSigma.toStringAsFixed(3)}°'),
              _buildMetricChip('Drift', '${result.driftDegPerMin.toStringAsFixed(3)}°/min'),
              _buildMetricChip('Abnormal', '${result.abnormalCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteWithOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.whiteWithOpacity(0.1),
          width: 1,
        ),
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
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.blueWithOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.read<QaBloc>().add(ResetTestEvent()),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Test Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}