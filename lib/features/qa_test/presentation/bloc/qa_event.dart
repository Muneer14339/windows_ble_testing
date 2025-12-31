import 'package:equatable/equatable.dart';

abstract class QaEvent extends Equatable {
  const QaEvent();

  @override
  List<Object?> get props => [];
}

class InitializeQaEvent extends QaEvent {
  const InitializeQaEvent();
}

class ToggleLanguageEvent extends QaEvent {
  const ToggleLanguageEvent();
}

class StartTestEvent extends QaEvent {
  const StartTestEvent();
}

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

class ConnectFirstDeviceEvent extends QaEvent {
  const ConnectFirstDeviceEvent();
}

class StartSensorsEvent extends QaEvent {
  const StartSensorsEvent();
}

class StartDataCollectionEvent extends QaEvent {
  const StartDataCollectionEvent();
}

class UpdateProgressEvent extends QaEvent {
  final double progress;

  const UpdateProgressEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class EvaluateResultEvent extends QaEvent {
  const EvaluateResultEvent();
}

class HardFailDetectedEvent extends QaEvent {
  final String address;

  const HardFailDetectedEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class RetryTestEvent extends QaEvent {
  const RetryTestEvent();
}

class TestNextDeviceEvent extends QaEvent {
  const TestNextDeviceEvent();
}

class DiscardDeviceEvent extends QaEvent {
  const DiscardDeviceEvent();
}

class StopTestEvent extends QaEvent {
  const StopTestEvent();
}

class ResetTestEvent extends QaEvent {
  const ResetTestEvent();
}
