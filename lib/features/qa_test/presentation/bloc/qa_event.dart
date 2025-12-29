import 'package:equatable/equatable.dart';

abstract class QaEvent extends Equatable {
  const QaEvent();

  @override
  List<Object?> get props => [];
}

class InitializeQaEvent extends QaEvent {}

class StartScanningEvent extends QaEvent {
  final int targetDeviceCount;

  const StartScanningEvent(this.targetDeviceCount);

  @override
  List<Object?> get props => [targetDeviceCount];
}

class StopScanningEvent extends QaEvent {}

class DeviceFoundEvent extends QaEvent {
  final String name;
  final String address;
  final int rssi;

  const DeviceFoundEvent({
    required this.name,
    required this.address,
    required this.rssi,
  });

  @override
  List<Object?> get props => [name, address, rssi];
}

class ConnectDevicesEvent extends QaEvent {}

class StartShakingEvent extends QaEvent {}  // NEW

class UpdateShakingEvent extends QaEvent {  // NEW
  final double progress;
  final bool isShaking;

  const UpdateShakingEvent(this.progress, this.isShaking);

  @override
  List<Object?> get props => [progress, isShaking];
}

class StartTestEvent extends QaEvent {}

class UpdateProgressEvent extends QaEvent {
  final double progress;

  const UpdateProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class EvaluateResultsEvent extends QaEvent {}

class ResetTestEvent extends QaEvent {}

class CancelTestEvent extends QaEvent {}

// In qa_event.dart
class HardFailDetectedEvent extends QaEvent {
  final String address;

  const HardFailDetectedEvent(this.address);

  @override
  List<Object?> get props => [address];
}