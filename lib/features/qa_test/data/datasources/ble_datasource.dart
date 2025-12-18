// lib/features/qa_test/data/datasources/ble_datasource.dart
import 'dart:async';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import '../../../../core/entities/imu_entities.dart';

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
  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, StreamController<ImuSample>> _deviceStreams = {};
  final Map<String, StreamSubscription> _notifySubscriptions = {};
  StreamSubscription? _scanSubscription;
  StreamController<BleDeviceInfo>? _scanController;

  @override
  Future<void> initialize() async {}

  @override
  Stream<BleDeviceInfo> scanForDevices() {
    _scanController?.close();
    _scanController = StreamController<BleDeviceInfo>.broadcast();

    final seenAddresses = <String>{};

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName;
        final address = result.device.remoteId.str;

        if (name.isEmpty || !name.startsWith("GMSync")) continue;
        if (seenAddresses.contains(address)) continue;

        seenAddresses.add(address);
        _devices[address] = result.device;

        _scanController?.add(BleDeviceInfo(
          name: name,
          address: address,
          rssi: result.rssi,
        ));
      }
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    return _scanController!.stream;
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _scanController?.close();
    _scanController = null;
  }

  @override
  Future<bool> connectDevice(String address) async {
    try {
      final device = _devices[address];
      if (device == null) return false;

      await device.connect(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnectDevice(String address) async {
    try {
      await _notifySubscriptions[address]?.cancel();
      _notifySubscriptions.remove(address);
      await _deviceStreams[address]?.close();
      _deviceStreams.remove(address);
      await _devices[address]?.disconnect();
      _devices.remove(address);
    } catch (e) {}
  }

  @override
  Stream<ImuSample> getDataStream(String address) {
    if (!_deviceStreams.containsKey(address)) {
      _deviceStreams[address] = StreamController<ImuSample>.broadcast();
    }
    return _deviceStreams[address]!.stream;
  }

  @override
  Future<void> startSensors(String address) async {
    final device = _devices[address];
    if (device == null) throw Exception('Device not found');

    try {
      final services = await device.discoverServices();

      BluetoothService? targetService;
      for (final service in services) {
        if (service.uuid.str.toLowerCase() == "0000b3a0-0000-1000-8000-00805f9b34fb") {
          targetService = service;
          break;
        }
      }

      if (targetService == null) throw Exception('Service not found');

      BluetoothCharacteristic? notifyChar;
      BluetoothCharacteristic? writeChar;

      for (final char in targetService.characteristics) {
        final uuid = char.uuid.str.toLowerCase();
        if (uuid == "0000b3a1-0000-1000-8000-00805f9b34fb") {
          notifyChar = char;
        } else if (uuid == "0000b3a2-0000-1000-8000-00805f9b34fb") {
          writeChar = char;
        }
      }

      if (notifyChar == null || writeChar == null) {
        throw Exception('Characteristics not found');
      }

      _deviceStreams[address] = StreamController<ImuSample>.broadcast();

      await notifyChar.setNotifyValue(true);

      _notifySubscriptions[address] = notifyChar.onValueReceived.listen((data) {
        try {
          final sample = _parseImuData(data);
          if (sample != null) {
            final controller = _deviceStreams[address];
            if (controller != null && !controller.isClosed) {
              controller.add(sample);
            }
          }
        } catch (e) {}
      });

      await Future.delayed(const Duration(milliseconds: 300));

      await writeChar.write([0x55, 0xAA, 0xF0, 0x00], withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 200));
      await writeChar.write([0x55, 0xAA, 0x11, 0x02, 0x00, 0x02], withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 200));
      await writeChar.write([0x55, 0xAA, 0x0A, 0x00], withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 200));
      await writeChar.write([0x55, 0xAA, 0x08, 0x00], withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 200));
      await writeChar.write([0x55, 0xAA, 0x06, 0x00], withoutResponse: false);
    } catch (e) {
      throw Exception('Failed to start sensors: $e');
    }
  }

  @override
  Future<void> stopSensors(String address) async {
    try {
      final device = _devices[address];
      if (device == null) return;

      final services = await device.discoverServices();

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == "0000b3a0-0000-1000-8000-00805f9b34fb") {
          for (final char in service.characteristics) {
            final uuid = char.uuid.str.toLowerCase();
            if (uuid == "0000b3a2-0000-1000-8000-00805f9b34fb") {
              await char.write([0x55, 0xAA, 0xF0, 0x00], withoutResponse: false);
            }
            if (uuid == "0000b3a1-0000-1000-8000-00805f9b34fb") {
              await char.setNotifyValue(false);
            }
          }
          break;
        }
      }
    } catch (e) {}
  }

  ImuSample? _parseImuData(List<int> data) {
    if (data.length < 10) return null;
    if (data[0] != 0x55 || data[1] != 0xAA) return null;

    final cmd = data[2];
    final len = data[3];
    if (len != 0x06) return null;

    final rx = _be16(data, 4);
    final ry = _be16(data, 6);
    final rz = _be16(data, 8);

    final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (cmd == 0x08) {
      return ImuSample(
        timestampS: timestamp,
        ax: 16.0 * rx / 32768.0,
        ay: 16.0 * ry / 32768.0,
        az: 16.0 * rz / 32768.0,
        gx: 0.0,
        gy: 0.0,
        gz: 0.0,
        temp: 0.0,
      );
    } else if (cmd == 0x0A) {
      return ImuSample(
        timestampS: timestamp,
        ax: 0.0,
        ay: 0.0,
        az: 0.0,
        gx: 500.0 * rx / 28571.0,
        gy: 500.0 * ry / 28571.0,
        gz: 500.0 * rz / 28571.0,
        temp: 0.0,
      );
    }

    return null;
  }

  int _be16(List<int> data, int offset) {
    final value = (data[offset] << 8) | data[offset + 1];
    return value > 32767 ? value - 65536 : value;
  }

  void dispose() {
    for (var subscription in _notifySubscriptions.values) {
      subscription.cancel();
    }
    _notifySubscriptions.clear();
    for (var controller in _deviceStreams.values) {
      controller.close();
    }
    _deviceStreams.clear();
    _devices.clear();
  }
}