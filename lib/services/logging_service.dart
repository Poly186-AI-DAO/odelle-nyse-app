import 'package:logger/logger.dart';

class LoggingService {
  // Configure the logger
  // You can customize the printer for different log formats and colors
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the log output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: true, // Should each log print contain a timestamp
    ),
    // You can also set a custom output, for example, to write logs to a file
    // output: null,
    // Filter logs by level
    // level: Level.debug, // Only log messages with level 'debug' and above
  );

  // Log levels
  // Use these methods throughout your application for consistent logging

  static void verbose(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace); // 't' for trace, equivalent to verbose
  }

  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace); // 'f' for fatal
  }

  // Example of a custom log with a specific level and printer
  // static void customLog(String message) {
  //   final customLogger = Logger(printer: SimplePrinter(colors: true));
  //   customLogger.v("Custom Verbose: $message");
  // }
}
