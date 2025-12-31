import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ImuSample extends Equatable {
  final double timestampS;
  final double ax, ay, az, gx, gy, gz, temp;
  final int rawAx, rawAy, rawAz, rawGx, rawGy, rawGz;

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
  final String macAddress;
  final bool passed;
  final QaFailureReason failureReason;
  final int saturationCount;
  final int spikeCount;
  final int maxAbsRaw;
  final int maxDelta;
  final int attemptNumber;
  final bool isBadSensor;

  const QaResult({
    required this.deviceId,
    required this.macAddress,
    required this.passed,
    required this.failureReason,
    required this.saturationCount,
    required this.spikeCount,
    required this.maxAbsRaw,
    required this.maxDelta,
    this.attemptNumber = 1,
    this.isBadSensor = false,
  });

  @override
  List<Object?> get props => [
    deviceId, 
    macAddress,
    passed, 
    failureReason, 
    saturationCount, 
    spikeCount, 
    maxAbsRaw, 
    maxDelta,
    attemptNumber,
    isBadSensor,
  ];
}

class BadDevice extends Equatable {
  final String macAddress;
  final String deviceName;
  final DateTime failedAt;

  const BadDevice({
    required this.macAddress,
    required this.deviceName,
    required this.failedAt,
  });

  @override
  List<Object?> get props => [macAddress, deviceName, failedAt];
}

class DeviceTestSession extends Equatable {
  final String macAddress;
  final String deviceName;
  final int currentAttempt;
  final List<QaResult> attemptResults;

  const DeviceTestSession({
    required this.macAddress,
    required this.deviceName,
    this.currentAttempt = 1,
    this.attemptResults = const [],
  });

  DeviceTestSession copyWith({
    int? currentAttempt,
    List<QaResult>? attemptResults,
  }) {
    return DeviceTestSession(
      macAddress: macAddress,
      deviceName: deviceName,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      attemptResults: attemptResults ?? this.attemptResults,
    );
  }

  @override
  List<Object?> get props => [macAddress, deviceName, currentAttempt, attemptResults];
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
