import 'package:dartz/dartz.dart';
import 'dart:math';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repository/qa_repository.dart';
import '../datasources/ble_datasource.dart';

class QaRepositoryImpl implements QaRepository {
  final BleDataSource dataSource;

  QaRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      await dataSource.initialize();
      return const Right(null);
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, BleDeviceInfo>> scanForDevices() async* {
    try {
      await for (final device in dataSource.scanForDevices()) {
        yield Right(device);
      }
    } catch (e) {
      yield Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopScan() async {
    try {
      await dataSource.stopScan();
      return const Right(null);
    } catch (e) {
      return Left(BleFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connectDevice(String address) async {
    try {
      final success = await dataSource.connectDevice(address);
      if (!success) {
        return const Left(ConnectionFailure("Failed to connect"));
      }
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectDevice(String address) async {
    try {
      await dataSource.disconnectDevice(address);
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startSensors(String address) async {
    try {
      await dataSource.startSensors(address);
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopSensors(String address) async {
    try {
      await dataSource.stopSensors(address);
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Stream<ImuSample> getDataStream(String address) {
    return dataSource.getDataStream(address);
  }

  @override
  Future<Either<Failure, QaResult>> evaluateDevice(
      String deviceId, List<ImuSample> samples, QaConfig config) async {
    try {
      if (samples.isEmpty) {
        return Right(QaResult(
          deviceId: deviceId,
          status: QaStatus.fail,
          macDeg: 0.0,
          noiseSigma: 0.0,
          driftDegPerMin: 0.0,
          gravityMeanG: 0.0,
          abnormalCount: 0,
        ));
      }

      double sumG = 0.0;
      int countG = 0;

      for (final sample in samples) {
        if (sample.ax != 0.0 || sample.ay != 0.0 || sample.az != 0.0) {
          final mag = sqrt(
            sample.ax * sample.ax +
                sample.ay * sample.ay +
                sample.az * sample.az,
          );
          sumG += mag;
          countG++;
        }
      }

      final gravityMeanG = countG > 0 ? sumG / countG : 0.0;

      return Right(QaResult(
        deviceId: deviceId,
        status: QaStatus.pass,
        macDeg: 0.0,
        noiseSigma: 0.0,
        driftDegPerMin: 0.0,
        gravityMeanG: gravityMeanG,
        abnormalCount: 0,
      ));
    } catch (e) {
      return Left(TestFailure(e.toString()));
    }
  }
}