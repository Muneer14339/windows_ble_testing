// lib/features/qa_test/data/datasources/ble_datasource.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';
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
  final Map<String, StreamController<ImuSample>> _deviceStreams = {};
  final Map<String, List<int>> _deviceBuffers = {}; // NEW: per-device buffer
  StreamSubscription? _globalNotifySubscription;
  StreamSubscription? _scanSubscription;
  StreamController<BleDeviceInfo>? _scanController;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    await WinBle.initialize(
      serverPath: await WinServer.path(),
      enableLog: false,
    );

    await _globalNotifySubscription?.cancel();
    _globalNotifySubscription = WinBle.characteristicValueStream.listen((data) {
      try {
        if (data is! Map) return;
print("Data is : $data");
        final eventAddress = data['address']?.toString();
        final eventCharId = data['characteristicId']?.toString();
        final rawValue = data['value'];

        const notifyUuid = "0000b3a1-0000-1000-8000-00805f9b34fb";

        if (eventAddress == null || eventCharId != notifyUuid || rawValue is! List) {
          return;
        }

        // Append bytes to device buffer
        _deviceBuffers[eventAddress] ??= [];
        _deviceBuffers[eventAddress]!.addAll(rawValue.cast<int>());

        // Extract all complete packets from buffer
        _processBuffer(eventAddress);
      } catch (e) {}
    });

    _isInitialized = true;
  }

  void _processBuffer(String address) {
    final buffer = _deviceBuffers[address];
    if (buffer == null || buffer.isEmpty) return;

    while (buffer.length >= 10) {
      // Find sync bytes (0x55 0xAA)
      int syncIndex = -1;
      for (int i = 0; i <= buffer.length - 2; i++) {
        if (buffer[i] == 0x55 && buffer[i + 1] == 0xAA) {
          syncIndex = i;
          break;
        }
      }

      // No sync found - keep last byte (might be start of 0x55)
      if (syncIndex == -1) {
        if (buffer.length > 1) buffer.removeRange(0, buffer.length - 1);
        break;
      }

      // Remove junk before sync
      if (syncIndex > 0) {
        buffer.removeRange(0, syncIndex);
      }

      // Need at least 10 bytes for complete packet
      if (buffer.length < 10) break;

      // Check if valid packet
      final len = buffer[3];
      if (len != 0x06) {
        buffer.removeAt(0); // Remove corrupt sync, try next
        continue;
      }

      // Extract packet
      final packet = buffer.sublist(0, 10);
      final sample = _parseImuData(packet);

      if (sample != null) {
        final controller = _deviceStreams[address];
        if (controller != null && !controller.isClosed) {
          controller.add(sample);
        }
      }

      // Remove processed packet
      buffer.removeRange(0, 10);
    }
  }

  @override
  Future<void> disconnectDevice(String address) async {
    try {
      await _stopNotifications(address);
      await _deviceStreams[address]?.close();
      _deviceStreams.remove(address);
      _deviceBuffers.remove(address); // NEW: cleanup buffer
      await WinBle.disconnect(address);
    } catch (e) {}
  }

  void dispose() {
    _globalNotifySubscription?.cancel();
    for (var controller in _deviceStreams.values) {
      controller.close();
    }
    _deviceStreams.clear();
    _deviceBuffers.clear(); // NEW
  }

  @override
  Stream<BleDeviceInfo> scanForDevices() {
    _scanController?.close();
    _scanController = StreamController<BleDeviceInfo>.broadcast();

    final seenAddresses = <String>{};

    _scanSubscription = WinBle.scanStream.listen((device) {
      if (device.advType != "ScanResponse") return;
      final name = device.name.trim();
      if (name.isEmpty || name == "N/A") return;
      final address = device.address.trim();
      if (address.isEmpty || address == "N/A" || address.endsWith("14")) return;
      if (!name.startsWith("GMSync")) return;
      if (seenAddresses.contains(device.address)) return;

      seenAddresses.add(device.address);
      _scanController?.add(BleDeviceInfo(
        name: name,
        address: device.address,
        rssi: int.tryParse(device.rssi) ?? -100,
      ));
    });

    WinBle.startScanning();
    return _scanController!.stream;
  }

  @override
  Future<void> stopScan() async {
    WinBle.stopScanning();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _scanController?.close();
    _scanController = null;
  }

  @override
  Future<bool> connectDevice(String address) async {
    try {
      await WinBle.connect(address);
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
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
    const serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
    const notifyUuid = "0000b3a1-0000-1000-8000-00805f9b34fb";
    const writeUuid = "0000b3a2-0000-1000-8000-00805f9b34fb";

    try {
      await WinBle.discoverServices(address);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!_deviceStreams.containsKey(address)) {
        _deviceStreams[address] = StreamController<ImuSample>.broadcast();
      }

      await WinBle.subscribeToCharacteristic(
        address: address,
        serviceId: serviceUuid,
        characteristicId: notifyUuid,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0xF0, 0x00]);
      await Future.delayed(const Duration(milliseconds: 200));
      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x11, 0x02, 0x00, 0x02]);
      await Future.delayed(const Duration(milliseconds: 200));
      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x0A, 0x00]);
      await Future.delayed(const Duration(milliseconds: 200));
      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x08, 0x00]);
      await Future.delayed(const Duration(milliseconds: 200));
      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x06, 0x00]);
    } catch (e) {
      throw Exception('Failed to start sensors: $e');
    }
  }

  @override
  Future<void> stopSensors(String address) async {
    const serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
    const writeUuid = "0000b3a2-0000-1000-8000-00805f9b34fb";

    try {
      await _writeCommand(address, writeUuid, [0x55, 0xAA, 0xF0, 0x00]);
      await _stopNotifications(address);
    } catch (e) {}
  }

  Future<void> _stopNotifications(String address) async {
    const serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
    const notifyUuid = "0000b3a1-0000-1000-8000-00805f9b34fb";

    try {
      await WinBle.unSubscribeFromCharacteristic(
        address: address,
        serviceId: serviceUuid,
        characteristicId: notifyUuid,
      );
    } catch (e) {}
  }

  Future<void> _writeCommand(String address, String characteristicId, List<int> data) async {
    const serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
    await WinBle.write(
      address: address,
      service: serviceUuid,
      characteristic: characteristicId,
      data: Uint8List.fromList(data),
      writeWithResponse: true,
    );
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
}

