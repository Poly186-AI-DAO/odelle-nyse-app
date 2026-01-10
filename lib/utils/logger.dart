import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Log entry for in-memory buffer
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String? tag;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    this.tag,
    required this.message,
  });

  String get formatted {
    final ts = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final tagStr = tag != null ? '[$tag]' : '';
    return '$ts $level$tagStr $message';
  }
}

class Logger {
  // In-memory buffer for recent logs (circular buffer, max 100 entries)
  static const int _maxBufferSize = 100;
  static final List<LogEntry> _buffer = [];

  /// Get all buffered log entries
  static List<LogEntry> get logs => List.unmodifiable(_buffer);

  /// Clear the log buffer
  static void clearLogs() => _buffer.clear();

  static void _addToBuffer(String level, String message, String? tag) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _buffer.add(entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }
  }

  static void log(String message,
      {String? tag,
      Object? error,
      StackTrace? stackTrace,
      Map<String, dynamic>? data}) {
    _addToBuffer('LOG', message, tag);

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
    _addToBuffer('INFO', message, tag);
    log(message, tag: tag, data: data);
  }

  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _addToBuffer('DEBUG', message, tag);
    log(message, tag: tag, data: data);
  }

  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    _addToBuffer('WARN', message, tag);
    log('[WARN] $message', tag: tag, data: data);
  }

  static void error(String message,
      {String? tag,
      Object? error,
      StackTrace? stackTrace,
      Map<String, dynamic>? data}) {
    _addToBuffer('ERROR', message, tag);
    log(message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }
}
