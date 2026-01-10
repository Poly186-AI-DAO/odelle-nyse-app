# Odelle Nyse (ON) - Live Build Plan
## Stream Build Guide: From Poly Client to Self-Actualization OS

**Stream Title**: "I Won't Die a Broke Tesla": Engineering My Own AI Savior (Live Build)  
**Date**: January 2026  
**Starting Point**: PolyMobileClient (Flutter app in TestFlight)  
**Target**: Odelle Nyse v0.1 - Voice-first self-improvement assistant

---

## Pre-Stream Setup Checklist

- [ ] Clone PolyMobileClient repo
- [ ] Rename all Poly references to ON/Odelle
- [ ] Set up `.env` file with required keys
- [ ] Verify emulator/simulator is running
- [ ] Test that base app compiles

---

## Required Environment Variables

Based on the PolyMobileClient, we need these in `.env`:

```bash
# Backend (Poly Servers for Voice)
POLY_PRODUCTION_BACKEND_URL=https://api.poly186.ai

# Google OAuth (for future calendar/health integrations)
GOOGLE_IOS_CLIENT_ID=your_ios_client_id
GOOGLE_WEB_CLIENT_ID=your_web_client_id

# Optional: Azure Voice (backup transcription)
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=your_region
```

---

## Hour-by-Hour Build Milestones

### 🕐 HOUR 1: Foundation (Setup & Rename)
**Goal**: Get the app running as "Odelle Nyse"

| Task | Time | Deliverable |
|------|------|-------------|
| Clone PolyMobileClient | 5 min | Fresh copy in odelle-nyse-app |
| Rename package to `OdelleNyse` | 10 min | pubspec.yaml updated |
| Update app name & branding | 10 min | "ON" appears in app |
| Replace Poly colors with ON colors | 15 min | Orange/Purple gradient (from VoiceNoteScreen) |
| Test build on simulator | 10 min | App launches with new name |
| Create ON logo placeholder | 10 min | Simple "ON" text or icon |

**Hour 1 Demo**: App launches, shows "Odelle Nyse" branding, basic navigation works.

---

### 🕑 HOUR 2: Voice Core (The "Kitchen Confessional")
**Goal**: Voice input that captures thoughts

| Task | Time | Deliverable |
|------|------|-------------|
| Adapt VoiceNoteScreen as main screen | 15 min | Single-page voice interface |
| Connect to existing Poly voice backend | 15 min | Transcription working |
| Add "Note to self" trigger phrase | 10 min | Keyword detection |
| Create voice journal entry model | 10 min | LocalStorage for entries |
| Display captured entries list | 10 min | Simple scrollable list |

**Hour 2 Demo**: Tap mic, speak, see transcription appear as journal entry.

---

### 🕒 HOUR 3: Protocol Logging (The Tracker)
**Goal**: Log daily protocol activities

| Task | Time | Deliverable |
|------|------|-------------|
| Create `ProtocolEntry` model | 10 min | Fields: type, timestamp, value, notes |
| Add quick-log buttons | 15 min | "Gym", "Meal", "Dose", "Meditation" |
| Implement local storage (SharedPreferences or Hive) | 15 min | Entries persist between sessions |
| Show today's log view | 15 min | Simple timeline of entries |
| Add streak counter | 5 min | Days in a row tracked |

**Hour 3 Demo**: Tap "Gym" → logged with timestamp → see today's entries.

---

### 🕓 HOUR 4: Mood & Mantras (The CBT Layer)
**Goal**: Capture mood and reinforce mantras

| Task | Time | Deliverable |
|------|------|-------------|
| Add mood quick-select (1-10 or emoji) | 10 min | Mood attached to entries |
| Create mantra storage system | 15 min | User can add/edit mantras |
| Display daily mantra on home | 10 min | Random mantra each day |
| Voice-read mantra option | 15 min | TTS reads mantra aloud |
| Add "How are you feeling?" prompt | 10 min | Morning check-in screen |

**Hour 4 Demo**: App greets with mantra, user logs mood, voice reads affirmation.

---

### 🕔 HOUR 5: Character Radar (The Gamification)
**Goal**: Visualize stats as RPG character

| Task | Time | Deliverable |
|------|------|-------------|
| Create `CharacterStats` model | 10 min | Strength, Intellect, Spirit, Sales |
| Build radar chart widget | 20 min | Visual polygon chart |
| Calculate stats from logged data | 15 min | Gym → Strength, Meditation → Spirit, etc. |
| Add XP/Level display | 10 min | Total XP from all activities |
| Animate stat changes | 5 min | Smooth transitions when stats update |

