/// Represents an output from an AI agent processing cycle
class AgentOutput {
  final int? id;
  final AgentType agentType;
  final String prompt;
  final String response;
  final DateTime createdAt;
  final bool reviewed;
  final String? reviewedBy; // 'chat' when ChatAgent reviews NanoAgent output
  final String? reviewNotes;

  AgentOutput({
    this.id,
    required this.agentType,
    required this.prompt,
    required this.response,
    DateTime? createdAt,
    this.reviewed = false,
    this.reviewedBy,
    this.reviewNotes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'agent_type': agentType.name,
      'prompt': prompt,
      'response': response,
      'created_at': createdAt.toIso8601String(),
      'reviewed': reviewed ? 1 : 0,
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
    };
  }

  factory AgentOutput.fromMap(Map<String, dynamic> map) {
    return AgentOutput(
      id: map['id'] as int?,
      agentType: AgentType.values.firstWhere(
        (e) => e.name == map['agent_type'],
        orElse: () => AgentType.nano,
      ),
      prompt: map['prompt'] as String? ?? '',
      response: map['response'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      reviewed: (map['reviewed'] as int?) == 1,
      reviewedBy: map['reviewed_by'] as String?,
      reviewNotes: map['review_notes'] as String?,
    );
  }

  AgentOutput copyWith({
    int? id,
    AgentType? agentType,
    String? prompt,
    String? response,
    DateTime? createdAt,
    bool? reviewed,
    String? reviewedBy,
    String? reviewNotes,
  }) {
    return AgentOutput(
      id: id ?? this.id,
      agentType: agentType ?? this.agentType,
      prompt: prompt ?? this.prompt,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      reviewed: reviewed ?? this.reviewed,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  @override
  String toString() =>
      'AgentOutput(${agentType.name}: ${response.substring(0, response.length.clamp(0, 50))}...)';
}

/// Types of agents in the system
enum AgentType {
  nano, // GPT-5 Nano - fast, cheap, every 5 min
  chat, // GPT-5 Chat - quality, supervisor, every 30 min
  bootstrap, // Bootstrap agent - runs at app startup
}

extension AgentTypeInfo on AgentType {
  String get displayName {
    switch (this) {
      case AgentType.nano:
        return 'GPT-5 Nano';
      case AgentType.chat:
        return 'GPT-5 Chat';
      case AgentType.bootstrap:
        return 'Bootstrap';
    }
  }

  String get emoji {
    switch (this) {
      case AgentType.nano:
        return '⚡';
      case AgentType.chat:
        return '🧠';
      case AgentType.bootstrap:
        return '🚀';
    }
  }
}
