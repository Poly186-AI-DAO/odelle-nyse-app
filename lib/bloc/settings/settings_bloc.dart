import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/digital_worker_voice.dart';
import '../../config/digital_worker_config.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences _prefs;

  SettingsBloc({
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);


    // Digital Worker Settings
    on<UpdateVoiceEvent>(_onUpdateVoice);
    on<ToggleNoiseSuppressionEvent>(_onToggleNoiseSuppression);
    on<ToggleEchoCancellationEvent>(_onToggleEchoCancellation);
    on<ToggleAutoGainControlEvent>(_onToggleAutoGainControl);
    on<UpdateVadThresholdEvent>(_onUpdateVadThreshold);
    on<UpdatePrefixPaddingEvent>(_onUpdatePrefixPadding);
    on<UpdateSilenceDurationEvent>(_onUpdateSilenceDuration);
    on<UpdateMaxRecordingDurationEvent>(_onUpdateMaxRecordingDuration);
    on<UpdateConnectionTimeoutEvent>(_onUpdateConnectionTimeout);
    on<UpdateInstructionsEvent>(_onUpdateInstructions);
  }

  // Digital Worker Settings Handlers
  void _onUpdateVoice(UpdateVoiceEvent event, Emitter<SettingsState> emit) {
    _prefs.setString('voice', event.voice.name);
    emit(state.copyWith(voice: event.voice));
  }

  void _onToggleNoiseSuppression(
    ToggleNoiseSuppressionEvent event,
    Emitter<SettingsState> emit,
  ) {
    final newValue = !state.enableNoiseSuppression;
    _prefs.setBool('enableNoiseSuppression', newValue);
    emit(state.copyWith(enableNoiseSuppression: newValue));
  }

  void _onToggleEchoCancellation(
    ToggleEchoCancellationEvent event,
    Emitter<SettingsState> emit,
  ) {
    final newValue = !state.enableEchoCancellation;
    _prefs.setBool('enableEchoCancellation', newValue);
    emit(state.copyWith(enableEchoCancellation: newValue));
  }

  void _onToggleAutoGainControl(
    ToggleAutoGainControlEvent event,
    Emitter<SettingsState> emit,
  ) {
    final newValue = !state.enableAutoGainControl;
    _prefs.setBool('enableAutoGainControl', newValue);
    emit(state.copyWith(enableAutoGainControl: newValue));
  }

  void _onUpdateVadThreshold(
    UpdateVadThresholdEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setDouble('vadThreshold', event.threshold);
    emit(state.copyWith(vadThreshold: event.threshold));
  }

  void _onUpdatePrefixPadding(
    UpdatePrefixPaddingEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setInt('prefixPaddingMs', event.paddingMs);
    emit(state.copyWith(prefixPaddingMs: event.paddingMs));
  }

  void _onUpdateSilenceDuration(
    UpdateSilenceDurationEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setInt('silenceDurationMs', event.durationMs);
    emit(state.copyWith(silenceDurationMs: event.durationMs));
  }

  void _onUpdateMaxRecordingDuration(
    UpdateMaxRecordingDurationEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setInt('maxRecordingDuration', event.durationSeconds);
    emit(state.copyWith(maxRecordingDuration: event.durationSeconds));
  }

  void _onUpdateConnectionTimeout(
    UpdateConnectionTimeoutEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setInt('connectionTimeout', event.timeoutSeconds);
    emit(state.copyWith(connectionTimeout: event.timeoutSeconds));
  }

  void _onUpdateInstructions(
    UpdateInstructionsEvent event,
    Emitter<SettingsState> emit,
  ) {
    _prefs.setString('instructions', event.instructions);
    emit(state.copyWith(instructions: event.instructions));
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // Load saved digital worker settings
      const defaultConfig = DigitalWorkerConfig();
      final instructions =
          _prefs.getString('instructions') ?? defaultConfig.instructions;
      final voice = DigitalWorkerVoice.values.firstWhere(
        (v) => v.name == (_prefs.getString('voice') ?? 'alloy'),
        orElse: () => DigitalWorkerVoice.alloy,
      );
      final enableNoiseSuppression = _prefs.getBool('enableNoiseSuppression') ??
          defaultConfig.enableNoiseSuppression;
      final enableEchoCancellation = _prefs.getBool('enableEchoCancellation') ??
          defaultConfig.enableEchoCancellation;
      final enableAutoGainControl = _prefs.getBool('enableAutoGainControl') ??
          defaultConfig.enableAutoGainControl;
      final vadThreshold =
          _prefs.getDouble('vadThreshold') ?? defaultConfig.vadThreshold;
      final prefixPaddingMs =
          _prefs.getInt('prefixPaddingMs') ?? defaultConfig.prefixPaddingMs;
      final silenceDurationMs =
          _prefs.getInt('silenceDurationMs') ?? defaultConfig.silenceDurationMs;
      final maxRecordingDuration = _prefs.getInt('maxRecordingDuration') ??
          defaultConfig.maxRecordingDuration;
      final connectionTimeout =
          _prefs.getInt('connectionTimeout') ?? defaultConfig.connectionTimeout;

      emit(state.copyWith(
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        isCalendarEnabled: false,
        isDriveEnabled: false,
        isGmailEnabled: false,
        isLoading: false,
        instructions: instructions,
        voice: voice,
        enableNoiseSuppression: enableNoiseSuppression,
        enableEchoCancellation: enableEchoCancellation,
        enableAutoGainControl: enableAutoGainControl,
        vadThreshold: vadThreshold,
        prefixPaddingMs: prefixPaddingMs,
        silenceDurationMs: silenceDurationMs,
        maxRecordingDuration: maxRecordingDuration,
        connectionTimeout: connectionTimeout,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }


}
