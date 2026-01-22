# Soul Screen Redesign - Implementation Spec

> Daily AI-Generated Content with Visual Cards

**Status**: Implementation  
**Created**: January 22, 2026  
**Sprint Goal**: Connect existing background services to UI, add meditation cards with images

---

## Overview

Transform the Soul Screen from static protocol buttons to a dynamic, AI-powered daily content hub. The LLM (GPT-5 Chat) analyzes user data at midnight and on first app open, generating personalized:

- **Mantras** (3-5 daily affirmations)
- **Meditations** (by mood: Morning Energy, Stress Relief, Sleep Prep)
- **Insights** (CBT/Jungian observations)
- **Daily Prophecy** (zodiac + numerology + archetypes)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DAILY CONTENT FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

    TRIGGERS:
    ├── Midnight (background task)
    └── First app open of day (bootstrap)
              │
              ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  DAILY CONTENT SERVICE                                                   │
    │                                                                          │
    │  INPUTS:                                                                 │
    │  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────────┐ │
    │  │ genesis_profile  │ │ HealthKit Data   │ │ Weather                  │ │
    │  │ • zodiac         │ │ • sleep score    │ │ • temperature            │ │
    │  │ • numerology     │ │ • HRV            │ │ • conditions             │ │
    │  │ • archetypes     │ │ • workout mins   │ │                          │ │
    │  │ • MBTI (INTJ)    │ │ • resting HR     │ │                          │ │
    │  └──────────────────┘ └──────────────────┘ └──────────────────────────┘ │
    │  ┌──────────────────┐ ┌──────────────────┐                              │
    │  │ Yesterday's Data │ │ Princeps_Mantras │                              │
    │  │ • mood logs      │ │ (219 seed mantras│                              │
    │  │ • journal entries│ │  for context)    │                              │
    │  │ • meditations    │ │                  │                              │
    │  └──────────────────┘ └──────────────────┘                              │
    │                              │                                          │
    │                              ▼                                          │
    │  ┌─────────────────────────────────────────────────────────────────┐   │
    │  │                     GPT-5 Chat                                   │   │
    │  │                     (Quality content)                            │   │
    │  └─────────────────────────────────────────────────────────────────┘   │
    │                              │                                          │
    │                              ▼                                          │
    │  OUTPUTS (stored in generation_queue table):                            │
    │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
    │  │ Mantras (5)  │ │ Meditations  │ │ Insight Cards│ │ Prophecy     │   │
    │  │              │ │ (3 by mood)  │ │ (CBT/Jung)   │ │              │   │
    │  │ + Audio?     │ │ + Script     │ │              │ │              │   │
    │  │              │ │ + Audio      │ │              │ │              │   │
    │  │              │ │ + Image      │ │              │ │              │   │
    │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │
    └─────────────────────────────────────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  SQLite: generation_queue                                                │
    │  ┌─────────────────────────────────────────────────────────────────────┐│
    │  │ id | type       | content_date | output_data (JSON)    | audio_path ││
    │  │ 1  | mantra     | 2026-01-22   | {text, category}      | null       ││
    │  │ 2  | meditation | 2026-01-22   | {title, desc, script} | /gen/m.mp3 ││
    │  │ 3  | meditation | 2026-01-22   | {title, desc, script} | /gen/s.mp3 ││
    │  │ 4  | insight    | 2026-01-22   | {title, body, action} | null       ││
    │  │ 5  | prophecy   | 2026-01-22   | {text}                | null       ││
    │  └─────────────────────────────────────────────────────────────────────┘│
    └─────────────────────────────────────────────────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  SOUL SCREEN UI                                                          │
    │  ┌─────────────────────────────────────────────────────────────────────┐│
    │  │ DailyContentViewModel (new)                                         ││
    │  │ • loadTodayContent() → queries generation_queue                     ││
    │  │ • todayMantras: List<Mantra>                                        ││
    │  │ • todayMeditations: List<MeditationCard>                            ││
    │  │ • todayInsights: List<InsightCard>                                  ││
    │  │ • dailyProphecy: String                                             ││
    │  └─────────────────────────────────────────────────────────────────────┘│
    └─────────────────────────────────────────────────────────────────────────┘
