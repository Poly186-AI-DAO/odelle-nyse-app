# Navigation Flow & User Journeys

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HOME SCREEN                                    │
│                     (Infinite Horizontal Pager)                         │
├────────────────┬────────────────────────┬───────────────────────────────┤
│                │                        │                               │
│   BODY (←)     │      VOICE (Center)    │        MIND (→)              │
│   Pillar 0     │      Pillar 1 (Home)   │        Pillar 2              │
│                │                        │                               │
│  ┌──────────┐  │    ┌──────────────┐    │   ┌──────────────┐           │
│  │Hero Card │  │    │  Hero Card   │    │   │  Hero Card   │           │
│  │(Calories)│  │    │  (Greeting)  │    │   │  (Identity)  │           │
│  └──────────┘  │    └──────────────┘    │   └──────────────┘           │
│  ┌──────────┐  │    ┌──────────────┐    │   ┌──────────────┐           │
│  │ Bottom   │  │    │Light Silver  │    │   │   Bottom     │           │
│  │ Panel    │  │    │ Background   │    │   │   Panel      │           │
│  └──────────┘  │    └──────────────┘    │   └──────────────┘           │
│                │                        │                               │
└────────────────┴────────────────────────┴───────────────────────────────┘
```

---

## Pillar Navigation (Swipe Horizontal)

| From | Swipe Left | Swipe Right |
|------|------------|-------------|
| Body | Voice | Body (loops) |
| Voice | Mind | Body |
| Mind | Mind (loops) | Voice |

**Entry Point**: App opens on **Voice** (Pillar 1, center).

---

## Bottom Panel → Detail Screen Navigation

### Body Pillar (Tracking)

```
Body Screen
├── [Hero] Calorie Overview
│
└── [Bottom Panel] (Draggable, expandable)
    ├── Macros Row (Protein, Carbs, Fat)
    │
    ├── TODAY'S MEALS
    │   ├── MealTimelineRow → [Tap] → Meal Detail (TODO)
    │   └── ...
    │
    ├── SUPPLEMENTS
    │   ├── DoseCard → [Tap] → Supplement Detail (TODO)
    │   └── ...
    │
    └── ACTIVITY
        └── WorkoutCard → [Tap] → Workout Detail (TODO)
```

### Voice Pillar (Conversation)

```
Voice Screen
├── [Hero Card] Greeting / AI Response / Recording State
│
└── [Light Background] Voice Button (FAB)
    └── [Tap] → Connect/Disconnect to Azure Realtime
    └── [Long Press] → Debug Dialog
```

### Mind Pillar (Self)

```
Mind Screen
├── [Hero] Identity Matrix (Archetypes, Astrology, Life Path)
│
└── [Bottom Panel]
    ├── SleepCard → [Tap] → Sleep Detail (TODO)
    │
    ├── OPEN PROTOCOLS
    │   ├── Journal → [Tap] → Journal Screen (TODO)
    │   └── Breathe → [Tap] → Breathing Exercise (TODO)
    │
    └── CONTINUE LEARNING
        └── ContentCard → [Tap] → Lesson Player (TODO)
```

---

## Detail Screen Navigation (Push/Pop)

| Parent | Tap Target | Destination | Status |
|--------|------------|-------------|--------|
| Body | MealTimelineRow | MealDetailScreen | TODO |
| Body | DoseCard | SupplementDetailScreen | TODO |
| Body | WorkoutCard | WorkoutDetailScreen | TODO |
| Mind | SleepCard | SleepDetailScreen | TODO |
| Mind | Journal Button | JournalScreen | TODO |
| Mind | Breathe Button | BreathingScreen | TODO |
| Mind | ContentCard | LessonPlayerScreen | TODO |

---

## FAB (Voice Button) Behavior

| Current Screen | Tap Action | Visual State |
|----------------|------------|--------------|
| Voice | Connect/Disconnect | Green ring (connected) |
| Body/Mind | Start/Stop transcription | Blue glow (recording) |
| Any (locked) | Navigate to locked screen | Lock icon shown |

---

## Back Navigation

- **Swipe back** on Detail screens pops back to parent Pillar.
- **Bottom panel drag down** collapses to minimum height.
- **Nav bar tap** on current pillar icon does nothing (already there).

---

## Future: Profile Screen

Profile is accessed via a separate route (e.g., from settings or avatar tap).

```
Profile Screen
├── [Hero] ProfileHeader (Avatar, Name, Level)
│
└── [Bottom Panel]
    ├── Stats Grid
    └── Achievement Badges
```
