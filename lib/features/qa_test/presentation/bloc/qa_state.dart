import 'package:equatable/equatable.dart';
import '../../../../core/entities/imu_entities.dart';

enum QaTestPhase {
  idle,
  initializing,
  scanning,
  connecting,
  shaking,  // NEW
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
  final Map<String, int> sampleCounts;
  final List<QaResult> results;
  final String? errorMessage;
  final double progress;
  final String statusMessage;
  final bool isShaking;  // NEW

  const QaState({
    required this.phase,
    this.targetDeviceCount = 0,
    this.foundDevices = const [],
    this.connectedDevices = const [],
    this.deviceSamples = const {},
    this.sampleCounts = const {},
    this.results = const [],
    this.errorMessage,
    this.progress = 0.0,
    this.statusMessage = '',
    this.isShaking = false,  // NEW
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
    Map<String, int>? sampleCounts,
    List<QaResult>? results,
    String? errorMessage,
    double? progress,
    String? statusMessage,
    bool? isShaking,  // NEW
  }) {
    return QaState(
      phase: phase ?? this.phase,
      targetDeviceCount: targetDeviceCount ?? this.targetDeviceCount,
      foundDevices: foundDevices ?? this.foundDevices,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      deviceSamples: deviceSamples ?? this.deviceSamples,
      sampleCounts: sampleCounts ?? this.sampleCounts,
      results: results ?? this.results,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      isShaking: isShaking ?? this.isShaking,  // NEW
    );
  }

  @override
  List<Object?> get props => [
    phase,
    targetDeviceCount,
    foundDevices,
    connectedDevices,
    deviceSamples,
    sampleCounts,
    results,
    errorMessage,
    progress,
    statusMessage,
    isShaking,  // NEW
  ];
}