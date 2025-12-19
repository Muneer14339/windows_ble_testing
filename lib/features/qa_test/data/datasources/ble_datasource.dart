// lib/features/qa_test/data/datasources/ble_datasource.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../platform/ble_platform_channel.dart';

abstract class BleDataSource {
  Future<void> initialize();
  Stream<BleDeviceInfo> scanForDevices();
  Future<void> stopScan();
  Future<bool> connectDevice(String address);
  Future<void> disconnectDevice(String address);
  Stream<ImuSample> getDataStream(String address);
  Future<void> startSensors(String address);
  Future<void> stopSensors(String address);
}

class BleDataSourceImpl implements BleDataSource {
  final BlePlatformChannel _platform = BlePlatformChannel();
  final Map<String, StreamController<ImuSample>> _deviceStreams = {};
  StreamSubscription? _scanSubscription;
  StreamController<BleDeviceInfo>? _scanController;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  @override
  Stream<BleDeviceInfo> scanForDevices() {
    _scanController?.close();
    _scanController = StreamController<BleDeviceInfo>.broadcast();

    _scanSubscription = _platform.deviceStream.listen((device) {
      _scanController?.add(device);
    });

    _platform.startScanning();
    return _scanController!.stream;
  }

  @override
  Future<void> stopScan() async {
    await _platform.stopScanning();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _scanController?.close();
    _scanController = null;
  }

  @override
  Future<bool> connectDevice(String address) async {
    try {
      await _platform.connectDevice(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnectDevice(String address) async {
    await _platform.stopSensors(address);
    await _deviceStreams[address]?.close();
    _deviceStreams.remove(address);
    await _platform.disconnectDevice(address);
  }

  @override
  Stream<ImuSample> getDataStream(String address) {
    if (!_deviceStreams.containsKey(address)) {
      _deviceStreams[address] = StreamController<ImuSample>.broadcast();
      _platform.getDataStream(address).listen((sample) {
        _deviceStreams[address]?.add(sample);
      });
    }
    return _deviceStreams[address]!.stream;
  }

  @override
  Future<void> startSensors(String address) async {
    await _platform.startSensors(address);
  }

  @override
  Future<void> stopSensors(String address) async {
    await _platform.stopSensors(address);
  }

  void dispose() {
    _platform.dispose();
    for (var controller in _deviceStreams.values) {
      controller.close();
    }
  }
}

