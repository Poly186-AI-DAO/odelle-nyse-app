import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../models/agent_output.dart';

/// Bridge to iOS Live Activities via MethodChannel
/// Manages Dynamic Island and Lock Screen Live Activities for agent status
class LiveActivityService {
  static const String _tag = 'LiveActivityService';
  static const _channel = MethodChannel('com.poly186.odellenyse/live_activity');

  bool _isActive = false;
  String? _activityId;

  /// Start a Live Activity for agent processing
  Future<void> startAgentActivity({
    required AgentType agentType,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('start', {
        'agentType': agentType.name,
        'agentEmoji': agentType.emoji,
        'agentName': agentType.displayName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _activityId = result;
      _isActive = true;
      Logger.info('Started Live Activity: $_activityId', tag: _tag);
    } on PlatformException catch (e) {
      Logger.warning('Live Activity not available: ${e.message}', tag: _tag);
    } catch (e) {
      Logger.error('Failed to start Live Activity', tag: _tag, error: e);
    }
  }

  /// Update the current Live Activity with new status
  Future<void> updateActivity({
    required AgentType agentType,
    required String message,
    bool isError = false,
    bool isComplete = false,
  }) async {
    if (!_isActive || _activityId == null) {
      // No active activity, start one instead
      await startAgentActivity(agentType: agentType, message: message);
      return;
    }

    try {
      await _channel.invokeMethod('update', {
        'activityId': _activityId,
        'agentType': agentType.name,
        'agentEmoji': agentType.emoji,
        'agentName': agentType.displayName,
        'message': message,
        'isError': isError,
        'isComplete': isComplete,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Logger.info('Updated Live Activity: $message', tag: _tag);
    } on PlatformException catch (e) {
      Logger.warning('Failed to update Live Activity: ${e.message}', tag: _tag);
    }
  }

  /// End the current Live Activity
  Future<void> endActivity() async {
    if (!_isActive || _activityId == null) return;

    try {
      await _channel.invokeMethod('end', {
        'activityId': _activityId,
      });

      _isActive = false;
      _activityId = null;
      Logger.info('Ended Live Activity', tag: _tag);
    } on PlatformException catch (e) {
      Logger.warning('Failed to end Live Activity: ${e.message}', tag: _tag);
    }
  }

  /// Check if Live Activities are supported on this device
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  bool get isActive => _isActive;
}