**Hour 5 Demo**: See character radar showing current stats, watch it update after logging gym.

---

### 🕕 HOUR 6: Polish & Integration (Ship It)
**Goal**: Make it feel real and connected

| Task | Time | Deliverable |
|------|------|-------------|
| Add focus mode timer | 15 min | Deep work tracking |
| Implement daily summary | 15 min | End-of-day review screen |
| Add protein/nutrition quick log | 10 min | "150g protein" voice entry |
| Settings screen with mantra editor | 10 min | Customize experience |
| Clean up UI/navigation | 10 min | Smooth flow between screens |

**Hour 6 Demo**: Complete daily flow from morning check-in to evening summary.

---

## Files to Rename/Modify

### Core Files
| Original | New |
|----------|-----|
| `pubspec.yaml` (name: PolyMobile) | `name: odelle_nyse` |
| `lib/main.dart` | Update app title to "Odelle Nyse" |
| `lib/constants/strings.dart` | Change all "Poly" to "ON" |
| `android/app/build.gradle` | applicationId: `com.poly186.odellenyse` |
| `ios/Runner/Info.plist` | CFBundleName: "Odelle Nyse" |

### Theme Updates
| File | Changes |
|------|---------|
| `lib/constants/theme_constants.dart` | Add ON color palette |
| `lib/constants/design_constants.dart` | Update brand colors |

