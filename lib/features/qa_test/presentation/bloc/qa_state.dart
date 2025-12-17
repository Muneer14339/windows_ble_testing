import 'package:equatable/equatable.dart';
import '../../../../core/entities/imu_entities.dart';

enum QaTestPhase {
  idle,
  initializing,
  scanning,
  connecting,
  settling,
  testing,
  evaluating,
  completed,
  error,
}

class QaState extends Equatable {
  final QaTestPhase phase;
  final int targetDeviceCount;
  final List<BleDeviceInfo> foundDevices;
  final List<String> connectedDevices;
  final Map<String, List<ImuSample>> deviceSamples;
  final List<QaResult> results;
  final String? errorMessage;
  final double progress;
  final String statusMessage;

  const QaState({
    required this.phase,
    this.targetDeviceCount = 0,
    this.foundDevices = const [],
    this.connectedDevices = const [],
    this.deviceSamples = const {},
    this.results = const [],
    this.errorMessage,
    this.progress = 0.0,
    this.statusMessage = '',
  });

  factory QaState.initial() {
    return const QaState(
      phase: QaTestPhase.idle,
      statusMessage: 'Ready to start',
    );
  }

  QaState copyWith({
    QaTestPhase? phase,
    int? targetDeviceCount,
    List<BleDeviceInfo>? foundDevices,
    List<String>? connectedDevices,
    Map<String, List<ImuSample>>? deviceSamples,
    List<QaResult>? results,
    String? errorMessage,
    double? progress,
    String? statusMessage,
  }) {
    return QaState(
      phase: phase ?? this.phase,
      targetDeviceCount: targetDeviceCount ?? this.targetDeviceCount,
      foundDevices: foundDevices ?? this.foundDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      deviceSamples: deviceSamples ?? this.deviceSamples,
      results: results ?? this.results,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    targetDeviceCount,
    foundDevices,
    connectedDevices,
    deviceSamples,
    results,
    errorMessage,
    progress,
    statusMessage,
  ];
}