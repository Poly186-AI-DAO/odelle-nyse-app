class InsightDimension {
  final String name;
  final double value; // 0.0 to 1.0
  final String description;

  InsightDimension({
    required this.name,
    required this.value,
    required this.description,
  });
}

class InsightEntry {
  final DateTime date;
  final List<InsightDimension> dimensions;
  final String summary;

  InsightEntry({
    required this.date,
    required this.dimensions,
    required this.summary,
  });
}

class UserInsights {
  final List<InsightEntry> entries;

  UserInsights({required this.entries});

  // Get the most recent insight entry
  InsightEntry? get mostRecent {
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  // Example data for demo purposes
  static UserInsights example() {
    return UserInsights(
      entries: [
        InsightEntry(
          date: DateTime.now().subtract(const Duration(days: 3)),
          dimensions: [
            InsightDimension(
              name: 'Awareness',
              value: 0.8,
              description: 'Your ability to recognize thoughts and emotions',
            ),
            InsightDimension(
              name: 'Acceptance',
              value: 0.6,
              description: 'Your ability to accept situations without judgment',
            ),
            InsightDimension(
              name: 'Compassion',
              value: 0.7,
              description: 'Your level of kindness toward yourself and others',
            ),
            InsightDimension(
              name: 'Gratitude',
              value: 0.9,
              description: 'Your recognition of positive aspects of life',
            ),
            InsightDimension(
              name: 'Resilience',
              value: 0.5,
              description: 'Your ability to bounce back from challenges',
            ),
          ],
          summary: 'You\'ve been showing strong awareness and gratitude, with room to grow in resilience.',
        ),
        InsightEntry(
          date: DateTime.now().subtract(const Duration(days: 1)),
          dimensions: [
            InsightDimension(
              name: 'Awareness',
              value: 0.85,
              description: 'Your ability to recognize thoughts and emotions',
            ),
            InsightDimension(
              name: 'Acceptance',
              value: 0.65,
              description: 'Your ability to accept situations without judgment',
            ),
            InsightDimension(
              name: 'Compassion',
              value: 0.75,
              description: 'Your level of kindness toward yourself and others',
            ),
            InsightDimension(
              name: 'Gratitude',
              value: 0.85,
              description: 'Your recognition of positive aspects of life',
            ),
            InsightDimension(
              name: 'Resilience',
              value: 0.6,
              description: 'Your ability to bounce back from challenges',
            ),
          ],
          summary: 'You\'ve made progress in all areas, particularly in resilience. Keep practicing acceptance techniques.',
        ),
      ],
    );
  }
}
