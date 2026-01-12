import 'package:equatable/equatable.dart';
import '../../models/digital_worker_voice.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}



// Digital Worker Settings Events
class UpdateVoiceEvent extends SettingsEvent {
  final DigitalWorkerVoice voice;

  const UpdateVoiceEvent(this.voice);

  @override
  List<Object?> get props => [voice];
}

class ToggleNoiseSuppressionEvent extends SettingsEvent {}

class ToggleEchoCancellationEvent extends SettingsEvent {}

class ToggleAutoGainControlEvent extends SettingsEvent {}

class UpdateVadThresholdEvent extends SettingsEvent {
  final double threshold;

  const UpdateVadThresholdEvent(this.threshold);

  @override
  List<Object?> get props => [threshold];
}

class UpdatePrefixPaddingEvent extends SettingsEvent {
  final int paddingMs;

  const UpdatePrefixPaddingEvent(this.paddingMs);

  @override
  List<Object?> get props => [paddingMs];
}

class UpdateSilenceDurationEvent extends SettingsEvent {
  final int durationMs;

  const UpdateSilenceDurationEvent(this.durationMs);

  @override
  List<Object?> get props => [durationMs];
}

class UpdateMaxRecordingDurationEvent extends SettingsEvent {
  final int durationSeconds;

  const UpdateMaxRecordingDurationEvent(this.durationSeconds);

  @override
  List<Object?> get props => [durationSeconds];
}

class UpdateConnectionTimeoutEvent extends SettingsEvent {
  final int timeoutSeconds;

  const UpdateConnectionTimeoutEvent(this.timeoutSeconds);

  @override
  List<Object?> get props => [timeoutSeconds];
}

class UpdateInstructionsEvent extends SettingsEvent {
  final String instructions;

  const UpdateInstructionsEvent(this.instructions);

  @override
  List<Object?> get props => [instructions];
}
