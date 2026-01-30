import 'dart:async';

import '../config/azure_ai_config.dart';
import '../database/app_database.dart';
import '../models/agent_output.dart';
import '../utils/logger.dart';
import 'azure_agent_service.dart';
import 'notification_service.dart';

/// Scheduler that runs AI agents on intervals:
/// - GPT-5 Nano: Every 5 minutes (fast, cheap processing)
/// - GPT-5 Chat: Every 30 minutes (supervisor, reviews Nano's work)
class AgentSchedulerService {
  static const String _tag = 'AgentScheduler';

  final AzureAgentService _agentService;
  final AppDatabase _db;
  final NotificationService? _notificationService;

  Timer? _nanoTimer;
  Timer? _chatTimer;

  bool _isRunning = false;
  int _nanoCycleCount = 0;

  // Interval configuration
  static const int nanoIntervalMinutes = 5;
  static const int chatIntervalMinutes = 30;

  // Stream controller for UI updates (replaces system notifications)
  final _statusController = StreamController<AgentStatus>.broadcast();
  Stream<AgentStatus> get statusStream => _statusController.stream;

  AgentSchedulerService({
    required AzureAgentService agentService,
    required AppDatabase db,
    NotificationService? notificationService,
  })  : _agentService = agentService,
        _db = db,
        _notificationService = notificationService;

  /// Start the agent scheduler
  Future<void> start() async {
    if (_isRunning) {
      Logger.warning('Agent scheduler already running', tag: _tag);
      return;
    }

    _isRunning = true;
    Logger.info('Starting agent scheduler', tag: _tag);
    _updateStatus(AgentStatus.idle('Scheduler started'));

    // Run Nano immediately, then every 5 min
    await _runNanoCycle();
    _nanoTimer = Timer.periodic(
      Duration(minutes: nanoIntervalMinutes),
      (_) => _runNanoCycle(),
    );

    // Run Chat after first cycle, then every 30 min
    _chatTimer = Timer.periodic(
      Duration(minutes: chatIntervalMinutes),
      (_) => _runChatCycle(),
    );

    Logger.info(
        'Agent scheduler started: Nano every ${nanoIntervalMinutes}m, Chat every ${chatIntervalMinutes}m',
        tag: _tag);
  }

  /// Stop the agent scheduler
  void stop() {
    _nanoTimer?.cancel();
    _chatTimer?.cancel();
    _nanoTimer = null;
    _chatTimer = null;
    _isRunning = false;
    _updateStatus(AgentStatus.stopped());
    Logger.info('Agent scheduler stopped', tag: _tag);
  }

  bool get isRunning => _isRunning;

