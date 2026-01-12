# Background Agent Specification

> The "Subconscious LLM" - Odelle's background processing system

**Status**: Planning  
**Last Updated**: January 11, 2026

---

## Overview

The Background Agent is the "subconscious" processing layer of Odelle. It runs periodically (hourly for psychograph, daily for content generation) to:

1. **Observe** - Gather context about the user's state, environment, and data
2. **Process** - Analyze patterns, compute metrics, generate insights
3. **Create** - Generate personalized content (meditations, affirmations, images)
4. **Act** - Update data, trigger notifications, prepare for conversations

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BACKGROUND AGENT SYSTEM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────────┐   │
│  │ PsychographSvc  │   │ DailyContentSvc │   │ (Future) NotificationSvc│   │
│  │ (Every 60 min)  │   │ (Once/day)      │   │ (Event-driven)          │   │
│  └────────┬────────┘   └────────┬────────┘   └────────────────────────-┘   │
│           │                     │                                          │
│           ▼                     ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                     CONTEXT GATHERING                              │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │    │
│  │  │ Genesis      │  │ Weather      │  │ Health/Workout Data      │ │    │
│  │  │ Profile      │  │ Service      │  │ (HealthKit)              │ │    │
│  │  │ (who you are)│  │ (environment)│  │ (body state)             │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │    │
│  │  │ Journal      │  │ Dose Logs    │  │ Time of Day /            │ │    │
│  │  │ Entries      │  │ (microdosing)│  │ Plasticity Windows       │ │    │
│  │  │ (mind state) │  │ (experiment) │  │ (circadian)              │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│                                    │                                        │
│                                    ▼                                        │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                         LLM PROCESSING                             │    │
│  │                     (gpt-5-nano - fast/cheap)                      │    │
│  │                                                                    │    │
│  │  • Compute RCA Meter (Raising Conscious Awareness)                 │    │
│  │  • Generate Psychograph (evolving understanding)                   │    │
│  │  • Produce Insights (actionable patterns)                          │    │
│  │  • Weather-aware suggestions ("Great day for outdoor meditation")  │    │
│  │  • Time-aware content (morning mantras vs evening reflection)      │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│                                    │                                        │
│                                    ▼                                        │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │                      OUTPUT GENERATION                             │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │    │
│  │  │ Meditation   │  │ Affirmation  │  │ Daily Image              │ │    │
│  │  │ Audio        │  │ Audio        │  │ (consistent style)       │ │    │
│  │  │ (ElevenLabs) │  │ (ElevenLabs) │  │ (FLUX.2-pro)             │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │    │
│  │                                                                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │    │
│  │  │ Updated      │  │ Notifications│  │ Workout Suggestions      │ │    │
│  │  │ Psychograph  │  │ (if enabled) │  │ (time + weather aware)   │ │    │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Services

### 1. PsychographService (Hourly)

**Purpose**: Maintain an evolving understanding of the user

**Inputs**:
- Genesis Profile (identity, mission, archetypes)
- Character Stats (current state, RCA meter)
- Mantras (active affirmations)
- Journal Entries (recent thoughts)
- Dose Logs (microdosing experiment data)
- Mood/Check-in Data

**Outputs**:
- **RCA Score** (0-100) - Raising Conscious Awareness meter
  - Presence (meditation, mindfulness)
  - Awareness (journaling, CBT engagement)
  - Integration (behavioral consistency)
- **Psychograph** - AI-generated summary of current state
- **Insights** - Actionable patterns noticed

**Model**: `gpt-5-nano` (fast, cheap for background processing)

---

### 2. DailyContentService (Once/Day at Midnight)

**Purpose**: Generate personalized daily content

**Inputs**:
- Current Psychograph State
- Weather Conditions (via WeatherKit)
- Time/Season Context
- User's Archetypes

