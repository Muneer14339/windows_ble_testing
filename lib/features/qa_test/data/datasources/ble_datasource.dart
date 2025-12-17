import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
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
  final Map<String, StreamSubscription> _connectionSubscriptions = {};
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
    _isInitialized = true;
  }

  @override
  Stream<BleDeviceInfo> scanForDevices() {
    _scanController?.close();
    _scanController = StreamController<BleDeviceInfo>.broadcast();

    final seenAddresses = <String>{};
    final Map<String, DateTime> pendingDevices = {};

    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_scanController == null || _scanController!.isClosed) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final toCheck = <String>[];

      pendingDevices.forEach((address, time) {
        if (now.difference(time).inMilliseconds >= 150) {
          toCheck.add(address);
        }
      });

      for (final address in toCheck) {
        pendingDevices.remove(address);
      }
    });

    _scanSubscription = WinBle.scanStream.listen((device) {
      if (device.advType != "ScanResponse") return;
      final name = device.name.trim();
      if (name.isEmpty || name == "N/A") return;
      if (!name.startsWith("GMSync")) return;
      if (seenAddresses.contains(device.address)) return;

      seenAddresses.add(device.address);
      _scanController?.add(BleDeviceInfo(
        name: name,
        address: device.address,
        rssi: int.parse(device.rssi) ?? -100,
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
  Future<void> disconnectDevice(String address) async {
    try {
      await _stopNotifications(address);
      await WinBle.disconnect(address);
      await _connectionSubscriptions[address]?.cancel();
      _connectionSubscriptions.remove(address);
      await _deviceStreams[address]?.close();
      _deviceStreams.remove(address);
    } catch (e) {}
  }

  @override
  Stream<ImuSample> getDataStream(String address) {
    _deviceStreams[address] ??= StreamController<ImuSample>.broadcast();
    return _deviceStreams[address]!.stream;
  }

  @override
  Future<void> startSensors(String address) async {
    const serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
    const notifyUuid = "0000b3a1-0000-1000-8000-00805f9b34fb";
    const writeUuid = "0000b3a2-0000-1000-8000-00805f9b34fb";

    await WinBle.discoverServices(address);
    await Future.delayed(const Duration(milliseconds: 300));

    WinBle.subscribeToCharacteristic(
      address: address,
      serviceId: serviceUuid,
      characteristicId: notifyUuid,
    );

    _connectionSubscriptions[address] = WinBle.characteristicValueStream.listen((event) {
      if (event.address == address && event.characteristicId == notifyUuid) {
        final sample = _parseImuData(event.value);
        if (sample != null && !(_deviceStreams[address]?.isClosed ?? true)) {
          _deviceStreams[address]!.add(sample);
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 200));
    await _writeCommand(address, writeUuid, [0x55, 0xAA, 0xF0, 0x00]);
    await Future.delayed(const Duration(milliseconds: 200));
    await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x11, 0x02, 0x00, 0x02]);
    await Future.delayed(const Duration(milliseconds: 200));
    await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x0A, 0x00]);
    await Future.delayed(const Duration(milliseconds: 200));
    await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x08, 0x00]);
    await Future.delayed(const Duration(milliseconds: 200));
    await _writeCommand(address, writeUuid, [0x55, 0xAA, 0x06, 0x00]);
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