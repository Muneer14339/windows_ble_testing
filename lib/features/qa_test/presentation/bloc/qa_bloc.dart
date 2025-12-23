// lib/features/qa_test/presentation/bloc/qa_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../domain/usecases/qa_usecases.dart';
import 'qa_event.dart';
import 'qa_state.dart';

class QaBloc extends Bloc<QaEvent, QaState> {
  final InitializeBle initializeBle;
  final ScanDevices scanDevices;
  final StopScan stopScan;
  final ConnectDevice connectDevice;
  final StartSensors startSensors;
  final StopSensors stopSensors;
  final GetDataStream getDataStream;
  final EvaluateDevice evaluateDevice;
  final DisconnectDevice disconnectDevice;
  final ExportToExcel exportToExcel;

  StreamSubscription? _scanSubscription;
  final Map<String, StreamSubscription> _dataSubscriptions = {};
  final Map<String, List<ImuSample>> _collectedSamples = {};
  Timer? _progressTimer;
  final QaConfig _config = const QaConfig();

  // Shaking detection
  final List<double> _recentAccelMagnitudes = [];
  DateTime _lastShakeDetected = DateTime.now();

  QaBloc({
    required this.initializeBle,
    required this.scanDevices,
    required this.stopScan,
    required this.connectDevice,
    required this.startSensors,
    required this.stopSensors,
    required this.getDataStream,
    required this.evaluateDevice,
    required this.disconnectDevice,
    required this.exportToExcel,
  }) : super(QaState.initial()) {
    on<InitializeQaEvent>(_onInitialize);
    on<StartScanningEvent>(_onStartScanning);
    on<StopScanningEvent>(_onStopScanning);
    on<DeviceFoundEvent>(_onDeviceFound);
    on<ConnectDevicesEvent>(_onConnectDevices);
    on<StartShakingEvent>(_onStartShaking);  // NEW
    on<UpdateShakingEvent>(_onUpdateShaking);  // NEW
    on<StartTestEvent>(_onStartTest);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<EvaluateResultsEvent>(_onEvaluateResults);
    on<ResetTestEvent>(_onReset);
    on<CancelTestEvent>(_onCancel);
  }

  Future<void> _onInitialize(InitializeQaEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.initializing,
      statusMessage: 'Initializing BLE...',
    ));

    final result = await initializeBle();
    result.fold(
          (failure) => emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: failure.message,
        statusMessage: 'Initialization failed',
      )),
          (_) => emit(state.copyWith(
        phase: QaTestPhase.idle,
        statusMessage: 'Ready to start',
      )),
    );
    add(const StartScanningEvent(1));
  }

  Future<void> _onStartScanning(StartScanningEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.scanning,
      targetDeviceCount: event.targetDeviceCount,
      foundDevices: [],
      statusMessage: 'Scanning for ${event.targetDeviceCount} GMSync device(s)...',
    ));

    await _scanSubscription?.cancel();

    _scanSubscription = scanDevices().listen(
          (result) {
        result.fold(
              (failure) {},
              (device) => add(DeviceFoundEvent(
            name: device.name,
            address: device.address,
            rssi: device.rssi,
          )),
        );
      },
    );
  }

  Future<void> _onDeviceFound(DeviceFoundEvent event, Emitter<QaState> emit) async {
    if (state.phase != QaTestPhase.scanning) return;

    final updatedDevices = List<BleDeviceInfo>.from(state.foundDevices);
    final exists = updatedDevices.any((device) => device.address == event.address);

    if (!exists) {
      updatedDevices.add(BleDeviceInfo(
        name: event.name,
        address: event.address,
        rssi: event.rssi,
      ));

      emit(state.copyWith(
        foundDevices: updatedDevices,
        statusMessage: 'Found ${updatedDevices.length}/${state.targetDeviceCount} devices',
      ));

      if (updatedDevices.length >= state.targetDeviceCount) {
        add(ConnectDevicesEvent());
      }
    }
  }

  Future<void> _onStopScanning(StopScanningEvent event, Emitter<QaState> emit) async {
    await stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> _onConnectDevices(ConnectDevicesEvent event, Emitter<QaState> emit) async {
    await stopScan();
    await _scanSubscription?.cancel();

    emit(state.copyWith(
      phase: QaTestPhase.connecting,
      statusMessage: 'Connecting to ${state.foundDevices.length} devices...',
    ));

    final connectionResults = await Future.wait(
      state.foundDevices.map((device) => _connectWithRetry(device.address)),
    );

    final connected = connectionResults
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => state.foundDevices[entry.key].address)
        .toList();

    if (connected.isEmpty) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'Failed to connect to any devices',
        statusMessage: 'Connection failed',
      ));
      return;
    }

    emit(state.copyWith(
      phase: QaTestPhase.connecting,
      connectedDevices: connected,
      statusMessage: 'Verifying data stream...',
    ));

    // Verify data stream
    final streamOk = await _verifyDataStream(connected.first);

    if (!streamOk) {
      for (final address in connected) {
        await stopSensors(address);
        await disconnectDevice(address);
      }

      emit(state.copyWith(
        phase: QaTestPhase.scanning,
        connectedDevices: [],
        foundDevices: [],
        statusMessage: 'Data stream failed, retrying...',
      ));

      await Future.delayed(const Duration(seconds: 1));
      add(const StartScanningEvent(1));
      return;
    }

    // Start streams ONCE after verification
    for (final address in connected) {
      _collectedSamples[address] = [];
      _dataSubscriptions[address] = getDataStream(address).listen(
            (sample) {
          _collectedSamples[address]?.add(sample);
        },
      );
    }

    emit(state.copyWith(
      phase: QaTestPhase.connecting,
      statusMessage: 'Connection verified!',
    ));

    await Future.delayed(const Duration(milliseconds: 500));
    add(StartShakingEvent());
  }

  Future<bool> _verifyDataStream(String address) async {
    bool dataReceived = false;

    final subscription = getDataStream(address).listen(
          (sample) {
        dataReceived = true;
      },
    );

    await Future.delayed(const Duration(seconds: 3));
    await subscription.cancel();

    return dataReceived;
  }

