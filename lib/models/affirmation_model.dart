class Affirmation {
  final String text;
  final String author;
  final DateTime date;
  final String theme; // e.g., 'gratitude', 'self-love', 'resilience'
  
  Affirmation({
    required this.text,
    required this.author,
    required this.date,
    required this.theme,
  });

  // Example data for demo purposes
  static List<Affirmation> examples() {
    return [
      Affirmation(
        text: 'I am worthy of love and respect just as I am.',
        author: 'Self',
        date: DateTime.now(),
        theme: 'self-love',
      ),
      Affirmation(
        text: 'Every challenge I face is an opportunity for growth.',
        author: 'Self',
        date: DateTime.now().subtract(const Duration(days: 1)),
        theme: 'resilience',
      ),
      Affirmation(
        text: 'I am grateful for all the beauty and abundance in my life.',
        author: 'Self',
        date: DateTime.now().subtract(const Duration(days: 2)),
        theme: 'gratitude',
      ),
      Affirmation(
        text: 'My thoughts and feelings are valid, and I honor them with compassion.',
        author: 'Self',
        date: DateTime.now().subtract(const Duration(days: 3)),
        theme: 'acceptance',
      ),
      Affirmation(
        text: 'I have the power to create positive change in my life.',
        author: 'Self',
        date: DateTime.now().subtract(const Duration(days: 4)),
        theme: 'empowerment',
      ),
    ];
  }

  // Get a random affirmation
  static Affirmation random() {
    final List<Affirmation> affirmations = examples();
    affirmations.shuffle();
    return affirmations.first;
  }

  // Get today's affirmation (or generate a new one if none exists)
  static Affirmation today() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final affirmations = examples();
    
    // Try to find an affirmation from today
    for (var affirmation in affirmations) {
      final affirmationDate = DateTime(
        affirmation.date.year,
        affirmation.date.month,
        affirmation.date.day,
      );
      
      if (affirmationDate.isAtSameMomentAs(todayStart)) {
        return affirmation;
      }
    }
    
    // If no affirmation for today, return a random one
    return random();
  }
}