**Outputs**:
- **Meditation Script** (3-5 min, personalized)
- **Meditation Audio** (via ElevenLabs TTS)
- **Daily Affirmation** (1-2 sentences)
- **Affirmation Audio** (via ElevenLabs TTS)
- **Daily Image** (via FLUX.2-pro, consistent zen style)

**Voice Synthesis Decision**:
- **ElevenLabs** - Higher quality voices, better for meditation
  - 10 min/month free tier, turbo model for efficiency
  - Selected voices: Lily (meditation), Bella (affirmation)
- **Azure TTS** - Alternative with 600+ voices
  - Already in our Azure subscription
  - May consider for workout/energetic content

---

## Weather Integration

The agent should consider weather when:

### Morning Context (07:00)
```
Weather: 72°F, Clear, Low UV
Suggestion: "Perfect weather for an outdoor morning meditation. 
             Consider your walk after gym."
```

### Workout Suggestions
```
Weather: 85°F, Humid, High UV
Suggestion: "Hot day - indoor gym recommended. 
             Hydrate extra. Evening walk after 6pm when it cools."
```

### Mood Correlation
```
Weather: Overcast, Rainy, 55°F
Note: "Gray days can affect mood. Extra attention to 
       morning mantras and light exposure."
```

### Seasonal Awareness
```
Season: Winter (shorter days)
Note: "Reduced daylight may impact vitamin D and mood. 
       Morning light exposure especially important."
```

---

## Timing & Plasticity Windows

The agent is aware of the user's optimal windows:

| Window | Time | Agent Action |
|--------|------|--------------|
| **Morning Plasticity** | 07:00-08:00 | Prepare mantras, meditation ready |
| **Post-Workout Peak** | 08:15-09:00 | Capture insights, voice journal prompt |
| **Afternoon Dip** | 14:00-15:00 | Gentle reminder, breath work suggestion |
| **Evening Wind-Down** | 21:00-22:00 | Reflection prompt, next-day prep |

---

## Data Models Used

| Model | Location | Purpose |
|-------|----------|---------|
| `genesis_profile.json` | data/user/ | Identity, mission, archetypes |
| `character_stats.json` | data/misc/ | RCA meter, psychograph, stats |
| `mantras.json` | data/misc/ | User's active mantras |
| `journal_entry.dart` | models/ | Journal/voice entries |
| `dose_log.dart` | models/tracking/ | Microdosing experiment |
| `workout_log.dart` | models/tracking/ | Gym sessions |
| `CurrentWeather` | services/ | Weather conditions |

---

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| PsychographService | ⚠️ Created, needs fixes | Logger/API signature issues |
| DailyContentService | ⚠️ Created, needs fixes | Same issues as above |
| ElevenLabsConfig | ✅ Done | API key in .env |
| WeatherService | ✅ Exists | Already integrated |
| Genesis Profile | ✅ Seeded | data/user/genesis_profile.json |
| Service Providers | ✅ Wired | In service_providers.dart |
| CI/CD Secrets | ⚠️ Pending | Need to add ELEVENLABS_API_KEY via gh CLI |

---

## Next Steps

1. **Fix DailyContentService** - Resolve API signature mismatches
2. **Integrate Weather** - Add WeatherService to background processing
3. **Add ELEVENLABS_API_KEY** to GitHub Secrets
4. **Test end-to-end** - Run background processing, verify outputs
5. **Notification System** - Connect to iOS notifications for check-ins

---

## Voice Provider Comparison

### ElevenLabs (Current Choice)
**Pros**:
- Industry-leading voice quality
- Natural, expressive meditation voices
- Fast turbo model available

**Cons**:
- 10 min/month free tier (need paid for heavy use)
- Additional API to manage

### Azure TTS (Alternative)
**Pros**:
- 600+ voices
- Already in our Azure subscription
- No additional cost

**Cons**:
- Voices less natural than ElevenLabs
- May require more tuning for meditation tone

**Decision**: Use ElevenLabs for meditation/affirmation (quality matters). Consider Azure for workout cues or fallback.

---

*This is a living document. Update as implementation progresses.*
