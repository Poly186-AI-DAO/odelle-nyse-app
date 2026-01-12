import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_kit/weather_kit.dart';

/// Data class for current weather conditions
class CurrentWeather {
  final double temperature; // Celsius
  final double feelsLike; // Celsius
  final double humidity; // 0-100%
  final double windSpeed; // km/h
  final String condition; // "Clear", "Cloudy", "Rain", etc.
  final String conditionDescription; // "Partly cloudy"
  final String iconName; // SF Symbol name
  final DateTime asOf;
  final bool isDaylight;
  final double? uvIndex;
  final double? visibility; // meters
  final double? pressure; // mb

  CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.conditionDescription,
    required this.iconName,
    required this.asOf,
    required this.isDaylight,
    this.uvIndex,
    this.visibility,
    this.pressure,
  });

  /// Get temperature in Fahrenheit
  double get temperatureF => (temperature * 9 / 5) + 32;
  double get feelsLikeF => (feelsLike * 9 / 5) + 32;

  /// Get a simple emoji for the condition
  String get emoji {
    switch (condition.toLowerCase()) {
      case 'clear':
        return isDaylight ? '☀️' : '🌙';
      case 'cloudy':
      case 'mostlycloudy':
        return '☁️';
      case 'partlycloudy':
        return isDaylight ? '⛅' : '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'heavyrain':
        return '⛈️';
      case 'thunderstorms':
        return '⛈️';
      case 'snow':
      case 'flurries':
        return '🌨️';
      case 'sleet':
      case 'freezingrain':
        return '🌨️';
      case 'haze':
      case 'fog':
        return '🌫️';
      case 'windy':
        return '💨';
      default:
        return '🌤️';
    }
  }

  /// Get a brief morning greeting based on weather
  String get morningGreeting {
    if (temperature < 0) {
      return "It's freezing out there! Bundle up.";
    } else if (temperature < 10) {
      return "Cold morning - grab a jacket.";
    } else if (temperature < 20) {
      return "Nice and cool today.";
    } else if (temperature < 30) {
      return "Warm weather ahead.";
    } else {
      return "Hot day - stay hydrated!";
    }
  }
}

/// Data class for daily forecast
class DailyForecast {
  final DateTime date;
  final double highTemp; // Celsius
  final double lowTemp; // Celsius
  final String condition;
  final String iconName;
  final double precipitationChance; // 0-1

  DailyForecast({
    required this.date,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
    required this.iconName,
    required this.precipitationChance,
  });

  double get highTempF => (highTemp * 9 / 5) + 32;
  double get lowTempF => (lowTemp * 9 / 5) + 32;
}

