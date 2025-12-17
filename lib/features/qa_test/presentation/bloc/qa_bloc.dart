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
  Timer? _testTimer;
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
    on<CollectSamplesEvent>(_onCollectSamples);
    on<EvaluateResultsEvent>(_onEvaluateResults);
    on<ResetTestEvent>(_onReset);
    on<CancelTestEvent>(_onCancel);
  }

  Future<void> _onInitialize(
      InitializeQaEvent event, Emitter<QaState> emit) async {
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

  Future<void> _onStartScanning(
      StartScanningEvent event, Emitter<QaState> emit) async {
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
              (failure) => add(DeviceFoundEvent(
            name: 'Error',
            address: '',
            rssi: 0,
          )),
              (device) => add(DeviceFoundEvent(
            name: device.name,
            address: device.address,
            rssi: device.rssi,
          )),
        );
      },
    );
  }

  Future<void> _onDeviceFound(
      DeviceFoundEvent event, Emitter<QaState> emit) async {
    if (state.phase != QaTestPhase.scanning) return;

    final updatedDevices = List<BleDeviceInfo>.from(state.foundDevices);
    final exists =
    updatedDevices.any((device) => device.address == event.address);

    if (!exists) {
      updatedDevices.add(BleDeviceInfo(
        name: event.name,
        address: event.address,
        rssi: event.rssi,
      ));

      emit(state.copyWith(
        foundDevices: updatedDevices,
        statusMessage:
        'Found ${updatedDevices.length}/${state.targetDeviceCount} devices',
      ));

      if (updatedDevices.length >= state.targetDeviceCount) {
        add(ConnectDevicesEvent());
      }
    }
  }

  Future<void> _onStopScanning(
      StopScanningEvent event, Emitter<QaState> emit) async {
    await stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  Future<void> _onConnectDevices(
      ConnectDevicesEvent event, Emitter<QaState> emit) async {
    await stopScan();
    await _scanSubscription?.cancel();

    emit(state.copyWith(
      phase: QaTestPhase.connecting,
      statusMessage: 'Connecting to devices...',
    ));

    final connected = <String>[];

    for (final device in state.foundDevices) {
      emit(state.copyWith(
        statusMessage: 'Connecting to ${device.name}...',
      ));

      final result = await connectDevice(device.address);
      await result.fold(
            (failure) async {},
            (_) async {
          final startResult = await startSensors(device.address);
          await startResult.fold(
                (failure) async {},
                (_) async {
              connected.add(device.address);
            },
          );
        },
      );
    }

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
        statusMessage: 'Connected ${connected.length} device(s)',
      ));

      add(StartTestEvent());
    }
  }

  Future<void> _onStartTest(
      StartTestEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.settling,
      statusMessage: 'Settling for ${_config.settleSeconds}s...',
      progress: 0.0,
    ));

    for (final address in state.connectedDevices) {
      _dataSubscriptions[address] = getDataStream(address).listen(
            (sample) {},
      );
    }

    await Future.delayed(Duration(seconds: _config.settleSeconds.toInt()));

    emit(state.copyWith(
      phase: QaTestPhase.testing,
      deviceSamples: {for (var addr in state.connectedDevices) addr: []},
      statusMessage: 'Collecting samples for ${_config.testSeconds}s...',
      progress: 0.0,
    ));

    for (final address in state.connectedDevices) {
      await _dataSubscriptions[address]?.cancel();
      _dataSubscriptions[address] = getDataStream(address).listen(
            (sample) {
          add(CollectSamplesEvent());
        },
      );
    }

    _testTimer = Timer.periodic(
      const Duration(milliseconds: 100),
          (timer) {
        if (state.phase == QaTestPhase.testing) {
          final elapsed = timer.tick * 0.1;
          final progress = elapsed / _config.testSeconds;

          if (progress >= 1.0) {
            timer.cancel();
            add(EvaluateResultsEvent());
          }
        }
      },
    );

    Future.delayed(Duration(seconds: _config.testSeconds.toInt()), () {
      if (state.phase == QaTestPhase.testing) {
        add(EvaluateResultsEvent());
      }
    });
  }

  Future<void> _onCollectSamples(
      CollectSamplesEvent event, Emitter<QaState> emit) async {
    if (state.phase != QaTestPhase.testing) return;

    final updatedSamples = Map<String, List<ImuSample>>.from(state.deviceSamples);

    for (final address in state.connectedDevices) {
      final subscription = _dataSubscriptions[address];
      if (subscription != null) {
        updatedSamples[address] = updatedSamples[address] ?? [];
      }
    }
  }

  Future<void> _onEvaluateResults(
      EvaluateResultsEvent event, Emitter<QaState> emit) async {
    _testTimer?.cancel();

    for (final subscription in _dataSubscriptions.values) {
      await subscription.cancel();
    }
    _dataSubscriptions.clear();

    emit(state.copyWith(
      phase: QaTestPhase.evaluating,
      statusMessage: 'Evaluating results...',
      progress: 1.0,
    ));

    final Map<String, List<ImuSample>> finalSamples = {};

    for (final address in state.connectedDevices) {
      final samples = <ImuSample>[];

      await for (final sample in getDataStream(address).take(1000)) {
        samples.add(sample);
      }

      finalSamples[address] = samples;
    }

    final results = <QaResult>[];

    for (final entry in finalSamples.entries) {
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
      deviceSamples: finalSamples,
      statusMessage: 'Test completed',
      progress: 1.0,
    ));
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
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}