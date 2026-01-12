import 'package:flutter/material.dart';

import '../../services/voice_action_service.dart';

/// A card that shows the result of a voice action
/// Appears when user says a command and LLM processes it
class ActionConfirmationCard extends StatelessWidget {
  final ActionResult result;
  final VoidCallback? onDismiss;

  const ActionConfirmationCard({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with icon and type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  result.success ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: result.success
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTitle(),
                    style: TextStyle(
                      color: result.success
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // Message
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              result.message,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Details (if any)
          if (result.details != null && result.details!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.details!.entries.map((entry) {
                  if (entry.key == 'time') return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (result.type) {
      case ActionType.logSupplement:
        return Icons.medication_outlined;
      case ActionType.logMeal:
        return Icons.restaurant_outlined;
      case ActionType.getMantra:
        return Icons.format_quote_outlined;
      case ActionType.checkProgress:
        return Icons.analytics_outlined;
      case ActionType.unknown:
        return Icons.help_outline;
      case ActionType.error:
        return Icons.error_outline;
    }
  }

  String _getTitle() {
    switch (result.type) {
      case ActionType.logSupplement:
        return 'Supplement Logged';
      case ActionType.logMeal:
        return 'Meal Logged';
      case ActionType.getMantra:
        return 'Your Mantra';
      case ActionType.checkProgress:
        return 'Daily Progress';
      case ActionType.unknown:
        return 'Not Understood';
      case ActionType.error:
        return 'Error';
    }
  }
}

/// Toast-style notification for quick action confirmations
class ActionToast extends StatelessWidget {
  final ActionResult result;

  const ActionToast({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: result.success ? Colors.green.shade600 : Colors.red.shade600,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              result.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
