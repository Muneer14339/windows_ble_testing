// lib/features/qa_test/presentation/bloc/qa_bloc.dart
import 'dart:async';
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

  StreamSubscription? _scanSubscription;
  final Map<String, StreamSubscription> _dataSubscriptions = {};
  final Map<String, List<ImuSample>> _collectedSamples = {};
  Timer? _progressTimer;
  final QaConfig _config = const QaConfig();

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
  }) : super(QaState.initial()) {
    on<InitializeQaEvent>(_onInitialize);
    on<StartScanningEvent>(_onStartScanning);
    on<StopScanningEvent>(_onStopScanning);
    on<DeviceFoundEvent>(_onDeviceFound);
    on<ConnectDevicesEvent>(_onConnectDevices);
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
    // Automatically start scanning for 1 device
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
      statusMessage: 'Connecting to ${state.foundDevices.length} devices in parallel...',
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
    } else {
      emit(state.copyWith(
        phase: QaTestPhase.settling,
        connectedDevices: connected,
        statusMessage: 'Connected ${connected.length}/${state.foundDevices.length} device(s)',
      ));

      add(StartTestEvent());
    }
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

  Future<void> _onStartTest(StartTestEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.settling,
      statusMessage: 'Settling for ${_config.settleSeconds}s...',
      progress: 0.0,
    ));

    await Future.delayed(Duration(seconds: _config.settleSeconds.toInt()));

    emit(state.copyWith(
      phase: QaTestPhase.testing,
      statusMessage: 'Collecting samples from ${state.connectedDevices.length} device(s)...',
      progress: 0.0,
    ));

    _collectedSamples.clear();

    for (final address in state.connectedDevices) {
      _collectedSamples[address] = [];
      await _dataSubscriptions[address]?.cancel();
      _dataSubscriptions[address] = getDataStream(address).listen(
            (sample) {
          _collectedSamples[address]?.add(sample);
        },
      );
    }

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

    emit(state.copyWith(
      phase: QaTestPhase.completed,
      results: results,
      deviceSamples: Map.from(_collectedSamples),
      statusMessage: 'Test completed - ${results.length} device(s) evaluated',
      progress: 1.0,
    ));

    _collectedSamples.clear();
  }

  Future<void> _onReset(ResetTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    // emit(QaState.initial());
    // Instead of going to idle, directly start scanning
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
    ));

    // Reinitialize and start scanning
    add(InitializeQaEvent());
  }

  Future<void> _onCancel(CancelTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    // emit(state.copyWith(
    //   phase: QaTestPhase.idle,
    //   statusMessage: 'Test cancelled',
    // ));

    // Instead of going to idle, directly start scanning again
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
    ));

    // Reinitialize and start scanning
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
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}