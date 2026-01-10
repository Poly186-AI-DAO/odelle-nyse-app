import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/app_routes.dart';
import 'constants/theme_constants.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // All services are now initialized via Riverpod providers
  // See lib/providers/service_providers.dart

  runApp(
    const ProviderScope(
      child: MyApp(),
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