/// Service for fetching weather data from Apple WeatherKit
///
/// Requires:
/// 1. WeatherKit capability enabled in Apple Developer Portal
/// 2. WeatherKit entitlement in Runner.entitlements
/// 3. Location permission from user
/// 4. A WeatherKit key from Apple Developer (p8 file)
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal() {
    // Auto-configure from dotenv on instantiation
    _configureFromEnv();
  }

  final WeatherKit _weatherKit = WeatherKit();

  String? _teamId;
  String? _keyId;
  String? _privateKey;
  String? _bundleId;

  /// Auto-configure from environment variables
  void _configureFromEnv() {
    final teamId = dotenv.env['WEATHER_TEAM_ID'];
    final keyId = dotenv.env['WEATHER_KEY_ID'];
    final privateKey = dotenv.env['WEATHER_PRIVATE_KEY'];
    final bundleId = dotenv.env['WEATHER_BUNDLE_ID'] ?? 'com.poly186.odelle';

    if (teamId != null && keyId != null && privateKey != null) {
      configure(
        teamId: teamId,
        keyId: keyId,
        privateKey: privateKey,
        bundleId: bundleId,
      );
    }
  }

  String? _jwt;
  DateTime? _jwtExpiry;

  Position? _lastPosition;
  CurrentWeather? _cachedWeather;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 15);
  static const _jwtDuration = Duration(hours: 1);

  /// Initialize the WeatherKit client with Apple credentials
  ///
  /// [teamId] - Your Apple Developer Team ID
  /// [keyId] - The Key ID for your WeatherKit key
  /// [privateKey] - The contents of your .p8 file (the PEM key)
  /// [bundleId] - Your app's bundle identifier
  void configure({
    required String teamId,
    required String keyId,
    required String privateKey,
    required String bundleId,
  }) {
    _teamId = teamId;
    _keyId = keyId;
    _privateKey = privateKey;
    _bundleId = bundleId;
    debugPrint('[Weather] WeatherKit configured');
  }

  /// Check if WeatherKit is configured
  bool get isConfigured =>
      _teamId != null &&
      _keyId != null &&
      _privateKey != null &&
      _bundleId != null;

  /// Generate or return cached JWT token
  String? _getJWT() {
    // Return cached token if still valid
    if (_jwt != null &&
        _jwtExpiry != null &&
        DateTime.now().isBefore(_jwtExpiry!)) {
      return _jwt;
    }

    if (!isConfigured) {
      debugPrint('[Weather] WeatherKit not configured');
      return null;
    }

    try {
      _jwt = _weatherKit.generateJWT(
        bundleId: _bundleId!,
        teamId: _teamId!,
        keyId: _keyId!,
        pem: _privateKey!,
        expiresIn: _jwtDuration,
      );
      _jwtExpiry = DateTime.now().add(_jwtDuration);
      debugPrint('[Weather] Generated new JWT');
      return _jwt;
    } catch (e) {
      debugPrint('[Weather] Error generating JWT: $e');
      return null;
    }
  }

  /// Get current location with permission handling
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[Weather] Location services disabled');
        return null;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[Weather] Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[Weather] Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // Low accuracy is fine for weather
          timeLimit: Duration(seconds: 10),
        ),
      );

      _lastPosition = position;
      debugPrint(
          '[Weather] Got location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[Weather] Error getting location: $e');
      return _lastPosition; // Return cached position if available
    }
  }

  /// Get current weather conditions
  /// Returns cached data if less than 15 minutes old
  Future<CurrentWeather?> getCurrentWeather({bool forceRefresh = false}) async {
    // Return cache if valid
    if (!forceRefresh &&
        _cachedWeather != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      debugPrint('[Weather] Returning cached weather');
      return _cachedWeather;
    }

    final jwt = _getJWT();
    if (jwt == null) {
      debugPrint('[Weather] No JWT available');
      return _cachedWeather;
    }

    final position = await _getCurrentLocation();
    if (position == null) {
      debugPrint('[Weather] No location available');
      return _cachedWeather;
    }

    try {
      final current = await _weatherKit.obtainWeatherData(
        jwt: jwt,
        language: 'en',
        latitude: position.latitude,
        longitude: position.longitude,
        dataSets: DataSet.currentWeather,
        timezone: DateTime.now().timeZoneName,
      );

      final conditionCode = current.conditionCode;
      final isDaylight = current.daylight ?? true;

      _cachedWeather = CurrentWeather(
        temperature: current.temperature,
        feelsLike: current.temperatureApparent,
        humidity: (current.humidity * 100),
        windSpeed: current.windSpeed,
        condition: conditionCode,
        conditionDescription: _getConditionDescription(conditionCode),
        iconName: _getSFSymbolName(conditionCode, isDaylight),
        asOf: current.asOf,
        isDaylight: isDaylight,
        uvIndex: current.uvIndex.toDouble(),
        visibility: current.visibility,
        pressure: current.pressure,
      );

      _cacheTime = DateTime.now();
      debugPrint(
          '[Weather] Current: ${_cachedWeather!.temperature.round()}°C, ${_cachedWeather!.condition}');

      return _cachedWeather;
    } catch (e) {
      debugPrint('[Weather] Error fetching weather: $e');
      return _cachedWeather; // Return stale cache on error
    }
  }

  /// Get weather forecast for the next few days
  /// NOTE: The weather_kit package only supports currentWeather dataset.
  /// Daily forecast would require direct API calls or a different package.
  Future<List<DailyForecast>> getDailyForecast({int days = 5}) async {
    // TODO: Implement when weather_kit supports forecastDaily
    // For now, return empty list - focus on current weather
    debugPrint('[Weather] Daily forecast not yet implemented');
    return [];
  }

  /// Get a human-readable description of the weather condition
  String _getConditionDescription(String? code) {
    if (code == null) return 'Unknown';

    final descriptions = {
      'Clear': 'Clear skies',
      'Cloudy': 'Cloudy',
      'MostlyCloudy': 'Mostly cloudy',
      'PartlyCloudy': 'Partly cloudy',
      'MostlyClear': 'Mostly clear',
      'Drizzle': 'Light drizzle',
      'Rain': 'Rain',
      'HeavyRain': 'Heavy rain',
      'Thunderstorms': 'Thunderstorms',
      'Snow': 'Snow',
      'Flurries': 'Snow flurries',
      'Sleet': 'Sleet',
      'FreezingRain': 'Freezing rain',
      'Haze': 'Hazy',
      'Fog': 'Foggy',
      'Windy': 'Windy',
      'Breezy': 'Breezy',
      'Hot': 'Hot',
      'Frigid': 'Frigid',
    };

    return descriptions[code] ?? code;
  }

  /// Get the SF Symbol name for a weather condition
  String _getSFSymbolName(String? code, bool? daylight) {
    final isDay = daylight ?? true;

    final symbols = {
      'Clear': isDay ? 'sun.max.fill' : 'moon.stars.fill',
      'Cloudy': 'cloud.fill',
      'MostlyCloudy': 'cloud.fill',
      'PartlyCloudy': isDay ? 'cloud.sun.fill' : 'cloud.moon.fill',
      'MostlyClear': isDay ? 'sun.max.fill' : 'moon.fill',
      'Drizzle': 'cloud.drizzle.fill',
      'Rain': 'cloud.rain.fill',
      'HeavyRain': 'cloud.heavyrain.fill',
      'Thunderstorms': 'cloud.bolt.rain.fill',
      'Snow': 'cloud.snow.fill',
      'Flurries': 'cloud.snow.fill',
      'Sleet': 'cloud.sleet.fill',
      'FreezingRain': 'cloud.sleet.fill',
      'Haze': 'sun.haze.fill',
      'Fog': 'cloud.fog.fill',
      'Windy': 'wind',
      'Breezy': 'wind',
    };

    return symbols[code] ?? 'cloud.fill';
  }

  /// Clear cached weather data
  void clearCache() {
    _cachedWeather = null;
    _cacheTime = null;
    debugPrint('[Weather] Cache cleared');
  }
}
