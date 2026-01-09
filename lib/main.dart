import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'constants/app_routes.dart';
import 'constants/theme_constants.dart';
import 'screens/home_screen.dart';
import 'services/google_auth_service.dart';
import 'services/backend_api_service.dart';
import 'services/poly_auth_service.dart';
import 'services/azure_speech_service.dart';
import 'providers/office_provider.dart';
import 'database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize services
  final backendBaseUrl = 'https://4b1db0965b44.ngrok-free.app';
  final polyAuthService = PolyAuthService(baseUrl: backendBaseUrl);
  final backendApiService = BackendApiService(baseUrl: backendBaseUrl);
  final googleAuthService = GoogleAuthService();

  // Singleton voice service - shared across app
  final voiceService = AzureSpeechService();

  runApp(
    MultiProvider(
      providers: [
        Provider<PolyAuthService>.value(value: polyAuthService),
        Provider<BackendApiService>.value(value: backendApiService),
        Provider<GoogleAuthService>.value(value: googleAuthService),
        Provider<AzureSpeechService>.value(value: voiceService),
        Provider<AppDatabase>.value(value: AppDatabase.instance),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
