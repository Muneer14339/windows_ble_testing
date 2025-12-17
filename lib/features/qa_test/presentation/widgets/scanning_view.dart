import 'package:flutter/material.dart';
import '../../../../core/entities/imu_entities.dart';
import '../bloc/qa_state.dart';

class ScanningView extends StatelessWidget {
  final int targetCount;
  final List<BleDeviceInfo> foundDevices;
  final QaTestPhase phase;
  final String statusMessage;

  const ScanningView({
    super.key,
    required this.targetCount,
    required this.foundDevices,
    required this.phase,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 32),
            if (foundDevices.isNotEmpty) _buildDevicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(32),
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
          color: Colors.blue.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildAnimatedIcon(),
          const SizedBox(height: 24),
          Text(
            phase == QaTestPhase.scanning
                ? 'Scanning for Devices'
                : 'Connecting to Devices',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            statusMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.0),
                ],
              ),
            ),
            child: Icon(
              phase == QaTestPhase.scanning
                  ? Icons.radar
                  : Icons.link,
              size: 64,
              color: Colors.blue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = foundDevices.length / targetCount;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${foundDevices.length}',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / $targetCount',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF151B35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: foundDevices.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.white12,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final device = foundDevices[index];
          return _buildDeviceItem(device, index + 1);
        },
      ),
    );
  }

  Widget _buildDeviceItem(BleDeviceInfo device, int number) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.blue,
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
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.address,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildSignalStrength(device.rssi),
        ],
      ),
    );
  }

  Widget _buildSignalStrength(int rssi) {
    final strength = rssi >= -50
        ? 3
        : rssi >= -70
        ? 2
        : 1;

    return Row(
      children: List.generate(
        3,
            (index) => Container(
          width: 4,
          height: 12 + (index * 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index < strength ? Colors.blue : Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}