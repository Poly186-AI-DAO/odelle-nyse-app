import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme_constants.dart';
import '../models/relationships/relationships.dart';
import '../providers/viewmodels/bonds_viewmodel.dart';
import '../widgets/widgets.dart';
import '../widgets/effects/breathing_card.dart';

/// Bonds Screen - Relationships pillar
/// Track connections with people who matter.
/// Uses same Hero Card pattern as other pillars.
class BondsScreen extends ConsumerStatefulWidget {
  final double panelVisibility;

  const BondsScreen({super.key, this.panelVisibility = 1.0});

  @override
  ConsumerState<BondsScreen> createState() => _BondsScreenState();
}

class _BondsScreenState extends ConsumerState<BondsScreen> {
  // Panel progress for hero card animation
  double _panelProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Load bonds data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bondsViewModelProvider.notifier).load();
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

  /// Hero content - Relationship health summary
  Widget _buildHeroContent() {
    return Column(
      key: const ValueKey('full'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RELATIONSHIPS',
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
              final bondsState = ref.watch(bondsViewModelProvider);
              return Column(
                children: [
                  // Connection stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(
                          '${bondsState.priorityContacts.length}', 'Priority'),
                      _buildStatColumn(
                          '${bondsState.overdueContacts.length}', 'Overdue'),
                      _buildStatColumn(
                          '${bondsState.interactionsThisWeek}', 'This Week'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 16),
                  // Status message
                  Text(
                    bondsState.totalContacts == 0
                        ? 'Add contacts to track your relationships'
                        : '${bondsState.totalContacts} contacts tracked',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  /// Compact bar - shown when panel is expanded
  Widget _buildCompactBar() {
    final bondsState = ref.watch(bondsViewModelProvider);
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
          _buildCompactStat('👥', '${bondsState.totalContacts}'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat(
              '⏰', '${bondsState.overdueContacts.length} overdue'),
          Container(
              width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildCompactStat(
              '💬', '${bondsState.interactionsThisWeek} this week'),
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
    final bondsState = ref.watch(bondsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week Day Picker
        WeekDayPicker(
          selectedDate: bondsState.selectedDate,
          headerText: "Stay connected",
          onDateSelected: (date) {
            ref.read(bondsViewModelProvider.notifier).selectDate(date);
          },
        ),

        const SizedBox(height: 20),

        // Priority Contacts
        _buildSectionHeader('PRIORITY CONTACTS'),
        const SizedBox(height: 12),
        if (bondsState.priorityContacts.isEmpty)
          _buildEmptyState(
            icon: Icons.people_outline,
            message: 'No priority contacts yet',
            actionText: 'Add Contact',
            onAction: () => _showAddContactHint(context),
          )
        else
          ...bondsState.priorityContacts
              .take(3)
              .map((contact) => _buildContactRow(contact)),

        const SizedBox(height: 24),

        // Reach Out To (Overdue)
        _buildSectionHeader('REACH OUT TO'),
        const SizedBox(height: 12),
        if (bondsState.overdueContacts.isEmpty)
          _buildEmptyState(
            icon: Icons.schedule,
            message: 'Contacts overdue for connection will appear here',
          )
        else
          ...bondsState.overdueContacts
              .take(3)
              .map((contact) => _buildContactRow(contact, showOverdue: true)),

        const SizedBox(height: 24),

        // Recent Interactions
        _buildSectionHeader('RECENT INTERACTIONS'),
        const SizedBox(height: 12),
        if (bondsState.recentInteractions.isEmpty)
          _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'Log interactions to track relationship health',
          )
        else
          ...bondsState.recentInteractions
              .take(5)
              .map((interaction) => _buildInteractionRow(interaction)),
      ],
    );
  }

  Widget _buildContactRow(Contact contact, {bool showOverdue = false}) {
    final daysSinceContact = contact.lastContact != null
        ? DateTime.now().difference(contact.lastContact!).inDays
        : null;

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
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: ThemeConstants.accentBlue.withValues(alpha: 0.2),
            backgroundImage: contact.photoUrl != null
                ? NetworkImage(contact.photoUrl!)
                : null,
            child: contact.photoUrl == null
                ? Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.accentBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.nickname ?? contact.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                if (daysSinceContact != null)
                  Text(
                    showOverdue
                        ? '$daysSinceContact days overdue'
                        : 'Last contact: $daysSinceContact days ago',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: showOverdue
                          ? Colors.orange
                          : ThemeConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Priority indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(contact.priority).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '★' * contact.priority,
              style: TextStyle(
                fontSize: 10,
                color: _getPriorityColor(contact.priority),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionRow(Interaction interaction) {
    final timeAgo = _formatTimeAgo(interaction.timestamp);

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
          // Interaction type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ThemeConstants.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getInteractionIcon(interaction.type),
              size: 18,
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
                  interaction.contact?.name ??
                      'Contact #${interaction.contactId}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                Text(
                  '${interaction.typeEmoji} ${_getInteractionTypeLabel(interaction.type)} • $timeAgo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ThemeConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Quality indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                5,
                (i) => Icon(
                      i < interaction.quality ? Icons.star : Icons.star_border,
                      size: 12,
                      color: i < interaction.quality
                          ? Colors.amber
                          : ThemeConstants.textMuted,
                    )),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 4) return Colors.red;
    if (priority >= 3) return Colors.orange;
    return ThemeConstants.textSecondary;
  }

  IconData _getInteractionIcon(InteractionType type) {
    switch (type) {
      case InteractionType.call:
        return Icons.phone;
      case InteractionType.videoCall:
        return Icons.videocam;
      case InteractionType.text:
        return Icons.message;
      case InteractionType.email:
        return Icons.email;
      case InteractionType.inPerson:
        return Icons.people;
      case InteractionType.social:
        return Icons.thumb_up;
      case InteractionType.gift:
        return Icons.card_giftcard;
      case InteractionType.other:
        return Icons.chat_bubble_outline;
    }
  }

  String _getInteractionTypeLabel(InteractionType type) {
    switch (type) {
      case InteractionType.call:
        return 'Call';
      case InteractionType.videoCall:
        return 'Video';
      case InteractionType.text:
        return 'Text';
      case InteractionType.email:
        return 'Email';
      case InteractionType.inPerson:
        return 'In Person';
      case InteractionType.social:
        return 'Social';
      case InteractionType.gift:
        return 'Gift';
      case InteractionType.other:
        return 'Other';
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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

  void _showAddContactHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact management coming soon!')),
    );
  }
}
