import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/entities/imu_entities.dart';
import '../../../../core/localization/app_translations.dart';
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
  StreamSubscription? _dataSubscription;
  final Map<String, List<ImuSample>> _collectedSamples = {};
  Timer? _progressTimer;
  final QaConfig _config = const QaConfig();
  final Map<String, int> _saturationCounts = {};

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
    on<ToggleLanguageEvent>(_onToggleLanguage);
    on<StartTestEvent>(_onStartTest);
    on<DeviceFoundEvent>(_onDeviceFound);
    on<ConnectFirstDeviceEvent>(_onConnectFirstDevice);
    on<StartSensorsEvent>(_onStartSensors);
    on<StartDataCollectionEvent>(_onStartDataCollection);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<HardFailDetectedEvent>(_onHardFailDetected);
    on<EvaluateResultEvent>(_onEvaluateResult);
    on<RetryTestEvent>(_onRetryTest);
    on<TestNextDeviceEvent>(_onTestNextDevice);
    on<DiscardDeviceEvent>(_onDiscardDevice);
    on<StopTestEvent>(_onStopTest);
    on<ResetTestEvent>(_onReset);
  }

  String _t(String key, {List<String>? args}) {
    return AppTranslations.translate(key, state.currentLanguage, args: args);
  }

  Future<void> _onInitialize(InitializeQaEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.initializing,
      statusMessage: _t('initializing'),
    ));

    final result = await initializeBle();
    result.fold(
          (failure) => emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: failure.message,
        statusMessage: _t('error'),
      )),
          (_) => emit(state.copyWith(
        phase: QaTestPhase.idle,
        statusMessage: _t('readyToStart'),
      )),
    );
  }

  Future<void> _onToggleLanguage(ToggleLanguageEvent event, Emitter<QaState> emit) async {
    final newLang = state.currentLanguage == 'zh' ? 'en' : 'zh';
    emit(state.copyWith(currentLanguage: newLang));
  }

  Future<void> _onStartTest(StartTestEvent event, Emitter<QaState> emit) async {
    emit(state.copyWith(
      phase: QaTestPhase.scanning,
      foundDevices: [],
      statusMessage: _t('scanningForDevices'),
      clearSession: true,
      clearResult: true,
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

      emit(state.copyWith(foundDevices: updatedDevices));

      // Auto-connect to first RA device found
      if (updatedDevices.length == 1) {
        add(const ConnectFirstDeviceEvent());
      }
    }
  }

  Future<void> _onConnectFirstDevice(ConnectFirstDeviceEvent event, Emitter<QaState> emit) async {
    await stopScan();
    await _scanSubscription?.cancel();

    if (state.foundDevices.isEmpty) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'No devices found',
      ));
      return;
    }

    final device = state.foundDevices.first;

    // Initialize session if new device
    final session = state.currentSession ?? DeviceTestSession(
      macAddress: device.address,
      deviceName: device.name,
      currentAttempt: 1,
    );

    emit(state.copyWith(
      phase: QaTestPhase.connecting,
      currentSession: session,
      statusMessage: _t('connecting'),
    ));

    final connectResult = await connectDevice(device.address);
    final connected = await connectResult.fold(
          (failure) async => false,
          (_) async => true,
    );

    if (!connected) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'Failed to connect',
      ));
      return;
    }

    emit(state.copyWith(connectedDeviceAddress: device.address));
    add(const StartSensorsEvent());
  }

  Future<void> _onStartSensors(StartSensorsEvent event, Emitter<QaState> emit) async {
    final address = state.connectedDeviceAddress;
    if (address == null) return;

    final startResult = await startSensors(address);
    final started = await startResult.fold(
          (failure) async => false,
          (_) async => true,
    );

    if (!started) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'Failed to start sensors',
      ));
      return;
    }

    // Set up data stream
    _collectedSamples[address] = [];
    _saturationCounts[address] = 0;

    await _dataSubscription?.cancel();
    _dataSubscription = getDataStream(address).listen(
          (sample) {
        _collectedSamples[address]?.add(sample);

        if (state.phase == QaTestPhase.testing) {
          final rawValues = [
            sample.rawAx.abs(),
            sample.rawAy.abs(),
            sample.rawAz.abs(),
            sample.rawGx.abs(),
            sample.rawGy.abs(),
            sample.rawGz.abs(),
          ];

          if (rawValues.any((v) => v >= _config.saturationThreshold)) {
            _saturationCounts[address] = (_saturationCounts[address] ?? 0) + 1;

            if (_saturationCounts[address]! > 5) {
              add(HardFailDetectedEvent(address));
            }
          }
        }
      },
    );

    // Verify data stream
    await Future.delayed(const Duration(seconds: 1));
    final beforeCount = _collectedSamples[address]?.length ?? 0;
    await Future.delayed(const Duration(seconds: 1));
    final afterCount = _collectedSamples[address]?.length ?? 0;

    if (afterCount <= beforeCount) {
      emit(state.copyWith(
        phase: QaTestPhase.error,
        errorMessage: 'No data received from sensor',
      ));
      return;
    }

    add(const StartDataCollectionEvent());
  }

  Future<void> _onStartDataCollection(StartDataCollectionEvent event, Emitter<QaState> emit) async {
    final address = state.connectedDeviceAddress;
    if (address == null) return;

    // Settling phase
    emit(state.copyWith(
      phase: QaTestPhase.settling,
      statusMessage: _t('settling', args: [_config.settleSeconds.toStringAsFixed(0)]),
      progress: 0.0,
    ));

    await Future.delayed(Duration(seconds: _config.settleSeconds.toInt()));

    // Clear samples after settling
    _collectedSamples[address]?.clear();
    _saturationCounts[address] = 0;

    // Testing phase
    emit(state.copyWith(
      phase: QaTestPhase.testing,
      statusMessage: _t('collecting'),
      progress: 0.0,
    ));

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
          add(const EvaluateResultEvent());
        }
      },
    );
  }

  Future<void> _onUpdateProgress(UpdateProgressEvent event, Emitter<QaState> emit) async {
    if (state.phase == QaTestPhase.testing) {
      final address = state.connectedDeviceAddress;
      final count = address != null ? (_collectedSamples[address]?.length ?? 0) : 0;

      emit(state.copyWith(
        progress: event.progress,
        sampleCounts: {if (address != null) address: count},
      ));
    }
  }

  Future<void> _onHardFailDetected(HardFailDetectedEvent event, Emitter<QaState> emit) async {
    _progressTimer?.cancel();
    add(const EvaluateResultEvent());
  }

  Future<void> _onEvaluateResult(EvaluateResultEvent event, Emitter<QaState> emit) async {
    _progressTimer?.cancel();
    // DON'T cancel data subscription - needed for retry

    final address = state.connectedDeviceAddress;
    if (address == null || state.currentSession == null) return;

    emit(state.copyWith(
      phase: QaTestPhase.evaluating,
      statusMessage: _t('evaluating'),
      progress: 1.0,
    ));

    final samples = _collectedSamples[address] ?? [];
    final result = await evaluateDevice(address, samples, _config);

    await result.fold(
          (failure) async {
        emit(state.copyWith(
          phase: QaTestPhase.error,
          errorMessage: failure.message,
        ));
      },
          (qaResult) async {
        final updatedResult = QaResult(
          deviceId: qaResult.deviceId,
          macAddress: state.currentSession!.macAddress,
          passed: qaResult.passed,
          failureReason: qaResult.failureReason,
          saturationCount: qaResult.saturationCount,
          spikeCount: qaResult.spikeCount,
          maxAbsRaw: qaResult.maxAbsRaw,
          maxDelta: qaResult.maxDelta,
          attemptNumber: state.currentSession!.currentAttempt,
        );

        // Update session with result
        final updatedResults = List<QaResult>.from(state.currentSession!.attemptResults)
          ..add(updatedResult);

        final updatedSession = state.currentSession!.copyWith(
          attemptResults: updatedResults,
        );

        // Disconnect only if passed or final fail (attempt 3)
        if (updatedResult.passed || state.currentSession!.currentAttempt >= 3) {
          await _dataSubscription?.cancel();
          await stopSensors(address);
          await disconnectDevice(address);
        }

        emit(state.copyWith(
          phase: QaTestPhase.completed,
          currentSession: updatedSession,
          currentResult: updatedResult,
          statusMessage: _t('completed'),
        ));
      },
    );
  }

  Future<void> _onRetryTest(RetryTestEvent event, Emitter<QaState> emit) async {
    if (state.currentSession == null) return;

    final updatedSession = state.currentSession!.copyWith(
      currentAttempt: state.currentSession!.currentAttempt + 1,
    );

    emit(state.copyWith(
      currentSession: updatedSession,
      clearResult: true,
    ));

    // Don't disconnect - reuse connection, just restart data collection
    add(const StartDataCollectionEvent());
  }

  Future<void> _onTestNextDevice(TestNextDeviceEvent event, Emitter<QaState> emit) async {
    // Already disconnected in evaluate result

    // Add to passed devices
    if (state.currentResult != null && state.currentResult!.passed) {
      final passed = List<QaResult>.from(state.passedDevices)..add(state.currentResult!);
      emit(state.copyWith(
        passedDevices: passed,
        clearSession: true,
        clearResult: true,
        connectedDeviceAddress: null,
        phase: QaTestPhase.idle,
      ));
    }
  }

  Future<void> _onDiscardDevice(DiscardDeviceEvent event, Emitter<QaState> emit) async {
    if (state.currentSession == null) return;

    // Already disconnected in evaluate result

    final badDevice = BadDevice(
      macAddress: state.currentSession!.macAddress,
      deviceName: state.currentSession!.deviceName,
      failedAt: DateTime.now(),
    );

    final bad = List<BadDevice>.from(state.badDevices)..add(badDevice);

    emit(state.copyWith(
      badDevices: bad,
      clearSession: true,
      clearResult: true,
      connectedDeviceAddress: null,
      phase: QaTestPhase.idle,
    ));
  }

  Future<void> _onStopTest(StopTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    emit(state.copyWith(
      phase: QaTestPhase.idle,
      clearSession: true,
      clearResult: true,
      progress: 0.0,
      foundDevices: [],
      connectedDeviceAddress: null,
    ));
  }

  Future<void> _onReset(ResetTestEvent event, Emitter<QaState> emit) async {
    await _cleanup();
    emit(QaState.initial().copyWith(
      currentLanguage: state.currentLanguage,
      badDevices: state.badDevices,
      passedDevices: state.passedDevices,
    ));
    add(const InitializeQaEvent());
  }

  Future<void> _cleanup() async {
    _progressTimer?.cancel();
    await _scanSubscription?.cancel();
    await _dataSubscription?.cancel();

    if (state.connectedDeviceAddress != null) {
      await stopSensors(state.connectedDeviceAddress!);
      await disconnectDevice(state.connectedDeviceAddress!);
    }

    await stopScan();
    _collectedSamples.clear();
    _saturationCounts.clear();
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}