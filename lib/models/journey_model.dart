class JourneyStage {
  final String name;
  final String description;
  final int step;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0

  JourneyStage({
    required this.name,
    required this.description,
    required this.step,
    required this.isCompleted,
    required this.progress,
  });
}

class HeroJourney {
  final List<JourneyStage> stages;
  final int currentStageIndex;
  final double overallProgress; // 0.0 to 1.0

  HeroJourney({
    required this.stages,
    required this.currentStageIndex,
    required this.overallProgress,
  });

  // Example data for demo purposes
  static HeroJourney example() {
    return HeroJourney(
      stages: [
        JourneyStage(
          name: 'Ordinary World',
          description: 'Your everyday reality before the journey begins',
          step: 1,
          isCompleted: true,
          progress: 1.0,
        ),
        JourneyStage(
          name: 'Call to Adventure',
          description: 'The challenge or quest that begins your journey',
          step: 2,
          isCompleted: true,
          progress: 1.0,
        ),
        JourneyStage(
          name: 'Refusal of the Call',
          description: 'Initial resistance to change',
          step: 3,
          isCompleted: false,
          progress: 0.7,
        ),
        JourneyStage(
          name: 'Meeting the Mentor',
          description: 'Finding guidance for your journey',
          step: 4,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Crossing the Threshold',
          description: 'Committing to the journey and entering the unknown',
          step: 5,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Tests, Allies, Enemies',
          description: 'Facing challenges and finding support',
          step: 6,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Approach to the Inmost Cave',
          description: 'Preparing for the major challenge ahead',
          step: 7,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Ordeal',
          description: 'Facing your greatest fear or challenge',
          step: 8,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Reward',
          description: 'Achieving the goal or receiving new insights',
          step: 9,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'The Road Back',
          description: 'Returning to your ordinary world with new knowledge',
          step: 10,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Resurrection',
          description: 'Final test of everything learned',
          step: 11,
          isCompleted: false,
          progress: 0.0,
        ),
        JourneyStage(
          name: 'Return with the Elixir',
          description: 'Using your newfound wisdom to help others',
          step: 12,
          isCompleted: false,
          progress: 0.0,
        ),
      ],
      currentStageIndex: 2, // "Refusal of the Call" is the current stage
      overallProgress: 0.22, // (1.0 + 1.0 + 0.7) / 12 ≈ 0.22
    );
  }
}
