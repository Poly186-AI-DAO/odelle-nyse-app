# Odelle Nyse Technical Context

## Technology Stack
- **Flutter**: Main framework for cross-platform mobile app development
- **LiveKit**: Real-time audio/video SDK used for voice assistant functionality
- **Google Fonts**: Typography (Work Sans for body text, Montserrat for headings)
- **Glass Package**: For glassmorphic UI effects (replaced ui_glass_effect)
- **Provider**: For state management
- **Flutter dotenv**: For environment variable management

## Current Color Scheme
```dart
class AppColors {
  static const Color primary = Color(0xFF8ECAE6); // Light Blue
  static const Color secondary = Color(0xFF219EBC); // Teal Blue
  static const Color accent = Color(0xFFFFB703); // Golden Yellow
  static const Color background = Color(0xFFF8F9FA); // Off-White
  static const Color textPrimary = Color(0xFF023047); // Dark Blue
  static const Color textSecondary = Color(0xFF8B8C89); // Gray
}
```

## Enhanced Color Scheme (To Implement)
We need to create a more saturated version of the color scheme while maintaining the aesthetic:

```dart
class AppColors {
  static const Color primary = Color(0xFF55BBFF); // Saturated Blue
  static const Color secondary = Color(0xFF0085C7); // Deep Teal Blue
  static const Color accent = Color(0xFFFF9500); // Vibrant Orange
  static const Color background = Color(0xFFF8F9FA); // Off-White (keep as is)
  static const Color textPrimary = Color(0xFF012A41); // Darker Blue
  static const Color textSecondary = Color(0xFF6D6E6B); // Darker Gray
}
```

## Glassmorphism Implementation
The app uses a custom `GlassMorphism` widget for the frosted glass effect:

```dart
GlassMorphism(
  blur: 18,
  opacity: 0.13,
  color: AppColors.background,
  child: Widget(...),
)
```

## LiveKit Integration
LiveKit is used for voice assistant functionality. Key components:
- Voice assistant button triggers navigation to voice assistant screen
- Audio waveform visualization
- Transcription view for speech-to-text
- Voice control interface

## Animation Requirements
Need to add animations for:
1. Card transitions and interactions
2. Data visualization (radar graph)
3. Voice assistant button and interface
4. Microphone audio level visualization

## Data Models
Need to create models for:
1. User Journey progress
2. Insights data (for radar graph)
3. Daily affirmations
4. Thought/Emotion/Behavior tracking
