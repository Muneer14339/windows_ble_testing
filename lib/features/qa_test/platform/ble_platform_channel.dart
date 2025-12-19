import 'dart:async';
import 'package:flutter/services.dart';
import '../../../../core/entities/imu_entities.dart';

class BlePlatformChannel {
  static const MethodChannel _channel = MethodChannel('native_ble_plugin');

  final StreamController<BleDeviceInfo> _deviceController = StreamController.broadcast();
  final Map<String, StreamController<ImuSample>> _dataControllers = {};
  Timer? _pollTimer;

  BlePlatformChannel() {
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      try {
        final devices = await _channel.invokeMethod('pollDevices');
        if (devices is List) {
          for (final device in devices) {
            final map = device as Map;
            _deviceController.add(BleDeviceInfo(
              name: map['name'],
              address: map['address'],
              rssi: map['rssi'],
            ));
          }
        }
      } catch (_) {}
    });
  }

  Stream<BleDeviceInfo> get deviceStream => _deviceController.stream;

  Stream<ImuSample> getDataStream(String address) {
    if (!_dataControllers.containsKey(address)) {
      _dataControllers[address] = StreamController<ImuSample>.broadcast();
      _pollDataStream(address);
    }
    return _dataControllers[address]!.stream;
  }

  void _pollDataStream(String address) {
    Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (!_dataControllers.containsKey(address)) return;

      try {
        final samples = await _channel.invokeMethod('pollSamples', {'address': address});
        if (samples is List) {
          for (final sample in samples) {
            final map = sample as Map;
            _dataControllers[address]?.add(ImuSample(
              timestampS: map['timestampS'],
              ax: map['ax'],
              ay: map['ay'],
              az: map['az'],
              gx: map['gx'],
              gy: map['gy'],
              gz: map['gz'],
              temp: map['temp'],
            ));
          }
        }
      } catch (_) {}
    });
  }

  Future<void> startScanning() => _channel.invokeMethod('startScanning');
  Future<void> stopScanning() => _channel.invokeMethod('stopScanning');

  Future<void> connectDevice(String address) =>
      _channel.invokeMethod('connectDevice', {'address': address});

  Future<void> startSensors(String address) =>
      _channel.invokeMethod('startSensors', {'address': address});

  Future<void> stopSensors(String address) =>
      _channel.invokeMethod('stopSensors', {'address': address});

  Future<void> disconnectDevice(String address) =>
      _channel.invokeMethod('disconnectDevice', {'address': address});

  void dispose() {
    _pollTimer?.cancel();
    _deviceController.close();
    for (var controller in _dataControllers.values) {
      controller.close();
    }
  }
}