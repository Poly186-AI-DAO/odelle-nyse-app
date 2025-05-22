class ThoughtEmotionBehavior {
  final String thought;
  final String emotion;
  final String behavior;
  final DateTime timestamp;
  final String insight; // Optional reflection or insight about the pattern

  ThoughtEmotionBehavior({
    required this.thought,
    required this.emotion,
    required this.behavior,
    required this.timestamp,
    this.insight = '',
  });

  // Example data for demo purposes
  static List<ThoughtEmotionBehavior> examples() {
    return [
      ThoughtEmotionBehavior(
        thought: 'I\'ll never be able to finish this project on time.',
        emotion: 'Anxiety, overwhelm',
        behavior: 'Procrastination, avoiding the task',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        insight: 'Catastrophic thinking pattern leading to avoidance behavior',
      ),
      ThoughtEmotionBehavior(
        thought: 'My colleague\'s silence means they dislike my idea.',
        emotion: 'Insecurity, embarrassment',
        behavior: 'Withdrawal from the conversation',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        insight: 'Mind reading cognitive distortion affecting social interaction',
      ),
      ThoughtEmotionBehavior(
        thought: 'I handled that difficult conversation really well.',
        emotion: 'Pride, satisfaction',
        behavior: 'Continued engagement, sharing ideas confidently',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        insight: 'Positive self-talk reinforcing constructive social behavior',
      ),
    ];
  }

  // Get the most recent entry
  static ThoughtEmotionBehavior? getMostRecent() {
    final entries = examples();
    if (entries.isEmpty) return null;
    
    return entries.reduce((a, b) => 
      a.timestamp.isAfter(b.timestamp) ? a : b);
  }
}
