import 'package:flutter/foundation.dart';
import 'dart:convert';

class Logger {
  static void log(String message,
      {String? tag,
      Object? error,
      StackTrace? stackTrace,
      Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagStr = tag != null ? '[$tag]' : '';
      print('$timestamp$tagStr: $message');

      if (data != null) {
        try {
          final prettyData = const JsonEncoder.withIndent('  ').convert(data);
          print('Data: $prettyData');
        } catch (e) {
          print('Data: $data');
        }
      }

      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('StackTrace: $stackTrace');
        }
      }
    }
  }

  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, tag: tag, data: data);
  }

  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    log(message, tag: tag, data: data);
  }

  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    log('[WARN] $message', tag: tag, data: data);
  }

  static void error(String message,
      {String? tag,
      Object? error,
      StackTrace? stackTrace,
      Map<String, dynamic>? data}) {
    log(message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }
}
