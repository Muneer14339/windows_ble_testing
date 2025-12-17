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

      double sumGx = 0.0, sumGy = 0.0, sumGz = 0.0;
      double sumAx = 0.0, sumAy = 0.0, sumAz = 0.0;
      int gyroCount = 0, accelCount = 0;

      for (final sample in samples) {
        if (sample.gx != 0.0 || sample.gy != 0.0 || sample.gz != 0.0) {
          sumGx += sample.gx;
          sumGy += sample.gy;
          sumGz += sample.gz;
          gyroCount++;
        }
        if (sample.ax != 0.0 || sample.ay != 0.0 || sample.az != 0.0) {
          sumAx += sample.ax;
          sumAy += sample.ay;
          sumAz += sample.az;
          accelCount++;
        }
      }

      final gravityMeanG = accelCount > 0
          ? sqrt((sumAx/accelCount) * (sumAx/accelCount) +
          (sumAy/accelCount) * (sumAy/accelCount) +
          (sumAz/accelCount) * (sumAz/accelCount))
          : 0.0;

      final gyroMeanX = gyroCount > 0 ? sumGx / gyroCount : 0.0;
      final gyroMeanY = gyroCount > 0 ? sumGy / gyroCount : 0.0;
      final gyroMeanZ = gyroCount > 0 ? sumGz / gyroCount : 0.0;

      double gyroVariance = 0.0;
      if (gyroCount > 0) {
        for (final sample in samples) {
          if (sample.gx != 0.0 || sample.gy != 0.0 || sample.gz != 0.0) {
            final dx = sample.gx - gyroMeanX;
            final dy = sample.gy - gyroMeanY;
            final dz = sample.gz - gyroMeanZ;
            gyroVariance += (dx * dx + dy * dy + dz * dz);
          }
        }
        gyroVariance /= gyroCount;
      }

      final noiseSigma = sqrt(gyroVariance);

      final gravityDeviation = (gravityMeanG - 1.0).abs();
      final isGravityGood = gravityDeviation <= config.gravityDeviationG;
      final isNoiseGood = noiseSigma <= config.maxNoiseSigmaDeg;

      QaStatus status;
      if (isGravityGood && isNoiseGood) {
        status = QaStatus.pass;
      } else if (isGravityGood || isNoiseGood) {
        status = QaStatus.warn;
      } else {
        status = QaStatus.fail;
      }

      return Right(QaResult(
        deviceId: deviceId,
        status: status,
        macDeg: 0.0,
        noiseSigma: noiseSigma,
        driftDegPerMin: 0.0,
        gravityMeanG: gravityMeanG,
        abnormalCount: 0,
      ));
    } catch (e) {
      return Left(TestFailure(e.toString()));
    }
  }
}