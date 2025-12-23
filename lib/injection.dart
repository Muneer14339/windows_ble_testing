import 'package:get_it/get_it.dart';
import 'features/qa_test/data/datasources/ble_datasource.dart';
import 'features/qa_test/data/datasources/excel_datasource.dart'; // NEW
import 'features/qa_test/data/repositories/qa_repository_impl.dart';
import 'features/qa_test/domain/repository/qa_repository.dart';
import 'features/qa_test/domain/usecases/qa_usecases.dart';
import 'features/qa_test/presentation/bloc/qa_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(
        () => QaBloc(
      initializeBle: sl(),
      scanDevices: sl(),
      stopScan: sl(),
      connectDevice: sl(),
      startSensors: sl(),
      stopSensors: sl(),
      getDataStream: sl(),
      evaluateDevice: sl(),
      disconnectDevice: sl(),
      exportToExcel: sl(), // NEW
    ),
  );

  sl.registerLazySingleton(() => InitializeBle(sl()));
  sl.registerLazySingleton(() => ScanDevices(sl()));
  sl.registerLazySingleton(() => StopScan(sl()));
  sl.registerLazySingleton(() => ConnectDevice(sl()));
  sl.registerLazySingleton(() => DisconnectDevice(sl()));
  sl.registerLazySingleton(() => StartSensors(sl()));
  sl.registerLazySingleton(() => StopSensors(sl()));
  sl.registerLazySingleton(() => GetDataStream(sl()));
  sl.registerLazySingleton(() => EvaluateDevice(sl()));
  sl.registerLazySingleton(() => ExportToExcel(sl())); // NEW

  sl.registerLazySingleton<QaRepository>(
        () => QaRepositoryImpl(sl(), sl()), // UPDATED
  );

  sl.registerLazySingleton<BleDataSource>(
        () => BleDataSourceImpl(),
  );

  sl.registerLazySingleton<ExcelDataSource>( // NEW
        () => ExcelDataSourceImpl(),
  );
}