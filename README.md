# Odelle Nyse (ON) 
## Self-Actualization Operating System

> *"I want to recalibrate and update my source code. I wanna update my system prompt."*

---

## The Pitch

**5 seconds**: "An app that helps me rewire my brain to think less and live more."

**10 seconds**: "I'm using microdosing to weaken my brain's 'cortico-cortical recurrent loops'—the thinking-about-thinking patterns—and an AI to help me stay present."

**30 seconds**: "Research just proved that psilocybin weakens *cortico-cortical recurrent loops*—the brain's feedback circuits responsible for rumination and the Default Mode Network. I'm building an app that combines microdosing with CBT and voice AI to leverage that plasticity window. The goal? Quiet the mental chatter, raise my conscious awareness, and actually be present. It's not just self-improvement—it's source code updates for my brain."

---

**Odelle Nyse** (pronounced "Oh-DELL NYE-see") is a voice-first AI assistant designed to help you become the best version of yourself. The name spells **ON** — because we're turning you ON.

---

## 🎯 What is this?

A mobile app designed to test a core hypothesis: **Can microdosing psilocybin help reduce cortico-cortical feedback loops (the "thinking about thinking" patterns of the Default Mode Network) and increase present-moment awareness?**

### The Trifecta Protocol

- **🧬 Bio-Chemical Priming**: Track microdosing protocol to open neuroplasticity windows
- **🧠 CBT & Mantras**: Cognitive reframing during peak plasticity to rewire thought patterns  
- **🤖 AI Companion**: Voice-first journaling and accountability to maintain consistency

### The Science

Based on the landmark [Jiang et al. (2025)](https://doi.org/10.1016/j.cell.2025.11.009) study published in *Cell*, which discovered that psilocybin:
- **Weakens** cortico-cortical recurrent loops (the biological signature of the Default Mode Network)
- **Strengthens** inputs from perceptual/sensory regions
- Rewires the brain in an **activity-dependent** manner (what you do during administration shapes the rewiring)

Full details in the [Odelle Nyse Whitepaper](docs/WHITEPAPER.md).

> ⚠️ **Disclaimer**: This is a personal self-improvement experiment, not medical advice. Psilocybin is a controlled substance in most jurisdictions. Consult healthcare professionals and understand local laws before making any decisions.

---

## 🏗 Tech Stack

- **Flutter** - Cross-platform mobile (iOS/Android)
- **Poly Backend** - Voice transcription & synthesis
- **Local Storage** - Private data sovereignty (your data stays yours)
- **Provider + BLoC** - State management

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.0+
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/Poly186-AI-DAO/odelle-nyse-app.git
   cd odelle-nyse-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

4. **Run the app**
   ```bash
   # iOS Simulator
   flutter run -d ios
   
   # Android Emulator
   flutter run -d android
   ```

---

## 📱 Features

### Voice Journal (The "Kitchen Confessional")
Capture thoughts via voice while your hands are busy. Say "Note to self" and your thoughts are transcribed and saved.

### Protocol Logging
Quick-tap buttons to log:
- 💪 Gym sessions
- 🥗 Meals & nutrition
- 💊 Microdose tracking
- 🧘 Meditation minutes
- 🎯 Deep work sessions

### Character Radar
Visualize your growth as an RPG character:
- **Strength** - from gym consistency
- **Intellect** - from focus/deep work
- **Spirit** - from meditation/mood
- **Sales** - from outreach activities

### Daily Mantras
- Paste your own mantras
- AI reads them aloud during peak plasticity
- CBT reframing prompts

---

## 📂 Project Structure

```
lib/
├── constants/          # Theme, strings, routes
├── models/             # Data models
│   ├── journal_entry.dart
│   ├── protocol_entry.dart
│   └── character_stats.dart
├── providers/          # State management
├── screens/            # UI screens
│   ├── dashboard_screen.dart
│   ├── voice_journal_screen.dart
│   └── protocol_log_screen.dart
├── services/           # API & local services
└── widgets/            # Reusable components
```

---

## 🎨 Brand Colors

```dart
// The ON Gradient (Sunrise/Activation)
onOrange: #FF8C42      // Energy
onPurple: #8200FF      // Wisdom  
onDarkPurple: #1A0524  // Depth
```

---

## 📖 Documentation

- [Whitepaper](docs/WHITEPAPER.md) - The full vision and science
- [Build Plan](docs/BUILD_PLAN.md) - Hour-by-hour development guide

---

## 🧾 Attribution

- Body icon - source pending for `assets/icons/body_gym_icon.png`
- Mind icon - source pending for `assets/icons/mind_meditate_icon.png`

---

## 🔗 Part of Poly186 Ecosystem

Odelle Nyse is a vertical within the [Poly186](https://poly186.ai) ecosystem, focused on individual self-actualization as the foundation for global improvement.

> *"For global world improvement, there must first improve the self."*

---

## 📄 License

Private - Poly186 AI DAO

---

*Let's turn ON.* 🔥
