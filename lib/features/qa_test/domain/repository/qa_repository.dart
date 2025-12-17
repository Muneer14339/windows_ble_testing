import 'package:dartz/dartz.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/errors/failures.dart';

abstract class QaRepository {
  Future<Either<Failure, void>> initialize();
  Stream<Either<Failure, BleDeviceInfo>> scanForDevices();
  Future<Either<Failure, void>> stopScan();
  Future<Either<Failure, void>> connectDevice(String address);
  Future<Either<Failure, void>> disconnectDevice(String address);
  Future<Either<Failure, void>> startSensors(String address);
  Future<Either<Failure, void>> stopSensors(String address);
  Stream<ImuSample> getDataStream(String address);
  Future<Either<Failure, QaResult>> evaluateDevice(
      String deviceId, List<ImuSample> samples, QaConfig config);
}