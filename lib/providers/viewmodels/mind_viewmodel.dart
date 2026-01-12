import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../../models/character_stats.dart';
import '../../services/health_kit_service.dart';
import '../../utils/logger.dart';
import '../service_providers.dart';

// State class for Mind Screen
class MindState {
  final DateTime selectedDate;
  final double panelProgress; // 0.0 to 1.0
  
  // HealthKit Data
  final SleepData? sleepData;
  final int? restingHeartRate;
  final Duration? mindfulMinutes;
  
  // DB / JSON Data
  final CharacterStats? characterStats;
  final Map<String, dynamic>? identityData; // For astrology/cosmic stats
  final Map<String, dynamic>? sleepLogFallback; // JSON fallback
  
  final bool isLoading;
  final String? error;

  const MindState({
    required this.selectedDate,
    this.panelProgress = 0.0,
    this.sleepData,
    this.restingHeartRate,
    this.mindfulMinutes,
    this.characterStats,
    this.identityData,
    this.sleepLogFallback,
    this.isLoading = false,
    this.error,
  });

  MindState copyWith({
    DateTime? selectedDate,
    double? panelProgress,
    SleepData? sleepData,
    int? restingHeartRate,
    Duration? mindfulMinutes,
    CharacterStats? characterStats,
    Map<String, dynamic>? identityData,
    Map<String, dynamic>? sleepLogFallback,
    bool? isLoading,
    String? error,
  }) {
    return MindState(
      selectedDate: selectedDate ?? this.selectedDate,
      panelProgress: panelProgress ?? this.panelProgress,
      sleepData: sleepData ?? this.sleepData,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      mindfulMinutes: mindfulMinutes ?? this.mindfulMinutes,
      characterStats: characterStats ?? this.characterStats,
      identityData: identityData ?? this.identityData,
      sleepLogFallback: sleepLogFallback ?? this.sleepLogFallback,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MindViewModel extends Notifier<MindState> {
  late final HealthKitService _healthKit;

  @override
  MindState build() {
    _healthKit = ref.read(healthKitServiceProvider);
    final initialDate = DateTime.now();
    Future.microtask(() => loadData(initialDate));
    return MindState(selectedDate: initialDate);
  }

  void setPanelProgress(double progress) {
    if (state.panelProgress != progress) {
      state = state.copyWith(panelProgress: progress);
    }
  }

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, isLoading: true);
    await loadData(date);
  }

  Future<void> loadData(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. HealthKit Data
      SleepData? sleepData;
      int? restingHR;
      Duration? mindfulMinutes;

      final authorized = await _healthKit.requestAuthorization();
      if (authorized) {
        final results = await Future.wait([
          _healthKit.getLastNightSleep(),
          _healthKit.getRestingHeartRate(),
          _healthKit.getMindfulMinutes(date),
        ]);

        sleepData = results[0] as SleepData?;
        restingHR = results[1] as int?;
        mindfulMinutes = results[2] as Duration?;
      }

      // 2. Load JSON Data (Identity & Sleep Fallback)
      Map<String, dynamic>? identityData;
      Map<String, dynamic>? sleepLogFallback;

      final identityJson =
          await rootBundle.loadString('data/misc/character_stats.json');
      final List<dynamic> identityList = json.decode(identityJson);
      if (identityList.isNotEmpty) {
        identityData = identityList.last as Map<String, dynamic>;
      }

      if (sleepData == null) {
        final sleepJson =
            await rootBundle.loadString('data/tracking/sleep_log.json');
        final List<dynamic> sleepList = json.decode(sleepJson);
        if (sleepList.isNotEmpty) {
          sleepLogFallback = sleepList.last as Map<String, dynamic>;
        }
      }

      state = state.copyWith(
        sleepData: sleepData,
        restingHeartRate: restingHR,
        mindfulMinutes: mindfulMinutes,
        identityData: identityData,
        sleepLogFallback: sleepLogFallback,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      Logger.error('Error loading mind data',
          tag: 'MindViewModel', error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final mindViewModelProvider = NotifierProvider<MindViewModel, MindState>(MindViewModel.new);
