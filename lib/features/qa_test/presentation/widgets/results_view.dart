import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
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
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    _buildSummaryCard(passCount, warnCount, failCount),
                    const SizedBox(height: 32),
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
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2749),
            const Color(0xFF151B35),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getStatusColor(overallStatus).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(overallStatus),
            size: 80,
            color: _getStatusColor(overallStatus),
          ),
          const SizedBox(height: 24),
          Text(
            'Test Complete',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tested $total device${total != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge('Pass', pass, Colors.green),
              const SizedBox(width: 16),
              _buildStatusBadge('Warn', warn, Colors.orange),
              const SizedBox(width: 16),
              _buildStatusBadge('Fail', fail, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 32,
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
        color: const Color(0xFF151B35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Device Results',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white12,
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getStatusColor(result.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(result.status).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: _getStatusColor(result.status),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.deviceId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMetricChip(
                      'Gravity',
                      '${result.gravityMeanG.toStringAsFixed(2)}g',
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      'MAC',
                      '${result.macDeg.toStringAsFixed(3)}°',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(result.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(result.status).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(result.status),
                  color: _getStatusColor(result.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  result.status == QaStatus.pass
                      ? 'PASS'
                      : result.status == QaStatus.warn
                      ? 'WARN'
                      : 'FAIL',
                  style: TextStyle(
                    color: _getStatusColor(result.status),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151B35),
        border: Border(
          top: BorderSide(
            color: Colors.blue.withOpacity(0.2),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(QaStatus status) {
    switch (status) {
      case QaStatus.pass:
        return Colors.green;
      case QaStatus.warn:
        return Colors.orange;
      case QaStatus.fail:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(QaStatus status) {
    switch (status) {
      case QaStatus.pass:
        return Icons.check_circle;
      case QaStatus.warn:
        return Icons.warning;
      case QaStatus.fail:
        return Icons.error;
    }
  }
}