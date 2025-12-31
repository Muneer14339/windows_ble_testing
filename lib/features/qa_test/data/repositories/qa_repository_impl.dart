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
      String deviceId, List<ImuSample> samples, QaConfig config) async
  {
    try {
      if (samples.isEmpty) {
        return Right(QaResult(
          deviceId: deviceId,
          macAddress: deviceId,
          passed: false,
          failureReason: QaFailureReason.none,
          saturationCount: 0,
          spikeCount: 0,
          maxAbsRaw: 0,
          maxDelta: 0,
        ));
      }

      int saturationCount = 0;
      int maxAbsRaw = 0;

      // Test 1: Hard Saturation Check
      for (final sample in samples) {
        final rawValues = [
          sample.rawAx.abs(),
          sample.rawAy.abs(),
          sample.rawAz.abs(),
          sample.rawGx.abs(),
          sample.rawGy.abs(),
          sample.rawGz.abs(),
        ];

        final maxSample = rawValues.reduce(max);
        maxAbsRaw = max(maxAbsRaw, maxSample);

        if (maxSample >= config.saturationThreshold) {
          saturationCount++;
        }
      }

      if (saturationCount > 5) {
        return Right(QaResult(
          deviceId: deviceId,
          macAddress: deviceId,
          passed: false,
          failureReason: QaFailureReason.saturationRaw,
          saturationCount: saturationCount,
          spikeCount: 0,
          maxAbsRaw: maxAbsRaw,
          maxDelta: 0,
        ));
      }

      // Test 2: Gyro Delta Spike Check (1-second windows)
      final gyroSamples = samples.where((s) =>
      s.rawGx != 0 || s.rawGy != 0 || s.rawGz != 0
      ).toList();

      int spikeCount = 0;
      int maxDelta = 0;

      if (gyroSamples.length > 1) {
        final windowStartTime = gyroSamples.first.timestampS;
        var windowSamples = <ImuSample>[];

        for (final sample in gyroSamples) {
          if (sample.timestampS - windowStartTime <= 1.0) {
            windowSamples.add(sample);
          } else {
            // Process window
            spikeCount += _countSpikesInWindow(windowSamples, config.gyroDeltaThreshold);
            maxDelta = max(maxDelta, _getMaxDeltaInWindow(windowSamples));

            // Start new window
            windowSamples = [sample];
          }
        }

        // Process last window
        if (windowSamples.isNotEmpty) {
          spikeCount += _countSpikesInWindow(windowSamples, config.gyroDeltaThreshold);
          maxDelta = max(maxDelta, _getMaxDeltaInWindow(windowSamples));
        }
      }

      final passed = spikeCount < config.maxSpikeCount;

      return Right(QaResult(
        deviceId: deviceId,
        macAddress: deviceId,
        passed: passed,
        failureReason: passed ? QaFailureReason.none : QaFailureReason.gyroDeltaSpike,
        saturationCount: 0,
        spikeCount: spikeCount,
        maxAbsRaw: maxAbsRaw,
        maxDelta: maxDelta,
      ));
    } catch (e) {
      return Left(TestFailure(e.toString()));
    }
  }

  int _countSpikesInWindow(List<ImuSample> samples, int threshold) {
    int count = 0;
    for (int i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];

      final deltaGx = (curr.rawGx - prev.rawGx).abs();
      final deltaGy = (curr.rawGy - prev.rawGy).abs();
      final deltaGz = (curr.rawGz - prev.rawGz).abs();

      if (deltaGx > threshold || deltaGy > threshold || deltaGz > threshold) {
        count++;
      }
    }
    return count;
  }

  int _getMaxDeltaInWindow(List<ImuSample> samples) {
    int maxDelta = 0;
    for (int i = 1; i < samples.length; i++) {
      final prev = samples[i - 1];
      final curr = samples[i];

      final deltaGx = (curr.rawGx - prev.rawGx).abs();
      final deltaGy = (curr.rawGy - prev.rawGy).abs();
      final deltaGz = (curr.rawGz - prev.rawGz).abs();

      maxDelta = max(maxDelta, max(deltaGx, max(deltaGy, deltaGz)));
    }
    return maxDelta;
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