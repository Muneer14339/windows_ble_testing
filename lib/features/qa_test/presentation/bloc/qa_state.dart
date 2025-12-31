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
  final String currentLanguage;
  final DeviceTestSession? currentSession;
  final List<BleDeviceInfo> foundDevices;
  final String? connectedDeviceAddress;
  final Map<String, List<ImuSample>> deviceSamples;
  final Map<String, int> sampleCounts;
  final QaResult? currentResult;
  final List<BadDevice> badDevices;
  final List<QaResult> passedDevices;
  final String? errorMessage;
  final double progress;
  final String statusMessage;
  final String? toastMessage;

  const QaState({
    required this.phase,
    this.currentLanguage = 'zh',
    this.currentSession,
    this.foundDevices = const [],
    this.connectedDeviceAddress,
    this.deviceSamples = const {},
    this.sampleCounts = const {},
    this.currentResult,
    this.badDevices = const [],
    this.passedDevices = const [],
    this.errorMessage,
    this.progress = 0.0,
    this.statusMessage = '',
    this.toastMessage,
  });

  factory QaState.initial() {
    return const QaState(
      phase: QaTestPhase.idle,
      currentLanguage: 'zh',
      statusMessage: '准备开始',
    );
  }

  QaState copyWith({
    QaTestPhase? phase,
    String? currentLanguage,
    DeviceTestSession? currentSession,
    List<BleDeviceInfo>? foundDevices,
    String? connectedDeviceAddress,
    Map<String, List<ImuSample>>? deviceSamples,
    Map<String, int>? sampleCounts,
    QaResult? currentResult,
    List<BadDevice>? badDevices,
    List<QaResult>? passedDevices,
    String? errorMessage,
    double? progress,
    String? statusMessage,
    bool clearSession = false,
    bool clearResult = false,
    String? toastMessage,
    bool clearToast = false,
  }) {
    return QaState(
      phase: phase ?? this.phase,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      currentSession: clearSession ? null : (currentSession ?? this.currentSession),
      foundDevices: foundDevices ?? this.foundDevices,
      connectedDeviceAddress: connectedDeviceAddress ?? this.connectedDeviceAddress,
      deviceSamples: deviceSamples ?? this.deviceSamples,
      sampleCounts: sampleCounts ?? this.sampleCounts,
      currentResult: clearResult ? null : (currentResult ?? this.currentResult),
      badDevices: badDevices ?? this.badDevices,
      passedDevices: passedDevices ?? this.passedDevices,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    currentLanguage,
    currentSession,
    foundDevices,
    connectedDeviceAddress,
    deviceSamples,
    sampleCounts,
    currentResult,
    badDevices,
    passedDevices,
    errorMessage,
    progress,
    statusMessage,
    toastMessage,
  ];
}
