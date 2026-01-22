import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to trigger voice recording from child screens
/// When set to true, HomeScreen picks it up and starts recording
/// HomeScreen then resets it to false
class VoiceTriggerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Request recording to be triggered
  void triggerRecording() {
    state = true;
  }

  /// Clear the trigger (called by HomeScreen after handling)
  void clearTrigger() {
    state = false;
  }
}

final voiceTriggerProvider =
    NotifierProvider<VoiceTriggerNotifier, bool>(VoiceTriggerNotifier.new);
