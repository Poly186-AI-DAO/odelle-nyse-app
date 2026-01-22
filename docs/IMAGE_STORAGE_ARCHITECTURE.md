# Image Storage Architecture

> Last Updated: January 22, 2026

## Overview

This document defines the standardized image and media storage patterns used across the Odelle app. All generated images use Azure's FLUX.2-pro model via `AzureImageService`.

## Directory Structure

```
/images/
├── exercises/      # Exercise demonstration images
├── insights/       # Psychograph insights & prophecy images
├── mantras/        # Daily mantra visualization images
├── meals/          # AI-generated meal images
├── meditations/    # Meditation visualization images
└── workouts/       # Workout log images

/audio/
└── meditations/    # Meditation audio files (ElevenLabs TTS)
```

## Naming Conventions

| Content Type | Pattern | Example |
|-------------|---------|---------|
| Exercises | `exercise_{name}.png` | `exercise_bench_press.png` |
| Insights | `insight_{i}_{j}_{date}.png` | `insight_0_1_2026-01-22.png` |
| Prophecy | `prophecy_{i}_{date}.png` | `prophecy_0_2026-01-22.png` |
| Mantras | `mantra_{i}_{date}.png` | `mantra_0_2026-01-22.png` |
| Meals | `meal_{id}.png` | `meal_abc123.png` |
| Meditations | `meditation_{date}.png` | `meditation_2026-01-22.png` |
| Workouts | `workout_{id}.png` | `workout_xyz789.png` |

## Service Implementations

### 1. ContentGenerationService (`content_generation_service.dart`)
- **Content**: Exercise images
- **Path**: `/images/exercises/`
- **Method**: `_saveImageFile()`

```dart
Future<String> _saveImageFile(Uint8List bytes, String exerciseName) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = 'exercise_${exerciseName.toLowerCase().replaceAll(' ', '_')}.png';
  final file = File('${dir.path}/images/exercises/$fileName');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}
```

### 2. PsychographService (`psychograph_service.dart`)
- **Content**: Insight & prophecy images
- **Path**: `/images/insights/`
- **Method**: `_saveImageFile()`

```dart
Future<String> _saveImageFile(Uint8List bytes, String prefix, int index) async {
  final dir = await getApplicationDocumentsDirectory();
  final date = DateTime.now().toIso8601String().split('T').first;
  final fileName = '${prefix}_${index}_$date.png';
  final file = File('${dir.path}/images/insights/$fileName');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}
```

### 3. DailyContentService (`daily_content_service.dart`)
- **Content**: Mantras, meditations (images + audio)
- **Paths**: `/images/meditations/`, `/images/mantras/`, `/audio/meditations/`
- **Method**: `_saveLocalFile()` with smart subdirectory routing

```dart
Future<String> _saveLocalFile(Uint8List bytes, String prefix, String extension) async {
  final dir = await getApplicationDocumentsDirectory();
  final date = DateTime.now().toIso8601String().split('T').first;
  final fileName = '${prefix}_$date.$extension';
  
  // Smart subdirectory based on file type
  final subdirectory = extension == 'mp3' ? 'audio' : 'images';
  final contentType = prefix.contains('mantra') ? 'mantras' : 'meditations';
  
  final file = File('${dir.path}/$subdirectory/$contentType/$fileName');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}
```

### 4. BodyViewModel (`body_viewmodel.dart`)
- **Content**: Meal & workout images
- **Paths**: `/images/meals/`, `/images/workouts/`
- **Methods**: `_saveMealImage()`, `_saveWorkoutImage()`

```dart
Future<String> _saveMealImage(Uint8List bytes, String mealId) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/images/meals/meal_$mealId.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<String> _saveWorkoutImage(Uint8List bytes, String workoutId) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/images/workouts/workout_$workoutId.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}
```

## Database Tables

### Image Tracking Tables (Migration v13)

```sql
CREATE TABLE IF NOT EXISTS mantra_images (
  id TEXT PRIMARY KEY,
  mantra_id TEXT NOT NULL,
  image_path TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (mantra_id) REFERENCES mantras(id)
);

CREATE TABLE IF NOT EXISTS workout_images (
  id TEXT PRIMARY KEY,
  workout_id TEXT NOT NULL,
  image_path TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (workout_id) REFERENCES workout_logs(id)
);
```

## Image Generation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Image Generation Flow                       │
└─────────────────────────────────────────────────────────────────┘

  ┌──────────────┐     ┌───────────────────┐     ┌──────────────┐
  │   Service    │────>│ AzureImageService │────>│ FLUX.2-pro   │
  │  (Generate)  │     │   .generateImage  │     │    (Azure)   │
  └──────────────┘     └───────────────────┘     └──────────────┘
         │                                              │
         │                                              │
         v                                              v
  ┌──────────────┐                              ┌──────────────┐
  │ Create Smart │                              │   Return     │
  │    Prompt    │                              │  Uint8List   │
  └──────────────┘                              └──────────────┘
                                                       │
                                                       v
                                               ┌──────────────┐
                                               │  _saveFile   │
                                               │   Method     │
                                               └──────────────┘
                                                       │
                                                       v
                                               ┌──────────────┐
                                               │  /images/    │
                                               │ {content}/   │
                                               └──────────────┘
```

## Prompt Engineering

Each content type has specialized prompt generation:

### Prophecy/Insight Prompts
- Ethereal, mystical atmosphere
- Cosmic and metaphysical elements
- User psychograph-aware theming

### Mantra Prompts
- Typography-focused
- Inspirational mood
- Theme-color integration

### Workout Prompts
- Activity-specific (strength, cardio, yoga, HIIT)
- Dynamic, energetic composition
- Realistic fitness photography style

### Meal Prompts
- Food photography style
- Ingredient-aware composition
- Appetizing lighting and presentation

## Error Handling

All image generation follows a graceful degradation pattern:

```dart
try {
  final bytes = await _imageService.generateImage(prompt, size: ImageSize.square);
  if (bytes != null) {
    final path = await _saveImageFile(bytes, ...);
    // Update model with imagePath
  }
} catch (e) {
  _logger.e('Image generation failed', e);
  // Content works without image - no user-facing error
}
```

## Background Generation

Images are generated in the background to avoid blocking UI:

1. **Bootstrap Phase**: Prophecy images via `dailyProphecyImagesProvider`
2. **Content Creation**: Inline during content generation
3. **Backfill**: `_checkForMissingImages()` fills gaps on demand

## Future Considerations

- [ ] Image caching layer with expiration
- [ ] Thumbnail generation for list views
- [ ] Cloud backup of generated images
- [ ] Image compression optimization
- [ ] Progressive loading placeholders
