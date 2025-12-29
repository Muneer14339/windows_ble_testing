import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ImuSample extends Equatable {
  final double timestampS;
  final double ax, ay, az, gx, gy, gz, temp;
  final int rawAx, rawAy, rawAz, rawGx, rawGy, rawGz; // NEW: raw int16 values

  const ImuSample({
    required this.timestampS,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.temp,
    required this.rawAx,
    required this.rawAy,
    required this.rawAz,
    required this.rawGx,
    required this.rawGy,
    required this.rawGz,
  });

  @override
  List<Object?> get props => [timestampS, ax, ay, az, gx, gy, gz, temp, rawAx, rawAy, rawAz, rawGx, rawGy, rawGz];
}

enum QaFailureReason { none, saturationRaw, gyroDeltaSpike }

class QaResult extends Equatable {
  final String deviceId;
  final bool passed;
  final QaFailureReason failureReason;
  final int saturationCount;
  final int spikeCount;
  final int maxAbsRaw;
  final int maxDelta;

  const QaResult({
    required this.deviceId,
    required this.passed,
    required this.failureReason,
    required this.saturationCount,
    required this.spikeCount,
    required this.maxAbsRaw,
    required this.maxDelta,
  });

  @override
  List<Object?> get props => [deviceId, passed, failureReason, saturationCount, spikeCount, maxAbsRaw, maxDelta];
}

class QaConfig extends Equatable {
  final double settleSeconds;
  final double testSeconds;
  final int saturationThreshold;
  final int gyroDeltaThreshold;
  final int maxSpikeCount;

  const QaConfig({
    this.settleSeconds = 5.0,
    this.testSeconds = 60.0,
    this.saturationThreshold = 32000,
    this.gyroDeltaThreshold = 5000,
    this.maxSpikeCount = 3,
  });

  @override
  List<Object?> get props => [settleSeconds, testSeconds, saturationThreshold, gyroDeltaThreshold, maxSpikeCount];
}

extension QaFailureReasonHelper on QaFailureReason {
  String get label {
    switch (this) {
      case QaFailureReason.none:
        return 'PASS';
      case QaFailureReason.saturationRaw:
        return 'SATURATION_RAW_AXIS';
      case QaFailureReason.gyroDeltaSpike:
        return 'GYRO_DELTA_SPIKE';
    }
  }
}

class BleDeviceInfo extends Equatable {
  final String name;
  final String address;
  final int rssi;

  const BleDeviceInfo({
    required this.name,
    required this.address,
    required this.rssi,
  });

  @override
  List<Object?> get props => [name, address, rssi];
}

enum QaStatus { pass, warn, fail }

extension QaStatusHelper on QaStatus {
  Color get color {
    switch (this) {
      case QaStatus.pass:
        return Colors.green;
      case QaStatus.warn:
        return Colors.orange;
      case QaStatus.fail:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case QaStatus.pass:
        return Icons.check_circle;
      case QaStatus.warn:
        return Icons.warning;
      case QaStatus.fail:
        return Icons.error;
    }
  }

  String get label {
    switch (this) {
      case QaStatus.pass:
        return 'PASS';
      case QaStatus.warn:
        return 'WARN';
      case QaStatus.fail:
        return 'FAIL';
    }
  }
}