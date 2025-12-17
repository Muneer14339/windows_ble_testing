import 'package:dartz/dartz.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/errors/failures.dart';
import '../repository/qa_repository.dart';

class InitializeBle {
  final QaRepository repository;

  InitializeBle(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.initialize();
  }
}

class ScanDevices {
  final QaRepository repository;

  ScanDevices(this.repository);

  Stream<Either<Failure, BleDeviceInfo>> call() {
    return repository.scanForDevices();
  }
}

class StopScan {
  final QaRepository repository;

  StopScan(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.stopScan();
  }
}

class ConnectDevice {
  final QaRepository repository;

  ConnectDevice(this.repository);

  Future<Either<Failure, void>> call(String address) {
    return repository.connectDevice(address);
  }
}

class DisconnectDevice {
  final QaRepository repository;

  DisconnectDevice(this.repository);

  Future<Either<Failure, void>> call(String address) {
    return repository.disconnectDevice(address);
  }
}

class StartSensors {
  final QaRepository repository;

  StartSensors(this.repository);

  Future<Either<Failure, void>> call(String address) {
    return repository.startSensors(address);
  }
}

class StopSensors {
  final QaRepository repository;

  StopSensors(this.repository);

  Future<Either<Failure, void>> call(String address) {
    return repository.stopSensors(address);
  }
}

class GetDataStream {
  final QaRepository repository;

  GetDataStream(this.repository);

  Stream<ImuSample> call(String address) {
    return repository.getDataStream(address);
  }
}

class EvaluateDevice {
  final QaRepository repository;

  EvaluateDevice(this.repository);

  Future<Either<Failure, QaResult>> call(
      String deviceId, List<ImuSample> samples, QaConfig config) {
    return repository.evaluateDevice(deviceId, samples, config);
  }
}