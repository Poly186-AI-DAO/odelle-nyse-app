import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tracking/dose_log.dart';
import '../../models/tracking/supplement.dart';
import '../../repositories/dose_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for dose tracking.
class DoseState {
  final List<Supplement> supplements;
  final List<DoseLog> doseLogs;
  final bool isLoading;
  final String? error;

  const DoseState({
    this.supplements = const [],
    this.doseLogs = const [],
    this.isLoading = false,
    this.error,
  });

  DoseState copyWith({
    List<Supplement>? supplements,
    List<DoseLog>? doseLogs,
    bool? isLoading,
    String? error,
  }) {
    return DoseState(
      supplements: supplements ?? this.supplements,
      doseLogs: doseLogs ?? this.doseLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for dose tracking.
class DoseViewModel extends Notifier<DoseState> {
  static const String _tag = 'DoseViewModel';

  @override
  DoseState build() {
    return const DoseState();
  }

  DoseRepository get _repository => ref.read(doseRepositoryProvider);

  Future<void> load({
    DateTime? startDate,
    DateTime? endDate,
    int? supplementId,
    bool activeSupplementsOnly = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final supplements =
          await _repository.getSupplements(activeOnly: activeSupplementsOnly);
      final doseLogs = await _repository.getDoseLogs(
        supplementId: supplementId,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        supplements: supplements,
        doseLogs: doseLogs,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to load dose data',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logDose({
    required int supplementId,
    required double amountMg,
    DateTime? timestamp,
    String? unit,
    DoseSource source = DoseSource.manual,
    bool takenWithFood = false,
    bool takenWithFat = false,
    String? mealContext,
    int? journalEntryId,
    double? confidence,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.logDose(
        supplementId: supplementId,
        amountMg: amountMg,
        timestamp: timestamp,
        unit: unit,
        source: source,
        takenWithFood: takenWithFood,
        takenWithFat: takenWithFat,
        mealContext: mealContext,
        journalEntryId: journalEntryId,
        confidence: confidence,
        notes: notes,
      );
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to log dose',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for dose ViewModel.
final doseViewModelProvider = NotifierProvider<DoseViewModel, DoseState>(
  DoseViewModel.new,
);
