# Odelle Nyse - Parallel Work Streams
## Breaking Down the Build for Multiple Agents

**Date**: January 2026  
**Status**: ACTIVE BUILD  
**Primary Goal**: Get voice tap → transcription → local storage working

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ODELLE NYSE (ON)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   STREAM 1   │    │   STREAM 2   │    │   STREAM 3   │      │
│  │  Voice Core  │    │ Data Models  │    │     UI       │      │
│  │              │    │              │    │              │      │
│  │ • Azure STT  │    │ • Room DB    │    │ • Dashboard  │      │
│  │ • Mic Input  │    │ • Journal    │    │ • Radar      │      │
│  │ • Transcript │    │ • Protocol   │    │ • Logging    │      │
│  └──────────────┘    │ • Stats      │    └──────────────┘      │
│         │            └──────────────┘           │               │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             ▼                                   │
│                    ┌──────────────┐                            │
│                    │  Local Room  │                            │
│                    │   Database   │                            │
│                    └──────────────┘                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔴 STREAM 1: Voice Core (PRIMARY - Agent 1)
**Owner**: Copilot (Primary)  
**Priority**: HIGHEST - Everything else depends on this

### Goal
Tap microphone → Azure Speech-to-Text → Display transcription → Save to local DB

### Tech Stack
- **Azure Speech SDK** (REST API for Flutter compatibility)
- **Microphone**: `mic_stream` package (already in pubspec)
- **Audio Processing**: Convert to PCM16 for Azure

### Environment Variables (Already in .env)
```bash
AZURE_SPEECH_KEY=<your-azure-key>
AZURE_SPEECH_REGION=eastus2
```

### Files to Create/Modify
1. `lib/services/azure_speech_service.dart` - NEW: Direct Azure STT service
2. `lib/screens/voice_journal_screen.dart` - NEW: Main voice capture UI
3. `lib/providers/voice_provider.dart` - NEW: Voice state management

### API Endpoint (Azure Speech-to-Text REST)
```
POST https://eastus2.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US
Headers:
  Ocp-Apim-Subscription-Key: <AZURE_SPEECH_KEY>
  Content-Type: audio/wav; codecs=audio/pcm; samplerate=16000
Body: <binary PCM audio data>
```

### Implementation Steps
1. ✅ Check existing Azure service
2. [ ] Create simplified `AzureSpeechService` (REST-based, no WebRTC)
3. [ ] Create `VoiceJournalScreen` with tap-to-record
4. [ ] Integrate `mic_stream` for audio capture
5. [ ] Convert audio to PCM16 format
6. [ ] Send to Azure, get transcription
7. [ ] Display result and save to local DB

---

## 🟡 STREAM 2: Data Models & Local Database (Agent 2)
**Owner**: Secondary Agent  
**Priority**: HIGH - Needed for persistence

### Goal
Create Room-style local database with models for all protocol logging

### Tech Stack
- **Database**: `sqflite` or `drift` (Room equivalent for Flutter)
- **Models**: Dart classes with JSON serialization

### Files to Create
```
lib/
├── database/
│   ├── app_database.dart         # Database singleton
│   └── daos/
│       ├── journal_dao.dart      # Journal entry operations
│       ├── protocol_dao.dart     # Protocol log operations
│       └── stats_dao.dart        # Character stats operations
├── models/
│   ├── journal_entry.dart        # Voice journal entries
│   ├── protocol_entry.dart       # Gym, meal, dose, meditation
│   ├── character_stats.dart      # RPG stats (strength, intellect, spirit, sales)
│   ├── mantra.dart               # User mantras/affirmations
│   └── daily_log.dart            # Daily summary aggregate
```

### Model Definitions

#### JournalEntry
```dart
class JournalEntry {
  final int? id;
  final DateTime timestamp;
  final String transcription;
  final double? mood;           // 1-10
  final String? sentiment;      // positive/negative/neutral
  final List<String> tags;
  
  // Constructors, toMap, fromMap
}
```

#### ProtocolEntry
```dart
enum ProtocolType { gym, meal, dose, meditation, focus, sleep }

class ProtocolEntry {
  final int? id;
  final DateTime timestamp;
  final ProtocolType type;
  final Map<String, dynamic> data;  // Type-specific (reps, grams, mg, minutes)
  final String? notes;
  
  // Constructors, toMap, fromMap
}
```

