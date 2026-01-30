import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../models/wealth/wealth.dart';
import '../providers/viewmodels/wealth_viewmodel.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';

import 'chat_screen.dart';

/// Wealth Screen - Finance pillar
/// Track bills, subscriptions, and income.
/// Uses same Hero Card pattern as other pillars.
class WealthScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const WealthScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends ConsumerState<WealthScreen> {
  // Panel progress for hero card animation
  double _panelProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Load wealth data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wealthViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    // Min panel: 38% of screen
    final minPanelHeight = screenHeight * 0.38;
    // Max panel: Leave room for nav bar + compact stats + padding
    final maxPanelHeight = screenHeight - safeTop - 70 - 100;

    // Calculate hero card position using BOTTOM coordinate
    final cardBottomAtRest = minPanelHeight + 20;
    final cardBottomAtExpanded = maxPanelHeight + 16;
    final cardBottom = cardBottomAtRest +
        (_panelProgress * (cardBottomAtExpanded - cardBottomAtRest));

    // Content crossfade
    final showFullCard = _panelProgress < 0.6;

    return TwoToneSplitLayout(
      panelVisibility: widget.panelVisibility,
      bottomPanelMinHeight: minPanelHeight,
      bottomPanelMaxHeight: maxPanelHeight,
      bottomPanelShowHandle: true,
      bottomPanelPulseEnabled: true,
      bottomPanelProgressChanged: (progress) {
        setState(() => _panelProgress = progress);
      },
      bottomPanel: _buildBottomPanelContent(context),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Hero content - always shown, animates with panel
            Positioned(
              left: 20,
              right: 20,
              bottom: cardBottom,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: showFullCard ? _buildHeroContent() : _buildCompactBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hero content - Monthly cash flow summary
  Widget _buildHeroContent() {
    return Column(
      key: const ValueKey('full'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CASH FLOW',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: ThemeConstants.borderRadiusXL,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Builder(
            builder: (context) {
              final wealthState = ref.watch(wealthViewModelProvider);
              final income = wealthState.totalMonthlyIncome;
              final expenses = wealthState.totalMonthlyExpenses;
              final net = wealthState.netMonthlyCashFlow;

              return Column(
                children: [
                  // Income
                  _buildFlowRow(
                    'Income',
                    '\$${income.toStringAsFixed(0)}',
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                  const SizedBox(height: 12),
                  // Expenses
                  _buildFlowRow(
                    'Expenses',
                    '\$${expenses.toStringAsFixed(0)}',
                    Colors.red.shade300,
                    Icons.arrow_upward,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 16),
                  // Net
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Monthly',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '\$${net.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: net >= 0
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlowRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Compact bar - shown when panel is expanded
  Widget _buildCompactBar() {
    final wealthState = ref.watch(wealthViewModelProvider);
    final income = wealthState.totalMonthlyIncome;
    final expenses = wealthState.totalMonthlyExpenses;
    final net = wealthState.netMonthlyCashFlow;

    return Container(
      key: const ValueKey('compact'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat('💰', '\$${income.toStringAsFixed(0)}'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('📤', '\$${expenses.toStringAsFixed(0)}'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('📊', '\$${net.toStringAsFixed(0)} net'),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Bottom panel content
  Widget _buildBottomPanelContent(BuildContext context) {
    final wealthState = ref.watch(wealthViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(context),
        const SizedBox(height: 16),

        // Month selector (using WeekDayPicker pattern)
        WeekDayPicker(
          selectedDate: DateTime.now(),
          headerText: "Track your money",
          onDateSelected: (date) {},
        ),

        const SizedBox(height: 20),

        // Bills Due
        _buildSectionHeaderWithAction(
            'BILLS DUE', 'Add', () => _showAddBillHint(context)),
        const SizedBox(height: 12),
        if (wealthState.bills.isEmpty)
          _buildEmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'No bills tracked yet',
            actionText: 'Add Bill',
            onAction: () => _showAddBillHint(context),
          )
        else
          ...wealthState.bills.take(3).map((bill) => _buildBillRow(bill)),

        const SizedBox(height: 24),

        // Subscriptions
        _buildSectionHeaderWithAction(
            'SUBSCRIPTIONS', 'Add', () => _showAddSubscriptionHint(context)),
        const SizedBox(height: 12),
        if (wealthState.subscriptions.isEmpty)
          _buildEmptyState(
            icon: Icons.subscriptions_outlined,
            message: 'Track your subscriptions',
          )
        else
          ...wealthState.subscriptions
              .take(3)
              .map((sub) => _buildSubscriptionRow(sub)),

        const SizedBox(height: 24),

        // Income
        _buildSectionHeader('INCOME'),
        const SizedBox(height: 12),
        if (wealthState.incomes.isEmpty)
          _buildEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            message: 'Add income sources to see your cash flow',
          )
        else
          ...wealthState.incomes
              .take(3)
              .map((income) => _buildIncomeRow(income)),
      ],
    );
  }

  Widget _buildBillRow(Bill bill) {
    final isDueSoon = bill.isDueSoon(7);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(
            color: isDueSoon
                ? Colors.orange.withValues(alpha: 0.3)
                : ThemeConstants.glassBorderWeak),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(bill.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getBillCategoryIcon(bill.category),
              size: 20,
              color: _getCategoryColor(bill.category),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  'Due day ${bill.dueDay}${bill.autopay ? ' • Autopay' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDueSoon
                        ? Colors.orange
                        : ThemeConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '\$${bill.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionRow(Subscription sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Row(
        children: [
          // Logo or icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThemeConstants.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: sub.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(sub.logoUrl!, fit: BoxFit.cover),
                  )
                : Icon(
                    _getSubscriptionCategoryIcon(sub.category),
                    size: 20,
                    color: ThemeConstants.accentBlue,
                  ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  _getFrequencyLabel(sub.frequency),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '\$${sub.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(Income income) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIncomeTypeIcon(income.type),
              size: 20,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.source,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  _getIncomeFrequencyLabel(income.frequency),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '\$${income.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BillCategory category) {
    switch (category) {
      case BillCategory.housing:
        return Colors.blue;
      case BillCategory.utilities:
        return Colors.amber;
      case BillCategory.insurance:
        return Colors.purple;
      case BillCategory.transportation:
        return Colors.teal;
      case BillCategory.debt:
        return Colors.red.shade700;
      case BillCategory.subscription:
        return Colors.indigo;
      case BillCategory.other:
        return ThemeConstants.textSecondary;
    }
  }

  IconData _getBillCategoryIcon(BillCategory category) {
    switch (category) {
      case BillCategory.housing:
        return Icons.home;
      case BillCategory.utilities:
        return Icons.power;
      case BillCategory.insurance:
        return Icons.security;
      case BillCategory.transportation:
        return Icons.directions_car;
      case BillCategory.debt:
        return Icons.credit_card;
      case BillCategory.subscription:
        return Icons.subscriptions;
      case BillCategory.other:
        return Icons.receipt_long;
    }
  }

  IconData _getSubscriptionCategoryIcon(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.entertainment:
        return Icons.play_circle;
      case SubscriptionCategory.productivity:
        return Icons.work;
      case SubscriptionCategory.health:
        return Icons.fitness_center;
      case SubscriptionCategory.education:
        return Icons.school;
      case SubscriptionCategory.software:
        return Icons.computer;
      case SubscriptionCategory.news:
        return Icons.newspaper;
      case SubscriptionCategory.social:
        return Icons.people;
      case SubscriptionCategory.other:
        return Icons.subscriptions;
    }
  }

  IconData _getIncomeTypeIcon(IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return Icons.work;
      case IncomeType.freelance:
        return Icons.laptop;
      case IncomeType.investment:
        return Icons.trending_up;
      case IncomeType.rental:
        return Icons.apartment;
      case IncomeType.business:
        return Icons.business;
      case IncomeType.side:
        return Icons.lightbulb;
      case IncomeType.other:
        return Icons.account_balance_wallet;
    }
  }

  String _getFrequencyLabel(SubscriptionFrequency freq) {
    switch (freq) {
      case SubscriptionFrequency.weekly:
        return 'Weekly';
      case SubscriptionFrequency.monthly:
        return 'Monthly';
      case SubscriptionFrequency.quarterly:
        return 'Quarterly';
      case SubscriptionFrequency.yearly:
        return 'Yearly';
    }
  }

  String _getIncomeFrequencyLabel(IncomeFrequency freq) {
    switch (freq) {
      case IncomeFrequency.weekly:
        return 'Weekly';
      case IncomeFrequency.biweekly:
        return 'Bi-weekly';
      case IncomeFrequency.monthly:
        return 'Monthly';
      case IncomeFrequency.quarterly:
        return 'Quarterly';
      case IncomeFrequency.yearly:
        return 'Yearly';
      case IncomeFrequency.oneTime:
        return 'One-time';
    }
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Manage your finances',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textOnLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _buildHeaderAction(
              icon: Icons.add_card,
              label: 'Add',
              color: ThemeConstants.accentGreen,
              onTap: () => _showAddBillHint(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.chat_bubble_outline,
              label: 'NTS',
              color: ThemeConstants.accentBlue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(
            icon: icon,
            color: color,
            size: 34,
            iconSize: 18,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ThemeConstants.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(
      String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ThemeConstants.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: 14,
                color: ThemeConstants.accentBlue,
              ),
              const SizedBox(width: 4),
              Text(
                actionText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.accentBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeConstants.glassBackgroundWeak,
        borderRadius: ThemeConstants.borderRadius,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
      ),
      child: Column(
        children: [
          Icon(icon, color: ThemeConstants.textSecondary, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ThemeConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ThemeConstants.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.accentBlue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddBillHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill management coming soon!')),
    );
  }

  void _showAddSubscriptionHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription tracking coming soon!')),
    );
  }
}