// _onStartShaking - Stream already running, just use data
  Future<void> _onStartShaking(StartShakingEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.shaking,
      statusMessage: 'Shake the device for 30 seconds...',
      progress: 0.0,
      isShaking: false,
    ));

    _recentAccelMagnitudes.clear();
    _lastShakeDetected = DateTime.now();

    // Stream already running, data collecting in background

    _progressTimer?.cancel();
    var elapsed = 0.0;
    const shakeDuration = 30.0;

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        elapsed += 0.1;
        final progress = elapsed / shakeDuration;

        // Detect shake from already collected samples
        for (final address in state.connectedDevices) {
          final samples = _collectedSamples[address];
          if (samples != null && samples.isNotEmpty) {
            _detectShake(samples.last);
          }
        }

        final timeSinceLastShake = DateTime.now().difference(_lastShakeDetected);
        final isCurrentlyShaking = timeSinceLastShake.inSeconds < 5;

        add(UpdateShakingEvent(progress, isCurrentlyShaking));

        if (progress >= 1.0) {
          timer.cancel();
          add(StartTestEvent());
        }
      },
    );
  }

// _onStartTest - Stream already running, just clear old data
  Future<void> _onStartTest(StartTestEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.settling,
      statusMessage: 'Settling for ${_config.settleSeconds}s...',
      progress: 0.0,
    ));

    // Clear shake data but keep stream running
    for (final address in state.connectedDevices) {
      _collectedSamples[address]?.clear();
    }

    await Future.delayed(Duration(seconds: _config.settleSeconds.toInt()));

    emit(state.copyWith(
      phase: QaTestPhase.testing,
      statusMessage: 'Collecting samples from ${state.connectedDevices.length} device(s)...',
      progress: 0.0,
    ));

    // Stream already collecting data in background!

    _progressTimer?.cancel();
    var elapsed = 0.0;
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        elapsed += 0.1;
        final progress = elapsed / _config.testSeconds;
        add(UpdateProgressEvent(progress));

        if (progress >= 1.0) {
          timer.cancel();
          add(EvaluateResultsEvent());
        }
      },
    );
  }


  Future<bool> _connectWithRetry(String address) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final connectResult = await connectDevice(address);
        final connected = await connectResult.fold(
              (failure) async => false,
              (_) async => true,
        );

        if (!connected) {
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
          return false;
        }

        await Future.delayed(const Duration(milliseconds: 300));

        final startResult = await startSensors(address);
        final started = await startResult.fold(
              (failure) async => false,
              (_) async => true,
        );

        if (started) return true;

        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e) {
        if (attempt == maxRetries) return false;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    return false;
  }

  void _detectShake(ImuSample sample) {
    // Calculate acceleration magnitude
    final mag = sqrt(
        sample.ax * sample.ax +
            sample.ay * sample.ay +
            sample.az * sample.az
    );

    _recentAccelMagnitudes.add(mag);

    // Keep only last 50 samples (~1 second of data at 50Hz)
    if (_recentAccelMagnitudes.length > 50) {
      _recentAccelMagnitudes.removeAt(0);
    }

    // Detect significant movement (shake)
    // Check if magnitude deviates significantly from 1g (gravity)
    if ((mag - 1.0).abs() > 0.5) {
      // Significant movement detected
      if (_recentAccelMagnitudes.length >= 10) {
        // Check variance to confirm shake (not just tilt)
        final mean = _recentAccelMagnitudes.reduce((a, b) => a + b) / _recentAccelMagnitudes.length;
        final variance = _recentAccelMagnitudes
            .map((v) => pow(v - mean, 2))
            .reduce((a, b) => a + b) / _recentAccelMagnitudes.length;

        if (variance > 0.1) {
          _lastShakeDetected = DateTime.now();
        }
      }
    }
  }

  Future<void> _onUpdateShaking(UpdateShakingEvent event, Emitter<QaState> emit) async {
    if (state.phase == QaTestPhase.shaking) {
      emit(state.copyWith(
        progress: event.progress,
        isShaking: event.isShaking,
        statusMessage: event.isShaking
            ? 'Good! Keep shaking... ${(event.progress * 100).toInt()}%'
            : 'No shaking detected, please shake the device!',
      ));
    }
  }

  Future<void> _onUpdateProgress(UpdateProgressEvent event, Emitter<QaState> emit) async {
    if (state.phase == QaTestPhase.testing) {
      final counts = <String, int>{};
      for (final address in state.connectedDevices) {
        counts[address] = _collectedSamples[address]?.length ?? 0;
      }

      emit(state.copyWith(
        progress: event.progress,
        sampleCounts: counts,
        statusMessage: 'Collecting... ${(event.progress * 100).toInt()}%',
      ));
    }
  }

  Future<void> _onEvaluateResults(EvaluateResultsEvent event, Emitter<QaState> emit) async {
    _progressTimer?.cancel();

    for (final subscription in _dataSubscriptions.values) {
      await subscription.cancel();
    }
    _dataSubscriptions.clear();

    emit(state.copyWith(
      phase: QaTestPhase.evaluating,
      statusMessage: 'Evaluating results from ${state.connectedDevices.length} device(s)...',
      progress: 1.0,
    ));

    final results = <QaResult>[];

    for (final entry in _collectedSamples.entries) {
      final result = await evaluateDevice(entry.key, entry.value, _config);
      result.fold(
            (failure) {},
            (qaResult) => results.add(qaResult),
      );
    }

    for (final address in state.connectedDevices) {
      await stopSensors(address);
      await disconnectDevice(address);
    }

    String? exportPath;
    if (results.isNotEmpty) {
      final exportResult = await exportToExcel(results);
      exportResult.fold(
            (failure) => exportPath = null,
            (path) => exportPath = path,
      );
    }

    emit(state.copyWith(
      phase: QaTestPhase.completed,
      results: results,
      deviceSamples: Map.from(_collectedSamples),
      statusMessage: exportPath != null
          ? 'Test completed - Data saved to Excel'
          : 'Test completed - ${results.length} device(s) evaluated',
      progress: 1.0,
    ));

    _collectedSamples.clear();
  }

  Future<void> _onReset(ResetTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    emit(state.copyWith(
      phase: QaTestPhase.initializing,
      statusMessage: 'Initializing...',
      targetDeviceCount: 0,
      foundDevices: [],
      connectedDevices: [],
      results: [],
      deviceSamples: {},
      sampleCounts: {},
      errorMessage: null,
      progress: 0.0,
      isShaking: false,
    ));

    add(InitializeQaEvent());
  }

  Future<void> _onCancel(CancelTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    emit(state.copyWith(
      phase: QaTestPhase.initializing,
      statusMessage: 'Restarting...',
      targetDeviceCount: 0,
      foundDevices: [],
      connectedDevices: [],
      results: [],
      deviceSamples: {},
      sampleCounts: {},
      errorMessage: null,
      progress: 0.0,
      isShaking: false,
    ));

    add(InitializeQaEvent());
  }

  Future<void> _cleanup() async {
    _progressTimer?.cancel();
    await _scanSubscription?.cancel();

    for (final subscription in _dataSubscriptions.values) {
      await subscription.cancel();
    }
    _dataSubscriptions.clear();

    for (final address in state.connectedDevices) {
      await stopSensors(address);
      await disconnectDevice(address);
    }

    await stopScan();
    _collectedSamples.clear();
    _recentAccelMagnitudes.clear();
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}