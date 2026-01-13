# Navigation Flow & User Journeys

> *"Your Soul Bonds Now with Health and Wealth"*

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              HOME SCREEN                                    │
│                        (Infinite Horizontal Pager)                          │
├──────────┬──────────┬──────────────┬──────────────┬───────────────────────┤
│   SOUL   │  BONDS   │     NOW      │    HEALTH    │       WEALTH          │
│ (Wisdom) │(Connect) │  (Digital    │   (Body)     │     (Finance)         │
│ Pillar 0 │ Pillar 1 │  Twin) - 2   │   Pillar 3   │     Pillar 4          │
├──────────┼──────────┼──────────────┼──────────────┼───────────────────────┤
│  Hero:   │  Hero:   │    Hero:     │    Hero:     │       Hero:           │
│ Identity │ Connect  │  Greeting/   │  Calories    │    Cash Flow          │
│  Matrix  │ Reminder │  AI Response │   Summary    │     Summary           │
├──────────┼──────────┼──────────────┼──────────────┼───────────────────────┤
│  Panel:  │  Panel:  │              │    Panel:    │       Panel:          │
│  Sleep   │ Contacts │   Voice FAB  │   Meals      │    Bills Due          │
│ Mantras  │ Reach-   │  (No panel)  │  Workouts    │   Subscriptions       │
│ Meditate │  outs    │              │   Supps      │      Income           │
└──────────┴──────────┴──────────────┴──────────────┴───────────────────────┘
```

---

## Pillar Navigation (Swipe Horizontal)

| From | Swipe Left | Swipe Right |
|------|------------|-------------|
| Soul | Bonds | Soul (loops) |
| Bonds | Now | Soul |
| Now | Health | Bonds |
| Health | Wealth | Now |
| Wealth | Wealth (loops) | Health |

**Entry Point**: App opens on **Now** (Pillar 2, center) — where Odelle lives.

---

## Bottom Panel → Detail Screen Navigation

### Soul Pillar (Wisdom)

```
Soul Screen (formerly Mind)
├── [Hero] Identity Matrix (Archetypes, Astrology, Life Path)
│
└── [Bottom Panel]
    ├── SleepCard → [Tap] → Sleep Detail (TODO)
    │
    ├── OPEN PROTOCOLS
    │   ├── Mantras → [Tap] → Mantra Screen
    │   ├── Meditate → [Tap] → Meditation Screen
    │   └── Breathe → [Tap] → Breathing Exercise (TODO)
    │
    └── CONTINUE LEARNING
        └── ContentCard → [Tap] → Lesson Player (TODO)
```

### Bonds Pillar (Relationships)

```
Bonds Screen [NEW]
├── [Hero] "Stay Connected" / Relationship Health Score
│
└── [Bottom Panel]
    ├── PRIORITY CONTACTS
    │   ├── ContactCard → [Tap] → Contact Detail
    │   └── ...
    │
    ├── REACH OUT TO
    │   └── Suggested contacts (overdue for connection)
    │
    └── RECENT INTERACTIONS
        └── InteractionLog → [Tap] → Add/Edit Interaction
```

### Now Pillar (Digital Twin Center)

```
Now Screen (formerly Voice)
├── [Hero Card] Greeting / AI Response / Recording State
│
└── [Light Background] Voice Button (FAB)
    └── [Tap] → Connect/Disconnect to Azure Realtime
    └── [Long Press] → Debug Dialog
```

### Health Pillar (Body)

```
Health Screen (formerly Body)
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

### Wealth Pillar (Finance)

```
Wealth Screen [NEW]
├── [Hero] Monthly Cash Flow Summary
│
└── [Bottom Panel]
    ├── BILLS DUE
    │   ├── BillCard → [Tap] → Bill Detail
    │   └── ...
    │
    ├── SUBSCRIPTIONS
    │   ├── SubscriptionCard → [Tap] → Subscription Detail
    │   └── ...
    │
    └── INCOME
        └── IncomeCard → [Tap] → Income Detail
```

---

## Detail Screen Navigation (Push/Pop)

| Parent | Tap Target | Destination | Status |
|--------|------------|-------------|--------|
| Health | MealTimelineRow | MealDetailScreen | TODO |
| Health | DoseCard | SupplementDetailScreen | TODO |
| Health | WorkoutCard | WorkoutDetailScreen | TODO |
| Soul | SleepCard | SleepDetailScreen | TODO |
| Soul | Mantras Button | MantraScreen | ✅ |
| Soul | Meditate Button | MeditationScreen | ✅ |
| Soul | Breathe Button | BreathingScreen | TODO |
| Soul | ContentCard | LessonPlayerScreen | TODO |
| Bonds | ContactCard | ContactDetailScreen | TODO |
| Bonds | InteractionLog | InteractionDetailScreen | TODO |
| Wealth | BillCard | BillDetailScreen | TODO |
| Wealth | SubscriptionCard | SubscriptionDetailScreen | TODO |

---

## FAB (Voice Button) Behavior

| Current Screen | Tap Action | Visual State |
|----------------|------------|--------------|
| Now | Connect/Disconnect | Green ring (connected) |
| Soul/Bonds/Health/Wealth | Start/Stop transcription | Blue glow (recording) |
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