#### CharacterStats
```dart
class CharacterStats {
  final int? id;
  final DateTime date;
  final double strength;     // Gym consistency
  final double intellect;    // Focus/work hours
  final double spirit;       // Meditation/mood
  final double sales;        // Outreach/deals
  final int totalXP;
  final int level;
  
  // Constructors, toMap, fromMap
}
```

#### Mantra
```dart
class Mantra {
  final int? id;
  final String text;
  final bool isActive;
  final DateTime createdAt;
  
  // Constructors, toMap, fromMap
}
```

### Database Schema (SQLite)
```sql
CREATE TABLE journal_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  transcription TEXT NOT NULL,
  mood REAL,
  sentiment TEXT,
  tags TEXT  -- JSON array
);

CREATE TABLE protocol_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  type TEXT NOT NULL,
  data TEXT NOT NULL,  -- JSON
  notes TEXT
);

CREATE TABLE character_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  strength REAL DEFAULT 0,
  intellect REAL DEFAULT 0,
  spirit REAL DEFAULT 0,
  sales REAL DEFAULT 0,
  total_xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1
);

CREATE TABLE mantras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL
);
```

---

## 🟢 STREAM 3: UI & Visualization (Agent 3)
**Owner**: UI Agent  
**Priority**: MEDIUM - Can be built in parallel

### Goal
Dashboard with Character Radar, Protocol Quick-Log buttons, Journal view

### Files to Create/Modify
```
lib/
├── screens/
│   ├── dashboard_screen.dart     # Main home with radar + actions
│   ├── protocol_log_screen.dart  # Log gym, meals, dose, meditation
│   ├── journal_list_screen.dart  # View past voice entries
│   └── mantra_screen.dart        # Manage mantras
├── widgets/
│   ├── character_radar.dart      # RPG stat radar chart
│   ├── protocol_button.dart      # Quick-log action button
│   ├── daily_streak.dart         # Streak counter
│   └── mood_selector.dart        # Mood quick-select (1-10 or emoji)
```

### Character Radar Widget
Uses custom painter to draw polygon chart:
```
           STRENGTH (100)
              ▲
              │
              │
   SPIRIT ◄───┼───► INTELLECT
              │
              │
              ▼
            SALES
```

### Quick-Log Buttons
```
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│   💪    │ │   🥗    │ │   💊    │ │   🧘    │
│   GYM   │ │  MEAL   │ │  DOSE   │ │  MEDI   │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

---

## Dependencies Between Streams

```
STREAM 1 (Voice)
    │
    ▼
STREAM 2 (Models/DB) ◄──── Needed to save transcriptions
    │
    ▼
STREAM 3 (UI) ◄──────────── Displays saved data
```

**Minimum Viable Demo**: Stream 1 + Stream 2 (basic) = Tap → Speak → See Transcription → Saved

---

## Immediate Next Steps

### Agent 1 (Copilot - PRIMARY)
1. Create `AzureSpeechService` with REST API
2. Create `VoiceJournalScreen` with tap-to-record
3. Wire up mic_stream → Azure → Display

### Agent 2 (Models Agent)
1. Add `sqflite` to pubspec.yaml
2. Create database singleton
3. Create all model classes
4. Create DAO classes

### Agent 3 (UI Agent)
1. Create `DashboardScreen` layout
2. Create `CharacterRadar` widget
3. Create `ProtocolButton` components

---

## Environment Notes

### Using Azure Speech (NOT LiveKit)
We're using Azure Speech-to-Text REST API directly:
- No WebRTC needed for basic transcription
- Simpler setup, faster iteration
- Keys already in `.env`

### Local Database (NOT MongoDB)
Using SQLite via `sqflite`:
- Works offline
- No server setup needed
- Can later sync to cloud
- Fast for mobile

---

## Success Criteria for Stream Build

By end of stream:
- [ ] Tap mic → recording starts
- [ ] Release → audio sent to Azure
- [ ] Transcription appears on screen
- [ ] Entry saved to local SQLite
- [ ] Can view past entries

*Let's build.* 🔥