```

---

## UI Layout

### Soul Screen Bottom Panel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  WHITE BOTTOM PANEL                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  HEADER ROW                                                      │   ││
│  │  │  "Let's make progress today!"    [🧘] [💬] [📿] [🔮]             │   ││
│  │  │                                   Med  NTS  Mantra Prophecy      │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  │  [WeekDayPicker] Mon Tue Wed [THU] Fri Sat                             ││
│  │                                                                         ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │ 📿 DAILY MANTRAS (Z-stacked swipeable cards)                     │   ││
│  │  │ ┌─────────────────────────────────────────────────────────────┐ │   ││
│  │  │ │ [MOTIVATION]                                                 │ │   ││
│  │  │ │ "This is my inflection point. It starts now.                │ │   ││
│  │  │ │  What I focus on, I become."                                │ │   ││
│  │  │ │                          ↑ Swipe to explore ↓               │ │   ││
│  │  │ └─────────────────────────────────────────────────────────────┘ │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                         ││
│  │  [SleepCard] Last Night 8h 0m | Score 85                               ││
│  │                                                                         ││
│  │  🧘 MEDITATIONS (horizontal scroll - with background images)           ││
│  │  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐       ││
│  │  │ ┌──────────────┐ │ │ ┌──────────────┐ │ │ ┌──────────────┐ │       ││
│  │  │ │ [FLUX Image] │ │ │ │ [FLUX Image] │ │ │ │ [FLUX Image] │ │       ││
│  │  │ │ Sunrise/Zen  │ │ │ │ Calm Water   │ │ │ │ Night Stars  │ │       ││
│  │  │ └──────────────┘ │ │ └──────────────┘ │ │ └──────────────┘ │       ││
│  │  │ Morning Energy   │ │ Stress Relief    │ │ Sleep Prep       │       ││
│  │  │ 5 min • Energize │ │ 10 min • Calm    │ │ 15 min • Relax   │       ││
│  │  └──────────────────┘ └──────────────────┘ └──────────────────┘       ││
│  │                                                                         ││
│  │  🔮 INSIGHTS (horizontal scroll - CBT/Jung analysis)                   ││
│  │  ┌──────────────────────────┐ ┌──────────────────────────┐             ││
│  │  │ 22/01 at 5:47 PM         │ │ Pattern Noticed          │             ││
│  │  │ "On the way home"        │ │ Your Hero archetype is   │             ││
│  │  │ I keep thinking about... │ │ driving action while...  │             ││
│  │  │ [Thoughts]               │ │ [Awareness]              │             ││
│  │  └──────────────────────────┘ └──────────────────────────┘             ││
│  │                                                                         ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

### Header Quick Actions (4 Icons)

| Icon | Label | Action |
|------|-------|--------|
| 🧘 | Meditate | → MeditationDetailScreen (today's session) |
| 💬 | NTS | → ChatScreen (Note to Self) |
| 📿 | Mantras | → MantraScreen (full standalone) |
| 🔮 | Prophecy | → Modal with daily prophecy |

---

## Data Models

### MeditationCard (for UI display)

```dart
class MeditationCard {
  final String id;
  final String title;          // "Morning Energy"
  final String description;    // "Start your day with clarity..."
  final String mood;           // "energize" | "calm" | "relax"
  final int durationMinutes;   // 5, 10, 15
  final String? imagePath;     // FLUX.2-pro generated image
  final String? audioPath;     // ElevenLabs audio file
  final String script;         // Full meditation script
  final DateTime contentDate;
}
```

### InsightCard (for UI display)

```dart
class InsightCard {
  final String id;
  final DateTime timestamp;
  final String? title;         // "On the way home" (optional)
  final String body;           // The observation/thought
  final String tag;            // "Thoughts", "Ideas", "Awareness", "Pattern"
  final InsightCategory category; // presence, awareness, integration
}
```

---

## Implementation Steps

### Phase 1: Foundation
1. ✅ Add `just_audio` to pubspec.yaml
2. Create `DailyContentViewModel` to query generation_queue
3. Create UI widgets: `MeditationCardWidget`, `InsightCardWidget`

### Phase 2: Soul Screen Update
4. Add header with 4 quick action icons
5. Replace protocol buttons with:
   - Mantra stacker (inline)
   - Meditation cards (horizontal scroll with images)
   - Insight cards (horizontal scroll)

### Phase 3: Background Services
6. Start `PsychographService.startBackgroundProcessing()` in HomeScreen
7. Call `DailyContentService.generateDailyMeditation()` in bootstrap
8. Add "first open of day" check in bootstrap

### Phase 4: Audio Playback
9. Add audio player to ActiveMeditationScreen
10. Load and play ElevenLabs MP3 from audio_path

---

## Files Modified

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `just_audio: ^0.9.36` |
| `lib/providers/viewmodels/daily_content_viewmodel.dart` | NEW: Load today's content |
| `lib/screens/soul_screen.dart` | New layout with cards |
| `lib/screens/home_screen.dart` | Start background processing |
| `lib/services/bootstrap_service.dart` | Trigger daily generation |
| `lib/widgets/organisms/mind/meditation_card_widget.dart` | NEW: Card with image |
| `lib/widgets/organisms/mind/insight_card_widget.dart` | NEW: Observation card |
| `lib/screens/active_meditation_screen.dart` | Add audio playback |

---

## Generation Queue Schema

The `generation_queue` table stores all AI-generated content:

```sql
CREATE TABLE generation_queue (
  id INTEGER PRIMARY KEY,
  type TEXT NOT NULL,           -- 'meditation', 'mantra', 'insight', 'prophecy'
  status TEXT DEFAULT 'pending',
  content_date TEXT,            -- '2026-01-22'
  input_data TEXT,              -- JSON: {mood, focus, weather}
  output_data TEXT,             -- JSON: {title, description, script, etc}
  image_path TEXT,              -- '/generated/meditation_morning.png'
  audio_path TEXT,              -- '/generated/meditation_morning.mp3'
  created_at TEXT,
  completed_at TEXT
);
```

---

## Success Criteria

- [ ] Soul screen loads today's generated mantras, meditations, insights
- [ ] Meditation cards show FLUX.2-pro images as backgrounds
- [ ] Tapping meditation card opens detail with audio playback
- [ ] Header icons navigate to sub-screens
- [ ] Content regenerates at midnight + first app open
- [ ] PsychographService updates RCA score hourly