### Screens to Repurpose
| Original | New Purpose |
|----------|-------------|
| `VoiceNoteScreen` | Main voice journal interface |
| `ModernHomeScreen` | Dashboard with Character Radar |
| `HomeScreen` | Voice chat (keep for AI interaction) |
| `StyleGuideScreen` | Keep for development reference |

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ODELLE NYSE v0.1                         │
├─────────────────────────────────────────────────────────────┤
│  SCREENS                                                    │
│  ├── DashboardScreen (Character Radar + Quick Actions)     │
│  ├── VoiceJournalScreen (Kitchen Confessional)             │
│  ├── ProtocolLogScreen (Daily Protocol Tracking)           │
│  ├── MantraScreen (CBT + Affirmations)                     │
│  └── SettingsScreen (Configuration)                        │
├─────────────────────────────────────────────────────────────┤
│  MODELS                                                     │
│  ├── JournalEntry (voice transcriptions)                   │
│  ├── ProtocolEntry (gym, meal, dose, meditation)           │
│  ├── CharacterStats (strength, intellect, spirit, sales)   │
│  ├── Mantra (user mantras + affirmations)                  │
│  └── DailyLog (aggregate of day's activities)              │
├─────────────────────────────────────────────────────────────┤
│  SERVICES                                                   │
│  ├── VoiceService (transcription via Poly backend)         │
│  ├── LocalStorageService (SharedPreferences/Hive)          │
│  ├── StatsCalculatorService (entries → character stats)    │
│  └── NotificationService (reminders, nudges)               │
├─────────────────────────────────────────────────────────────┤
│  PROVIDERS (State Management)                               │
│  ├── JournalProvider                                        │
│  ├── ProtocolProvider                                       │
│  └── CharacterProvider                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## New Models to Create

### JournalEntry
```dart
class JournalEntry {
  final String id;
  final DateTime timestamp;
  final String transcription;
  final double? mood;        // 1-10
  final List<String> tags;   // auto-detected or manual
  final String? sentiment;   // positive/negative/neutral
}
```

### ProtocolEntry
```dart
class ProtocolEntry {
  final String id;
  final DateTime timestamp;
  final ProtocolType type;   // gym, meal, dose, meditation, focus
  final Map<String, dynamic> data;  // type-specific data
  final String? notes;
}

enum ProtocolType { gym, meal, dose, meditation, focus, sleep }
```

### CharacterStats
```dart
class CharacterStats {
  final double strength;     // from gym entries
  final double intellect;    // from focus/work entries
  final double spirit;       // from meditation/mood entries
  final double sales;        // manual input for now
  final int level;
  final int totalXP;
}
```

---

## Color Palette (ON Brand)

Based on the VoiceNoteScreen gradient:

```dart
// Primary Gradient (Sunrise/Activation)
static const Color onOrange = Color(0xFFFF8C42);    // Energy
static const Color onPurple = Color(0xFF8200FF);    // Wisdom
static const Color onDarkPurple = Color(0xFF1A0524); // Depth

// Accent Colors
static const Color onMint = Color(0xFF00D9A5);      // Success/Health
static const Color onGold = Color(0xFFFFD700);      // Achievement
static const Color onWhite = Color(0xFFFFFFFF);     // Text

// Gradient
static const LinearGradient onGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [onOrange, onPurple, onDarkPurple],
  stops: [0.0, 0.4, 1.0],
);
```

---

## Stream Talking Points

### Why This Works (For Audience)
1. **Vibe Coding**: We're not starting from scratch - leveraging existing infrastructure
2. **The Trifecta**: Bio-chemical + CBT + Digital = Actual change
3. **Personal Stakes**: Not just a demo app - this is survival software
4. **Open Build**: Showing the real process, not polished tutorial

### Key Quotes to Reference
- "I want to recalibrate and update my source code"
- "It's Game of Thrones self improvement"
- "I don't wanna die like a fucking broke Nicola Tesla"

---

## Success Criteria

By end of stream, the app should:
- [x] Launch as "Odelle Nyse" with ON branding
- [x] Accept voice input and transcribe
- [x] Log protocol entries (gym, meal, etc.)
- [x] Display Character Radar with calculated stats
- [x] Show daily mantra
- [x] Persist data between sessions

---

## Current Status (v1.2.0 - January 2026)

### ✅ Completed
- **Voice Infrastructure**: Azure OpenAI Realtime API integration working
- **Transcription Mode**: Hold-to-talk captures voice, Whisper-1 transcribes
- **Data Models**: Comprehensive models defined in DATA_MODELS.md
- **Database**: SQLite with all core tables (journals, protocols, stats, etc.)
- **3-Pillar UI**: Body | Voice | Mind screens with swipe navigation
- **Riverpod State**: VoiceViewModel centralizes voice state management
- **Protocol Logging**: Manual tap logging for gym/meal/dose/meditation

### 🔧 v1.2.0 Changes
- Created `VoiceViewModel` for centralized voice state management
- VoiceScreen now uses VoiceViewModel (no local state duplication)
- HomeScreen uses VoiceViewModel for reactive voice button states
- Fixed debug overlay (disabled for production)
- Cleaner state flow: single source of truth for voice state

### 🚧 Next Priority (Voice Reliability)
1. **Audio Playback** - AI speaks back in conversation mode (just_audio integration)
2. **Mode Separation** - Center screen = Live Mode, Side screens = Transcription
3. **Conversation History** - Display AI responses in VoiceScreen
4. **Mode Confirmation** - Guard rails when switching modes

### 📋 Future Features
- **AI Parsing** - Extract structured data from voice transcriptions
- **Tools/Function Calling** - Agent can log protocols via voice
- **Health Integrations** - Apple Health, Google Fit sync
- **Push Notifications** - Protocol reminders

---

## Architecture (Current)

```
┌─────────────────────────────────────────────────────────────────────┐
│                     VOICE STATE FLOW (v1.2.0)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │              VoiceViewModel (Riverpod Notifier)             │     │
│  │  ┌──────────────────────────────────────────────────────┐  │     │
│  │  │  VoiceState:                                         │  │     │
│  │  │  - connectionState: disconnected|connecting|...       │  │     │
│  │  │  - activeMode: transcription|conversation             │  │     │
│  │  │  - currentTranscription: String                       │  │     │
│  │  │  - partialTranscription: String                       │  │     │
│  │  │  - isModeLocked: bool                                 │  │     │
│  │  └──────────────────────────────────────────────────────┘  │     │
│  └───────────────────────────┬────────────────────────────────┘     │
│                              │ watches                               │
│         ┌────────────────────┼────────────────────┐                 │
│         ▼                    ▼                    ▼                 │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐         │
│  │ BodyScreen  │      │ VoiceScreen │      │ MindScreen  │         │
│  │  (display)  │      │  (display)  │      │  (display)  │         │
│  └─────────────┘      └─────────────┘      └─────────────┘         │
│                                                                      │
│  HomeScreen: Controls mic stream, calls VoiceViewModel methods      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Post-Stream Tasks

1. **Clean up code** and remove unused Poly features
2. **Add push notifications** for protocol reminders
3. **Implement local LLM** for CBT prompts
4. **Build meditation playlist** integration
5. **Design proper ON logo/icon**
6. **Set up TestFlight** for ON app

---

*Let's build. Let's turn ON.*
