import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'injection.dart' as di;
import 'features/qa_test/presentation/bloc/qa_bloc.dart';
import 'features/qa_test/presentation/pages/qa_test_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(850, 650));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMU QA Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: const Color(0xFF0A0E27),
          surface: const Color(0xFF151B35),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: BlocProvider(
        create: (_) => di.sl<QaBloc>(),
        child: const QaTestPage(),
      ),
    );
  }
}