import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agent_output.dart';
import '../../services/agent_scheduler_service.dart';

/// Overlay widget that shows real-time agent status
/// Displays in the corner of the screen when agents are active
class AgentStatusOverlay extends ConsumerWidget {
  const AgentStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to get the scheduler, but handle when provider not overridden
    AgentSchedulerService? scheduler;
    try {
      scheduler = ref.watch(agentSchedulerProvider);
    } catch (_) {
      // Provider not initialized - show nothing
      return const SizedBox.shrink();
    }

    if (scheduler == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<AgentStatus>(
      stream: scheduler.statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        
        // Only show for running, completed, or error states
        if (status.type == AgentStatusType.idle || 
            status.type == AgentStatusType.stopped) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(status),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getGlowColor(status).withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(status),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTitle(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 180,
                    child: Text(
                      _truncate(status.message, 60),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(AgentStatus status) {
    if (status.isRunning) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    IconData icon;
    if (status.isError) {
      icon = Icons.error_outline;
    } else {
      icon = status.agentType == AgentType.nano
          ? Icons.bolt
          : Icons.psychology;
    }

    return Icon(icon, color: Colors.white, size: 20);
  }

  String _getTitle(AgentStatus status) {
    final agentName = status.agentType?.displayName ?? 'Agent';
    final emoji = status.agentType?.emoji ?? '🤖';
    
    switch (status.type) {
      case AgentStatusType.running:
        return '$emoji $agentName Processing...';
      case AgentStatusType.completed:
        return '$emoji $agentName Done';
      case AgentStatusType.error:
        return '⚠️ $agentName Error';
      default:
        return agentName;
    }
  }

  Color _getBackgroundColor(AgentStatus status) {
    if (status.isError) {
      return Colors.red.shade900.withValues(alpha: 0.9);
    }
    if (status.agentType == AgentType.nano) {
      return Colors.purple.shade900.withValues(alpha: 0.9);
    }
    return Colors.blue.shade900.withValues(alpha: 0.9);
  }

  Color _getGlowColor(AgentStatus status) {
    if (status.isError) return Colors.red;
    if (status.agentType == AgentType.nano) return Colors.purple;
    return Colors.blue;
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
