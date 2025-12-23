import 'package:dartz/dartz.dart';
import 'dart:math';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repository/qa_repository.dart';
import '../datasources/ble_datasource.dart';
import '../datasources/excel_datasource.dart';

class QaRepositoryImpl implements QaRepository {
  final BleDataSource dataSource;
  final ExcelDataSource excelDataSource;

  QaRepositoryImpl(this.dataSource, this.excelDataSource);

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

      // Separate gyro and accel samples
      final gyroSamples = <ImuSample>[];
      final accelSamples = <ImuSample>[];

      for (final sample in samples) {
        if (sample.gx != 0.0 || sample.gy != 0.0 || sample.gz != 0.0) {
          gyroSamples.add(sample);
        }
        if (sample.ax != 0.0 || sample.ay != 0.0 || sample.az != 0.0) {
          accelSamples.add(sample);
        }
      }

      // Calculate gravity mean (magnitude of mean acceleration)
      double gravityMeanG = 0.0;
      if (accelSamples.isNotEmpty) {
        double sumAx = 0.0, sumAy = 0.0, sumAz = 0.0;
        for (final s in accelSamples) {
          sumAx += s.ax;
          sumAy += s.ay;
          sumAz += s.az;
        }
        final meanAx = sumAx / accelSamples.length;
        final meanAy = sumAy / accelSamples.length;
        final meanAz = sumAz / accelSamples.length;
        gravityMeanG = sqrt(meanAx * meanAx + meanAy * meanAy + meanAz * meanAz);
      }

      // Calculate gyro noise (σ - standard deviation)
      double noiseSigma = 0.0;
      if (gyroSamples.isNotEmpty) {
        double sumGx = 0.0, sumGy = 0.0, sumGz = 0.0;
        for (final s in gyroSamples) {
          sumGx += s.gx;
          sumGy += s.gy;
          sumGz += s.gz;
        }
        final meanGx = sumGx / gyroSamples.length;
        final meanGy = sumGy / gyroSamples.length;
        final meanGz = sumGz / gyroSamples.length;

        double variance = 0.0;
        for (final s in gyroSamples) {
          final dx = s.gx - meanGx;
          final dy = s.gy - meanGy;
          final dz = s.gz - meanGz;
          variance += (dx * dx + dy * dy + dz * dz);
        }
        variance /= gyroSamples.length;
        noiseSigma = sqrt(variance);
      }

      // Calculate drift (linear fit of gyro magnitude over time)
      double driftDegPerMin = 0.0;
      if (gyroSamples.length > 1) {
        final firstTime = gyroSamples.first.timestampS;
        final lastTime = gyroSamples.last.timestampS;
        final duration = lastTime - firstTime;

        if (duration > 0) {
          final firstMag = sqrt(
              gyroSamples.first.gx * gyroSamples.first.gx +
                  gyroSamples.first.gy * gyroSamples.first.gy +
                  gyroSamples.first.gz * gyroSamples.first.gz
          );
          final lastMag = sqrt(
              gyroSamples.last.gx * gyroSamples.last.gx +
                  gyroSamples.last.gy * gyroSamples.last.gy +
                  gyroSamples.last.gz * gyroSamples.last.gz
          );
          driftDegPerMin = ((lastMag - firstMag) / duration) * 60.0;
        }
      }

      // Count abnormal samples (gyro magnitude > threshold)
      int abnormalCount = 0;
      for (final s in gyroSamples) {
        final mag = sqrt(s.gx * s.gx + s.gy * s.gy + s.gz * s.gz);
        print("Magnitude : $mag");
        if (mag > config.abnormalThresholdDeg) {
          abnormalCount++;
        }
      }

      // Calculate MAC (Mean Absolute Change) - simplified as noise for now
      final macDeg = noiseSigma;

      // Determine status based on PDF criteria
      final gravityDeviation = (gravityMeanG - 1.0).abs();
      final isGravityGood = gravityDeviation <= config.gravityDeviationG;
      final isNoiseGood = noiseSigma <= config.maxNoiseSigmaDeg;
      final isMacGood = macDeg <= config.maxMacDeg;
      final isDriftGood = driftDegPerMin.abs() <= config.maxDriftDegPerMin;
      final isAbnormalGood = abnormalCount < config.maxAbnormalPerWindow;

      QaStatus status;
      if (isGravityGood && isNoiseGood && isMacGood && isDriftGood && isAbnormalGood) {
        status = QaStatus.pass;
      } else if (!isGravityGood || abnormalCount >= config.maxAbnormalPerWindow) {
        status = QaStatus.fail;
      } else {
        status = QaStatus.warn;
      }

      return Right(QaResult(
        deviceId: deviceId,
        status: status,
        macDeg: macDeg,
        noiseSigma: noiseSigma,
        driftDegPerMin: driftDegPerMin,
        gravityMeanG: gravityMeanG,
        abnormalCount: abnormalCount,
      ));
    } catch (e) {
      return Left(TestFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportToExcel(List<QaResult> results) async {
    try {
      final filePath = await excelDataSource.exportResults(results);
      return Right(filePath);
    } catch (e) {
      return Left(TestFailure('Export failed: ${e.toString()}'));
    }
  }
}