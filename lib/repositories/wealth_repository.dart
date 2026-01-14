import '../database/app_database.dart';
import '../models/wealth/wealth.dart';
import '../utils/logger.dart';

/// Repository for Wealth pillar data: Bills, Subscriptions, Income.
class WealthRepository {
  static const String _tag = 'WealthRepository';
  final AppDatabase _db;

  WealthRepository(this._db);

  // ===================
  // Bills
  // ===================

  Future<List<Bill>> getBills({bool activeOnly = true}) async {
    return _db.getBills(activeOnly: activeOnly);
  }

  Future<List<Bill>> getBillsDueSoon({int days = 7}) async {
    return _db.getBillsDueSoon(days);
  }

  Future<Bill?> getBill(int id) async {
    return _db.getBill(id);
  }

  Future<int> createBill(Bill bill) async {
    Logger.info('Creating bill: ${bill.name}', tag: _tag);
    return _db.insertBill(bill);
  }

  Future<int> updateBill(Bill bill) async {
    Logger.info('Updating bill: ${bill.id}', tag: _tag);
    return _db.updateBill(bill);
  }

  Future<int> deleteBill(int id) async {
    Logger.info('Deleting bill: $id', tag: _tag);
    return _db.deleteBill(id);
  }

  // ===================
  // Subscriptions
  // ===================

  Future<List<Subscription>> getSubscriptions({bool activeOnly = true}) async {
    return _db.getSubscriptions(activeOnly: activeOnly);
  }

  Future<Subscription?> getSubscription(int id) async {
    return _db.getSubscription(id);
  }

  Future<int> createSubscription(Subscription subscription) async {
    Logger.info('Creating subscription: ${subscription.name}', tag: _tag);
    return _db.insertSubscription(subscription);
  }

  Future<int> updateSubscription(Subscription subscription) async {
    Logger.info('Updating subscription: ${subscription.id}', tag: _tag);
    return _db.updateSubscription(subscription);
  }

  Future<int> deleteSubscription(int id) async {
    Logger.info('Deleting subscription: $id', tag: _tag);
    return _db.deleteSubscription(id);
  }

  // ===================
  // Income
  // ===================

  Future<List<Income>> getIncomes({bool activeOnly = true}) async {
    return _db.getIncomes(activeOnly: activeOnly);
  }

  Future<Income?> getIncome(int id) async {
    return _db.getIncome(id);
  }

  Future<int> createIncome(Income income) async {
    Logger.info('Creating income: ${income.source}', tag: _tag);
    return _db.insertIncome(income);
  }

  Future<int> updateIncome(Income income) async {
    Logger.info('Updating income: ${income.id}', tag: _tag);
    return _db.updateIncome(income);
  }

  Future<int> deleteIncome(int id) async {
    Logger.info('Deleting income: $id', tag: _tag);
    return _db.deleteIncome(id);
  }

  // ===================
  // Aggregates
  // ===================

  /// Get monthly summary: total income, expenses, and net cash flow.
  Future<WealthSummary> getMonthlySummary() async {
    final totalIncome = await _db.getTotalMonthlyIncome();
    final totalBills = await _db.getTotalMonthlyBills();
    final totalSubs = await _db.getTotalMonthlySubscriptions();
    final totalExpenses = totalBills + totalSubs;

    return WealthSummary(
      totalMonthlyIncome: totalIncome,
      totalMonthlyBills: totalBills,
      totalMonthlySubscriptions: totalSubs,
      totalMonthlyExpenses: totalExpenses,
      netMonthlyCashFlow: totalIncome - totalExpenses,
    );
  }
}

/// Aggregate summary of monthly wealth data.
class WealthSummary {
  final double totalMonthlyIncome;
  final double totalMonthlyBills;
  final double totalMonthlySubscriptions;
  final double totalMonthlyExpenses;
  final double netMonthlyCashFlow;

  const WealthSummary({
    required this.totalMonthlyIncome,
    required this.totalMonthlyBills,
    required this.totalMonthlySubscriptions,
    required this.totalMonthlyExpenses,
    required this.netMonthlyCashFlow,
  });
}
