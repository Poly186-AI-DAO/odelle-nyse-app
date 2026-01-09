import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_routes.dart';
import 'constants/theme_constants.dart';
import 'config/digital_worker_config.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/voice_journal_screen.dart';
import 'screens/style_guide_screen.dart';
import 'services/google_auth_service.dart';
import 'services/openai_realtime/openai_webrtc_service.dart';
import 'services/openai_realtime/openai_session_service.dart';
import 'models/digital_worker_voice.dart';
import 'services/backend_api_service.dart';
import 'services/poly_auth_service.dart';
import 'services/azure_voice/azure_webrtc_service.dart';
import 'services/azure_speech_service.dart';
import 'providers/office_provider.dart';
import 'database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  // Using Ngrok for physical device support
  final backendBaseUrl = 'https://4b1db0965b44.ngrok-free.app';
  final polyAuthService = PolyAuthService(baseUrl: backendBaseUrl);
  final backendApiService = BackendApiService(baseUrl: backendBaseUrl);
  final googleAuthService = GoogleAuthService();
  final webrtcService = OpenAIWebRTCService();
  final sessionService = OpenAISessionService();

  // Initialize default config
  final defaultConfig = const DigitalWorkerConfig(
    voice: DigitalWorkerVoice.alloy,
    enableNoiseSuppression: true,
    enableEchoCancellation: true,
    enableAutoGainControl: true,
    vadThreshold: 0.5,
    prefixPaddingMs: 500,
    silenceDurationMs: 1000,
    maxRecordingDuration: 300,
    connectionTimeout: 30,
    instructions: '',
    enableDebugLogs: true,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<PolyAuthService>.value(value: polyAuthService),
        Provider<BackendApiService>.value(value: backendApiService),
        Provider<GoogleAuthService>(
          create: (_) => googleAuthService,
        ),
        Provider<OpenAIWebRTCService>(
          create: (_) => webrtcService,
        ),
        Provider<OpenAISessionService>(
          create: (_) => sessionService,
        ),
        Provider<AzureWebRTCService>(
          create: (_) => AzureWebRTCService(),
        ),
        Provider<AzureSpeechService>(
          create: (_) => AzureSpeechService(),
        ),
        Provider<AppDatabase>.value(value: AppDatabase.instance),
        ChangeNotifierProvider(
          create: (_) => OfficeProvider(),
        ),
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
      home: const DashboardScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case AppRoutes.voiceJournal:
            return MaterialPageRoute(
                builder: (_) => const VoiceJournalScreen());
          case AppRoutes.styleGuide:
            return MaterialPageRoute(builder: (_) => const StyleGuideScreen());
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
