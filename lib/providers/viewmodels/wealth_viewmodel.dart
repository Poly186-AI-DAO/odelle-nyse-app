import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wealth/wealth.dart';
import '../../repositories/wealth_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for the Wealth pillar.
class WealthState {
  final List<Bill> bills;
  final List<Subscription> subscriptions;
  final List<Income> incomes;
  final double totalMonthlyIncome;
  final double totalMonthlyExpenses;
  final double netMonthlyCashFlow;
  final bool isLoading;
  final String? error;

  const WealthState({
    this.bills = const [],
    this.subscriptions = const [],
    this.incomes = const [],
    this.totalMonthlyIncome = 0,
    this.totalMonthlyExpenses = 0,
    this.netMonthlyCashFlow = 0,
    this.isLoading = false,
    this.error,
  });

  WealthState copyWith({
    List<Bill>? bills,
    List<Subscription>? subscriptions,
    List<Income>? incomes,
    double? totalMonthlyIncome,
    double? totalMonthlyExpenses,
    double? netMonthlyCashFlow,
    bool? isLoading,
    String? error,
  }) {
    return WealthState(
      bills: bills ?? this.bills,
      subscriptions: subscriptions ?? this.subscriptions,
      incomes: incomes ?? this.incomes,
      totalMonthlyIncome: totalMonthlyIncome ?? this.totalMonthlyIncome,
      totalMonthlyExpenses: totalMonthlyExpenses ?? this.totalMonthlyExpenses,
      netMonthlyCashFlow: netMonthlyCashFlow ?? this.netMonthlyCashFlow,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Count of bills due within next 7 days.
  int get billsDueSoon => bills.where((b) => b.isDueSoon(7)).length;
}

/// ViewModel for the Wealth pillar.
class WealthViewModel extends Notifier<WealthState> {
  static const String _tag = 'WealthViewModel';

  @override
  WealthState build() {
    return const WealthState();
  }

  WealthRepository get _repository => ref.read(wealthRepositoryProvider);

  /// Load all wealth data.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bills = await _repository.getBills();
      final subscriptions = await _repository.getSubscriptions();
      final incomes = await _repository.getIncomes();
      final summary = await _repository.getMonthlySummary();

      state = state.copyWith(
        bills: bills,
        subscriptions: subscriptions,
        incomes: incomes,
        totalMonthlyIncome: summary.totalMonthlyIncome,
        totalMonthlyExpenses: summary.totalMonthlyExpenses,
        netMonthlyCashFlow: summary.netMonthlyCashFlow,
        isLoading: false,
      );
      Logger.info('Loaded wealth data: ${bills.length} bills, '
          '${subscriptions.length} subs, ${incomes.length} incomes', tag: _tag);
    } catch (e, stackTrace) {
      Logger.error('Failed to load wealth data',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ===================
  // Bills
  // ===================

  Future<void> addBill(Bill bill) async {
    try {
      await _repository.createBill(bill);
      await load(); // Refresh all data
    } catch (e, stackTrace) {
      Logger.error('Failed to add bill',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateBill(Bill bill) async {
    try {
      await _repository.updateBill(bill);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update bill',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteBill(int id) async {
    try {
      await _repository.deleteBill(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete bill',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  // ===================
  // Subscriptions
  // ===================

  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _repository.createSubscription(subscription);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to add subscription',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _repository.updateSubscription(subscription);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update subscription',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSubscription(int id) async {
    try {
      await _repository.deleteSubscription(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete subscription',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  // ===================
  // Income
  // ===================

  Future<void> addIncome(Income income) async {
    try {
      await _repository.createIncome(income);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to add income',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      await _repository.updateIncome(income);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update income',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteIncome(int id) async {
    try {
      await _repository.deleteIncome(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete income',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for WealthViewModel.
final wealthViewModelProvider =
    NotifierProvider<WealthViewModel, WealthState>(WealthViewModel.new);
