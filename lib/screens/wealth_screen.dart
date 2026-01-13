import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';

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

    return FloatingHeroCard(
      panelVisibility: widget.panelVisibility,
      draggableBottomPanel: true,
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
            // Hero content
            Positioned(
              left: 20,
              right: 20,
              bottom: cardBottom,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: showFullCard
                    ? _buildHeroContent()
                    : _buildCompactBar(),
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
          child: Column(
            children: [
              // Income
              _buildFlowRow(
                'Income',
                '\$0',
                Colors.green,
                Icons.arrow_downward,
              ),
              const SizedBox(height: 12),
              // Expenses
              _buildFlowRow(
                'Expenses',
                '\$0',
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
                    '\$0',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
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
          _buildCompactStat('💰', '\$0'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('📤', '\$0'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat('📊', '\$0 net'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month selector (using WeekDayPicker pattern)
        WeekDayPicker(
          selectedDate: DateTime.now(),
          headerText: "Track your money",
          onDateSelected: (date) {},
        ),

        const SizedBox(height: 20),

        // Bills Due
        _buildSectionHeaderWithAction('BILLS DUE', 'Add', () => _showAddBillHint(context)),
        const SizedBox(height: 12),
        _buildEmptyState(
          icon: Icons.receipt_long_outlined,
          message: 'No bills tracked yet',
          actionText: 'Add Bill',
          onAction: () => _showAddBillHint(context),
        ),

        const SizedBox(height: 24),

        // Subscriptions
        _buildSectionHeaderWithAction('SUBSCRIPTIONS', 'Add', () => _showAddSubscriptionHint(context)),
        const SizedBox(height: 12),
        _buildEmptyState(
          icon: Icons.subscriptions_outlined,
          message: 'Track your subscriptions',
        ),

        const SizedBox(height: 24),

        // Income
        _buildSectionHeader('INCOME'),
        const SizedBox(height: 12),
        _buildEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          message: 'Add income sources to see your cash flow',
        ),
      ],
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

  Widget _buildSectionHeaderWithAction(String title, String actionText, VoidCallback onAction) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
