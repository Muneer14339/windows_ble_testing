import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ImuSample extends Equatable {
  final double timestampS;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
  final double temp;

  const ImuSample({
    required this.timestampS,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.temp,
  });

  @override
  List<Object?> get props => [timestampS, ax, ay, az, gx, gy, gz, temp];
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

class QaResult extends Equatable {
  final String deviceId;
  final QaStatus status;
  final double macDeg;
  final double noiseSigma;
  final double driftDegPerMin;
  final double gravityMeanG;
  final int abnormalCount;

  const QaResult({
    required this.deviceId,
    required this.status,
    required this.macDeg,
    required this.noiseSigma,
    required this.driftDegPerMin,
    required this.gravityMeanG,
    required this.abnormalCount,
  });

  @override
  List<Object?> get props => [
    deviceId,
    status,
    macDeg,
    noiseSigma,
    driftDegPerMin,
    gravityMeanG,
    abnormalCount,
  ];
}

class QaConfig extends Equatable {
  final double settleSeconds;
  final double testSeconds;
  final double abnormalThresholdDeg;
  final double gravityDeviationG;
  final double gyroStillnessDegPerS;
  final int maxAbnormalPerWindow;
  final double maxMacDeg;
  final double maxNoiseSigmaDeg;
  final double maxDriftDegPerMin;

  const QaConfig({
    this.settleSeconds = 5.0,
    this.testSeconds = 60.0,
    this.abnormalThresholdDeg = 0.30,
    this.gravityDeviationG = 0.05,
    this.gyroStillnessDegPerS = 0.5,
    this.maxAbnormalPerWindow = 100,
    this.maxMacDeg = 0.20,
    this.maxNoiseSigmaDeg = 0.05,
    this.maxDriftDegPerMin = 0.10,
  });

  @override
  List<Object?> get props => [
    settleSeconds,
    testSeconds,
    abnormalThresholdDeg,
    gravityDeviationG,
    gyroStillnessDegPerS,
    maxAbnormalPerWindow,
    maxMacDeg,
    maxNoiseSigmaDeg,
    maxDriftDegPerMin,
  ];
}

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