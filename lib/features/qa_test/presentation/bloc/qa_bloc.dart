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
  Timer? _testTimer;
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

    // Parallel connection with individual retry logic for each device
    final connectionTasks = state.foundDevices.map((device) {
      return _connectDeviceWithRetry(device.address, device.name, emit);
    }).toList();

    final results = await Future.wait(connectionTasks);
    final connected = results.where((addr) => addr != null).map((addr) => addr!).toList();

    if (connected.isEmpty) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'Failed to connect to any devices',
        statusMessage: 'Connection failed',
      ));
    } else {
      final successCount = connected.length;
      final totalCount = state.foundDevices.length;

      emit(state.copyWith(
        phase: QaTestPhase.settling,
        connectedDevices: connected,
        statusMessage: 'Connected $successCount/$totalCount device(s). ${totalCount - successCount > 0 ? "Retrying failed connections..." : ""}',
      ));

      add(StartTestEvent());
    }
  }

  Future<String?> _connectDeviceWithRetry(
      String address,
      String name,
      Emitter<QaState> emit,
      ) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await connectDevice(address);

        final success = await result.fold(
              (failure) async => false,
              (_) async {
            // Small delay after connection
            await Future.delayed(const Duration(milliseconds: 300));

            // Try to start sensors
            final startResult = await startSensors(address);
            return await startResult.fold(
                  (failure) async => false,
                  (_) async => true,
            );
          },
        );

        if (success) return address;

        // Exponential backoff for retry
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e) {
        if (attempt == maxRetries) {
          return null;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    return null;
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

    // Clear previous data
    _collectedSamples.clear();

    // Setup data collection for ALL connected devices in parallel
    for (final address in state.connectedDevices) {
      _collectedSamples[address] = [];

      await _dataSubscriptions[address]?.cancel();
      _dataSubscriptions[address] = getDataStream(address).listen(
            (sample) {
          _collectedSamples[address]?.add(sample);
        },
        onError: (error) {
          // Continue collecting from other devices even if one fails
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
      // Get current sample counts for all devices
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
    _testTimer?.cancel();
    _progressTimer?.cancel();

    // Cancel all data subscriptions
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

    // Evaluate each device
    for (final entry in _collectedSamples.entries) {
      final result = await evaluateDevice(entry.key, entry.value, _config);
      result.fold(
            (failure) {},
            (qaResult) => results.add(qaResult),
      );
    }

    // Stop sensors and disconnect
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
    emit(QaState.initial());
  }

  Future<void> _onCancel(CancelTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    emit(state.copyWith(
      phase: QaTestPhase.idle,
      statusMessage: 'Test cancelled',
    ));
  }

  Future<void> _cleanup() async {
    _testTimer?.cancel();
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