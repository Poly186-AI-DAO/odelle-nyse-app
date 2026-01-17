import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/app_routes.dart';
import 'constants/theme_constants.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await dotenv.load();
    } catch (e) {
      Logger.warning('Failed to load .env file: $e');
    }

    try {
      await Firebase.initializeApp();
    } catch (e) {
      Logger.error('Failed to initialize Firebase: $e');
      runApp(ErrorApp(message: 'Firebase Init Failed: $e'));
      return;
    }

    // All services are now initialized via Riverpod providers
    // See lib/providers/service_providers.dart

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    Logger.error('Unhandled error in main', error: error, stackTrace: stack);
  });
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Startup Error:\n$message',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odelle Nyse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ThemeConstants.backgroundColor,
        fontFamily: 'Lato', // Default font
        primaryColor: ThemeConstants.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: ThemeConstants.primaryColor,
          secondary: ThemeConstants.uiInfo,
          surface: ThemeConstants.surfaceColor,
          error: ThemeConstants.errorColor,
          onPrimary: ThemeConstants.polyBlack,
          onSecondary: ThemeConstants.polyWhite,
          onSurface: ThemeConstants.textColor,
          onError: ThemeConstants.polyWhite,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