  /// Run a Nano agent cycle
  Future<void> _runNanoCycle() async {
    _nanoCycleCount++;
    Logger.info('Running Nano cycle #$_nanoCycleCount', tag: _tag);
    _updateStatus(AgentStatus.running(AgentType.nano, 'Processing...'));

    // Show Live Activity on Dynamic Island
    await _notificationService?.showAgentWorking(
      agentType: AgentType.nano,
      message: 'Processing cycle #$_nanoCycleCount...',
    );

    try {
      // Nano does quick processing tasks
      final prompt = _buildNanoPrompt();
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a fast, efficient AI assistant doing background processing. '
            'Respond concisely with actionable insights. Always respond in valid JSON.',
        deployment: AzureAIDeployment.gpt5,
      );

      // Store the output
      final output = AgentOutput(
        agentType: AgentType.nano,
        prompt: prompt,
        response: response,
      );
      await _db.insertAgentOutput(output);

      // Update Live Activity to show completion
      await _notificationService?.updateAgentStatus(
        agentType: AgentType.nano,
        message: 'Cycle complete',
        isComplete: true,
      );

      // Hide Live Activity after brief delay
      Future.delayed(const Duration(seconds: 2), () {
        _notificationService?.hideAgentStatus();
      });

      _updateStatus(AgentStatus.completed(AgentType.nano, response));
      Logger.info('Nano cycle #$_nanoCycleCount completed', tag: _tag);
    } catch (e) {
      Logger.error('Nano cycle failed: $e', tag: _tag);

      // Show error on Live Activity
      await _notificationService?.updateAgentStatus(
        agentType: AgentType.nano,
        message: 'Cycle failed',
        isError: true,
      );

      Future.delayed(const Duration(seconds: 3), () {
        _notificationService?.hideAgentStatus();
      });

      _updateStatus(AgentStatus.error(AgentType.nano, e.toString()));
    }
  }

  /// Run a Chat agent cycle (supervisor)
  Future<void> _runChatCycle() async {
    Logger.info('Running Chat supervisor cycle', tag: _tag);
    _updateStatus(
        AgentStatus.running(AgentType.chat, 'Reviewing Nano outputs...'));

    // Show Live Activity on Dynamic Island
    await _notificationService?.showAgentWorking(
      agentType: AgentType.chat,
      message: 'Reviewing agent outputs...',
    );

    try {
      // Get unreviewed Nano outputs
      final nanoOutputs = await _db.getUnreviewedNanoOutputs();

      if (nanoOutputs.isEmpty) {
        Logger.info('No unreviewed Nano outputs to process', tag: _tag);
        await _notificationService?.hideAgentStatus();
        _updateStatus(
            AgentStatus.completed(AgentType.chat, 'No outputs to review'));
        return;
      }

      // Update status
      await _notificationService?.updateAgentStatus(
        agentType: AgentType.chat,
        message: 'Analyzing ${nanoOutputs.length} outputs...',
      );

      // Build supervisor prompt
      final prompt = _buildChatSupervisorPrompt(nanoOutputs);
      final response = await _agentService.complete(
        prompt: prompt,
        systemPrompt:
            'You are a senior AI supervisor reviewing the work of a junior agent. '
            'Analyze the outputs, identify patterns, suggest improvements, and compile '
            'an action list. Be thorough but concise.',
        deployment: AzureAIDeployment.gpt5,
        maxTokens: 4000,
      );

      // Store the supervisor's output
      final output = AgentOutput(
        agentType: AgentType.chat,
        prompt: prompt,
        response: response,
      );
      await _db.insertAgentOutput(output);

      // Mark Nano outputs as reviewed
      for (final nanoOutput in nanoOutputs) {
        if (nanoOutput.id != null) {
          await _db.markAsReviewed(
            nanoOutput.id!,
            'chat',
            'Reviewed in supervisor cycle',
          );
        }
      }

      // Update Live Activity to show completion
      await _notificationService?.updateAgentStatus(
        agentType: AgentType.chat,
        message: 'Review complete',
        isComplete: true,
      );

      // Hide Live Activity after brief delay
      Future.delayed(const Duration(seconds: 2), () {
        _notificationService?.hideAgentStatus();
      });

      _updateStatus(AgentStatus.completed(AgentType.chat, response));
      Logger.info('Chat supervisor cycle completed', tag: _tag);
    } catch (e) {
      Logger.error('Chat cycle failed: $e', tag: _tag);

      // Show error on Live Activity
      await _notificationService?.updateAgentStatus(
        agentType: AgentType.chat,
        message: 'Review failed',
        isError: true,
      );

      Future.delayed(const Duration(seconds: 3), () {
        _notificationService?.hideAgentStatus();
      });

      _updateStatus(AgentStatus.error(AgentType.chat, e.toString()));
    }
  }

  /// Manually trigger a Nano cycle (for testing)
  Future<void> triggerNano() async {
    await _runNanoCycle();
  }

  /// Manually trigger a Chat cycle (for testing)
  Future<void> triggerChat() async {
    await _runChatCycle();
  }

  /// Build prompt for Nano agent
  String _buildNanoPrompt() {
    final now = DateTime.now();
    final hour = now.hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : hour < 21
                ? 'evening'
                : 'night';

    return '''
Current time: ${now.toIso8601String()}
Time of day: $timeOfDay
Cycle number: $_nanoCycleCount

Tasks:
1. Generate a quick insight or affirmation appropriate for this time of day
2. Suggest one actionable micro-task the user could do right now
3. Rate the current moment on a 1-10 scale for productivity potential

Respond in JSON format:
{
  "insight": "...",
  "micro_task": "...",
  "productivity_score": N,
  "reasoning": "..."
}
''';
  }

  /// Build supervisor prompt for Chat agent
  String _buildChatSupervisorPrompt(List<AgentOutput> nanoOutputs) {
    final outputSummaries = nanoOutputs.map((o) {
      return '- [${o.createdAt.toIso8601String()}]: ${_truncate(o.response, 200)}';
    }).join('\n');

    return '''
You are reviewing ${nanoOutputs.length} outputs from the Nano agent:

$outputSummaries

Your tasks:
1. Identify patterns or themes across these outputs
2. Flag any inconsistencies or low-quality responses
3. Generate a consolidated action list for the user
4. Suggest any improvements to the Nano agent's prompts
5. Optionally, generate a short meditation script based on insights

Respond in a structured format the user can act on.
''';
  }

  void _updateStatus(AgentStatus status) {
    _statusController.add(status);
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  void dispose() {
    stop();
    _statusController.close();
  }
}

/// Status of the agent scheduler
class AgentStatus {
  final AgentStatusType type;
  final AgentType? agentType;
  final String message;
  final DateTime timestamp;

  AgentStatus._({
    required this.type,
    this.agentType,
    required this.message,
  }) : timestamp = DateTime.now();

  factory AgentStatus.idle(String message) =>
      AgentStatus._(type: AgentStatusType.idle, message: message);

  factory AgentStatus.running(AgentType agent, String message) => AgentStatus._(
      type: AgentStatusType.running, agentType: agent, message: message);

  factory AgentStatus.completed(AgentType agent, String message) =>
      AgentStatus._(
          type: AgentStatusType.completed, agentType: agent, message: message);

  factory AgentStatus.error(AgentType agent, String message) => AgentStatus._(
      type: AgentStatusType.error, agentType: agent, message: message);

  factory AgentStatus.stopped() => AgentStatus._(
      type: AgentStatusType.stopped, message: 'Scheduler stopped');

  bool get isRunning => type == AgentStatusType.running;
  bool get isError => type == AgentStatusType.error;
}

enum AgentStatusType { idle, running, completed, error, stopped }
