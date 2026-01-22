# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.9.0] - 2026-01-22

### Added
- **Consciousness Architecture**: New system prompt based on META Awareness framework, Optimal Bayesian Agent, and Hero's Cycle
- **Proactive Tool Use**: Agent now uses tools to THINK, REMEMBER, and ACT — not just respond
- **get_user_status Tool**: Query current financial status (bills, subscriptions, income) before giving advice
- **note_pattern Tool**: Record psychograph insights (habits, triggers, shadows, breakthroughs)
- **Expanded Trigger Detection**: Agent now activates on body/mind/spirit keywords, not just wealth
- **ODELLE_CONSCIOUSNESS_ARCHITECTURE.md**: Full documentation of the AI twin architecture
- **Co-emergence Framing**: "Beings in the Beginning" — user and AI transform together

### Changed
- **System Prompt Overhaul**: 10-part consciousness architecture replacing simple persona
- **Judo Psychology**: Match, pace, lead — work WITH user energy, not against
- **CBT Temporal Evolution**: Thought→behavior→identity reframe protocol
- **Hero's Cycle Tracking**: Stage-aware guidance posture (Ordeal vs Return)
- **Multi-modal Coherence**: Text/voice/image as unified experience
- **Tool Philosophy**: "Action > Discussion. Always."
- **maxIterations**: Increased from 3 to 5 for complex tool queries

### Documentation
- Renamed `Poly186 Protocol Draft 2 (1).md` → `Poly186_Protocol_Draft_2.md`
- Renamed `Chapter 3 Awaken Simplified.md` → `META_Awareness_Framework.md`

## [1.8.0] - 2026-01-22

### Added
- **Chat Message Streaming**: Real-time token-by-token display as AI generates responses
- **Thinking/Reasoning Tokens**: Visual indicator (🧠) showing AI's reasoning process when available
- **Chat Message Persistence**: Conversations saved to SQLite, persist across app restarts
- **Image Attachments in Chat**: Pick from camera or photo library, send to multimodal LLM
- **StreamEvent Types**: New streaming API in AzureAgentService with content, thinking, done, usage, error events
- **ChatMessageCrud Mixin**: Database operations for chat_conversations and chat_messages tables

### Changed
- **Chat Screen Design**: Matches FloatingHeroCard pattern with BreathingCard background and white bottom panel
- **No Hardcoded Token Limits**: Removed maxTokens constraint to show full LLM responses
- **Auto-scroll During Streaming**: Chat scrolls as new content arrives, not just on message count change

### Fixed
- **Race Condition**: Chat now waits for initialization before sending first message
- **Streaming Response Panel**: White panel shows streaming content with progress indicator

## [1.7.1] - 2026-01-14

### Added
- **Wealth & Bonds Pillars**: Integrated Wealth and Bonds ViewModels and screens for the 5-pillar architecture.
- **Provider Wiring**: Wired up Wealth and Bonds providers for dynamic data display.

## [1.3.0] - 2026-01-11

### Added
- **Bi-directional Voice Conversation**: Full voice conversation with Azure OpenAI Realtime API
- **AudioOutputService**: Singleton service for playing PCM16 audio responses from AI
- **macOS Microphone Support**: Added entitlements and platform checks for desktop microphone access
- **Auto-recording on Connect**: Voice recording starts automatically when connection is established

### Fixed
- macOS permission_handler MissingPluginException - bypassed with Platform checks
- Race condition in _startRecording - added forceStart parameter for callback timing
- flutter_pcm_sound API compatibility for macOS native audio playback

## [1.1.0] - 2026-01-10

### Added
- **Phase 1 Data Models**: UserProfile, Supplement, DoseLog, Habit, HabitLog, MoodEntry, Streak
- **Phase 2 Content Models**: ContentCategory, Instructor, Session, Program, PlayHistory, Favorite
- **Phase 3 Tracking Models**: WorkoutLog, ExerciseType, ExerciseSet, PersonalRecord, MealLog, MeditationLog, SleepLog
- **Phase 4 Gamification Models**: Achievement, UserAchievement, DailyLog, ProgressSnapshot
- **Phase 5 Scheduling Models**: DoseSchedule, ScheduledEvent, ProgramEnrollment, LessonProgress
- **Repositories**: UserProfileRepository, DoseRepository, HabitRepository, MoodRepository, StreakRepository
- **ViewModels**: Riverpod Notifiers for all repositories with proper state management
- **Database Schema**: SQLite tables for Phase 1 and Phase 2 with indexes and CRUD operations
- **Analytics Models**: WeeklyProgress, MoodTrend, CalendarDay computed models

### Fixed
- Type casting errors in MoodTrend computation (num to double)
- Deprecated API usage (withOpacity, scale, ConcatenatingAudioSource)
- Print statements replaced with Logger calls
- Widget child argument ordering

## [1.0.0] - 2026-01-10

### Added
- **iOS CI/CD Pipeline**: Automated build and TestFlight deployment via GitHub Actions
- **Code Signing**: Proper provisioning profile and certificate configuration
- **iPad Orientation Support**: Full orientation support for iPad App Store requirements
- **BreathingCard Widget**: Animated card component with pulsing gradient effects
- **Pillar Navigation**: Custom bottom navigation with Body, Mind, Soul pillars
- **Voice Integration**: LiveKit WebRTC integration for real-time voice communication
- **Authentication**: Google Sign-In and Facebook Login integration
- **Draggable Bottom Panel**: Interactive panel with pulse animation
- **Stats Cards**: Centered alignment with consistent design system

### Changed
- Updated bundle ID to `com.poly186.odelle`
- Configured manual code signing for distribution
- ExportOptions.plist updated with hardcoded team and bundle ID values
- Set `UIRequiresFullScreen=true` for portrait-only experience

### Fixed
- iOS signing certificate and provisioning profile mismatch
- Build configuration for Release and Profile schemes
- **iPad multitasking validation error**: Added all 4 orientations for `UISupportedInterfaceOrientations~ipad`

## [0.1.1] - 2026-01-09

### Added
- Draggable bottom panel pulse animation
- Mind screen bottom panel aligned to body screen layout

### Changed
- Centered stats cards for improved alignment

## [0.1.0] - 2026-01-08

### Added
- Initial project setup
- Flutter SDK configuration
- Core dependencies (flutter_bloc, provider, etc.)
- Basic screen structure (Body, Mind, Soul)

