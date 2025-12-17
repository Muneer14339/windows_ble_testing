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