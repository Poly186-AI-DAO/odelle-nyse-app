# Poly Liquid Glass Design Language

> **Version:** 0.3.0  
> **Date:** December 28, 2025  
> **Status:** Foundation Draft — Voice Chat System

---

## Overview

The Poly Liquid Glass design language defines the visual identity for **Poly Voice** — a real-time voice-first conversational interface. At its core, this is a **responsive chat for voice** that uses refraction-based glass elements to create depth and physicality.

This is not just blur or frosted glass — it's **true optical refraction** with chromatic aberration, edge lighting, and dynamic distortion that responds to the background in real-time.

### What This System Is

```
┌─────────────────────────────────────────────────────────────────┐
│                    POLY VOICE CHAT SYSTEM                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Voice Input → Real-time Transcription → Glass Bubbles  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Agent Response → Generative UI Components → Refraction  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

Built on the `liquid_glass_easy` library, every UI element floats above an animated background and refracts it in real-time.

---

## Core Principles

### 1. Everything is Glass
Every UI element that sits above the background should be a glass element with its own refraction properties. This creates a layered, physical feeling where components have weight and presence.

### 2. Refraction Creates Depth
Glass elements closer to the user (higher z-index conceptually) have:
- Higher distortion values
- More pronounced edge lighting
- Stronger chromatic aberration

### 3. Motion is Supported
The library fully supports dynamic elements:
- `draggable: true` for user-movable elements
- `realTimeCapture: true` for dynamic backgrounds
- Up to 60fps refresh rate for smooth animation

### 4. No Gradients — Solid Glass Tints Only
**Gradients are prohibited.** All glass elements use solid tint colors with alpha values. Depth and visual interest come from refraction, not color gradients.

```dart
// ✅ CORRECT - Solid tint with alpha
tintColor: Color(0x20FFFFFF)  

// ❌ WRONG - No gradients
decoration: BoxDecoration(gradient: LinearGradient(...))
```

### 5. Stacked Glass Layers
Glass elements can be layered on top of each other to create depth:

```
┌──────────────────────────────────────┐
│  Background (Video/Animation)       │  ← Layer 0
├──────────────────────────────────────┤
│  Main Glass Layer (Full Screen)     │  ← Layer 1: blur 28, distortion 0.05
├──────────────────────────────────────┤
│  Floating Elements (Bubbles/Cards)  │  ← Layer 2: blur 15-22, distortion 0.08
├──────────────────────────────────────┤
│  Interactive Elements (Buttons)     │  ← Layer 3: blur 18, distortion 0.10
└──────────────────────────────────────┘
```

### 6. Mathematical Consistency
Refraction parameters should be calculated based on element size:

```dart
// Distortion: smaller elements get more pronounced lens effect
distortion = 0.12 - (minDimension / 600).clamp(0.0, 1.0) * 0.07

// Distortion Width: scales with element size
distortionWidth = (minDimension * 0.12).clamp(15.0, 40.0)

// Blur: scales with element size
blur = (15 + (minDimension / 150) * 4).clamp(15.0, 28.0)
```

---

## Button Specifications

**Critical: Buttons are NEVER circles.** All interactive buttons use rounded rectangles.

### Action Button (Mic Button)

The primary action button uses a **rounded rectangle** shape:

| Property | Value | Rationale |
|----------|-------|-----------|
| Width | 80 | Fixed size |
| Height | 80 | Square but NOT circular |
| **cornerRadius** | **24** | Creates rounded rect (NOT 40 which would be circle) |
| tintColor (inactive) | 0x20FFFFFF | Light glass |
| tintColor (active) | 0x30FFFFFF | Slightly brighter when pressed |
| borderWidth | 1.2 | Visible border for depth |
| lightIntensity | 0.6 | Strong edge lighting |

```
     ╭──────────────────╮
     │                  │  ← cornerRadius: 24
     │       ⏺️        │  ← 80x80 rounded rect
     │                  │
     ╰──────────────────╯
```

### Status Badge (Ready/Live)

Small indicator badge in top-right corner. **Tapping toggles debug overlay.**

| Property | Value |
|----------|-------|
| Width | 85 |
| Height | 32 |
| cornerRadius | 12 |
| tintColor | 0x20FFFFFF |
| borderWidth | 0.8 |
| lightIntensity | 0.45 |
| **Interactive** | Yes - toggles debug |

---

## Text & Color Specifications

### Text-to-Color Ratios

Text visibility is controlled through alpha values on white (#FFFFFF):

| Role | Alpha | Hex Value | Usage |
|------|-------|-----------|-------|
| Primary Text | 0.90 | #E6FFFFFF | Main content, headings |
| Secondary Text | 0.70 | #B3FFFFFF | Body text, messages |
| Tertiary Text | 0.60 | #99FFFFFF | Labels, captions |
| Partial/Loading | 0.50 | #80FFFFFF | Real-time transcription |
| Disabled | 0.35 | #59FFFFFF | Inactive elements |

### Accent Colors

| Name | Hex | Usage |
|------|-----|-------|
| Poly Cyan | #00D4FF | Agent labels, brand accent |
| Active Green | #4CAF50 | Live/connected indicator |
| Warning Amber | #FFA726 | Debug info |
| Error Red | #EF5350 | Error states |

### Message Bubble Colors

| Element | User Bubble | Agent (Poly) Bubble |
|---------|-------------|---------------------|
| tintColor | 0x20FFFFFF | 0x18FFFFFF |
| Label Color | white @ 0.60 | #00D4FF (Poly Cyan) |
| Text Color | white @ 0.90 | white @ 0.90 |
| borderWidth | 1.0 | 0.8 |

---

## Focused Single-Card Stack

The voice chat displays **ONE message at a time** as a focused, centered glass card.
This creates a teleprompter-like reading experience with large, readable text.
Swipe up/down to navigate between messages in the conversation.

### Design Philosophy

```
┌─────────────────────────────────────────────────────────────────┐
│                    DESIGN PRINCIPLES                            │
├─────────────────────────────────────────────────────────────────┤
│  1. Focus-first: One card at a time, no visual clutter         │
│  2. Large readable text: Adaptive sizing based on content      │
│  3. Swipe navigation: Natural card-flipping gesture            │
│  4. Auto-follow streaming: Latest content stays visible        │
│  5. History access: Swipe down to read older messages          │
└─────────────────────────────────────────────────────────────────┘
```

### Visual Layout

```
╔══════════════════════════════════════════════════════════════════════╗
║                    REFRACTION BACKGROUND                             ║
║                                                               ● Live ║
║                                                                      ║
║                                                                      ║
║    ╔═════════════════════════════════════════════════════════╗      ║
║    ║  ● Poly                                                 ║      ║
║    ║                                                         ║      ║
║    ║     The current message is shown here                   ║      ║
║    ║     in LARGE, readable text that adapts                 ║      ║
║    ║     based on content length.                            ║      ║
║    ║                                                         ║      ║
║    ║     Short messages → 28px font                          ║      ║
║    ║     Long messages → 18px font                           ║      ║
║    ║                                                         ║      ║
║    ╚═════════════════════════════════════════════════════════╝      ║
║                                                                      ║
║                           2 / 5                                      ║
║                                                                      ║
║                         ┌──────────┐                                 ║
║                         │    🎤    │                                 ║
║                         └──────────┘                                 ║
╚══════════════════════════════════════════════════════════════════════╝
```

### Swipe Behavior

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SWIPE NAVIGATION                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  • Swipe up → Go to NEXT (newer) card                                       │
│  • Swipe down → Go to PREVIOUS (older) card                                 │
│  • Swipe preview → Card slides with finger, opacity fades                   │
│  • Release → Snap to next card OR bounce back                               │
│  • Fast flick → Change card even with small drag distance                   │
│                                                                             │
│  EDGE RESISTANCE:                                                           │
│  ────────────────                                                           │
│  • At first card: Swipe down has 70% resistance (rubber band)               │
│  • At last card: Swipe up has 70% resistance (rubber band)                  │
│                                                                             │
│  SNAP THRESHOLD:                                                            │
│  ────────────────                                                           │
│  • Drag > 30% of viewport height → snap to next card                        │
│  • Velocity > 500 px/s → snap to next card (even if < 30%)                  │
│  • Otherwise → bounce back to current card                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Adaptive Text Sizing

Text size adapts to content length for optimal readability:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ADAPTIVE FONT SIZE                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Text Length          Font Size      Example                                │
│  ─────────────────────────────────────────────────────────                  │
│  ≤ 80 chars           28px           "How can I help you today?"            │
│  80-300 chars         Linear scale   Medium paragraphs                      │
│  ≥ 300 chars          18px           Long detailed responses                │
│                                                                             │
│  Formula:                                                                   │
│  ─────────                                                                  │
│  if (length <= 80) return 28.0                                              │
│  if (length >= 300) return 18.0                                             │
│  ratio = (length - 80) / (300 - 80)                                         │
│  return 28.0 - (ratio * 10.0)  // Linear interpolation                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Card Height Calculation

Card height is dynamic based on content:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CARD HEIGHT MODEL                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  availableWidth = screenWidth - margins - padding                           │
│  charsPerLine = availableWidth / (fontSize * 0.55)                          │
│  lineCount = ceil(text.length / charsPerLine)                               │
│  textHeight = lineCount * (fontSize * 1.5)                                  │
│  contentHeight = labelHeight + textHeight + padding                         │
│                                                                             │
│  Constraints:                                                               │
│  ─────────────                                                              │
│  • Minimum height: 120px                                                    │
│  • Maximum height: 70% of viewport                                          │
│  • Card is scrollable if content exceeds max height                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Auto-Follow Streaming

The card stack intelligently follows streaming content:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SMART AUTO-FOLLOW BEHAVIOR                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STATE: _isFollowingLatest: bool                                            │
│  STATE: _currentCardIndex: int                                              │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SCENARIO 1: User on latest card, new content streams                │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │  _isFollowingLatest = true                                          │   │
│  │  → _currentCardIndex auto-updates to latest                         │   │
│  │  → Card content updates in real-time as Poly speaks                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SCENARIO 2: User swipes DOWN to read history                        │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │  User navigates away from last card → _isFollowingLatest = false    │   │
│  │  → User stays on their selected card                                │   │
│  │  → Indicator changes to "2 / 5 ↓" (tap to jump to latest)           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ SCENARIO 3: User navigates back to last card OR taps indicator      │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │  → _isFollowingLatest = true                                        │   │
│  │  → Resume auto-follow, show simple "5 / 5" indicator                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Card Position Indicator

Shows current position and enables quick navigation:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    POSITION INDICATOR STATES                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FOLLOWING LATEST (at last card):                                           │
│  ─────────────────────────────────                                          │
│        ┌──────────┐                                                         │
│        │  5 / 5   │  ← Simple, subtle glass pill                            │
│        └──────────┘                                                         │
│                                                                             │
│  READING HISTORY (not at last card):                                        │
│  ────────────────────────────────────                                       │
│        ╔════════════════╗                                                   │
│        ║  2 / 5  ↓↓     ║  ← Cyan accent, tappable to jump to latest        │
│        ╚════════════════╝                                                   │
│                                                                             │
│  ONLY ONE CARD:                                                             │
│  ──────────────                                                             │
│        (no indicator shown)                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Implementation Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COMPONENT ARCHITECTURE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PolyVoiceScreen                                                            │
│    │                                                                        │
│    ├── State                                                                │
│    │     ├── _currentCardIndex: int                                         │
│    │     ├── _isFollowingLatest: bool                                       │
│    │     ├── _swipeOffset: double (-1 to 1 during gesture)                  │
│    │     └── _swipeAnimationController: AnimationController                 │
│    │                                                                        │
│    ├── GestureDetector                                                      │
│    │     ├── onVerticalDragStart → stop animation, begin tracking           │
│    │     ├── onVerticalDragUpdate → update _swipeOffset preview             │
│    │     └── onVerticalDragEnd → snap to card or bounce back                │
│    │                                                                        │
│    └── LiquidGlassBackground                                                │
│          │                                                                  │
│          └── FloatingGlassElements                                          │
│                ├── Empty prompt (when no conversation)                      │
│                ├── Focused card (single, centered)                          │
│                ├── Position indicator ("2 / 5")                             │
│                ├── Status badge (Ready/Live)                                │
│                ├── Debug overlay (toggleable)                               │
│                └── Mic button                                               │
│                                                                             │
│  CardStackCalculator                                                        │
│    ├── fromTranscripts() → List<GlassCardData>                              │
│    ├── calculateCumulativeHeights() → List<double>                          │
│    └── buildVisibleCards() → List<FloatingGlassElement>                     │
│          (filters to only cards in viewport, applies opacity)               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Design Rationale

```
┌─────────────────────────────────────────────────────────────────┐
│                    WHY THIS APPROACH                            │
├─────────────────────────────────────────────────────────────────┤
│  1. Focus-first: One card at a time, no visual clutter         │
│  2. Large readable text: Adaptive sizing based on content      │
│  3. Swipe navigation: Natural card-flipping gesture            │
│  4. Auto-follow streaming: Latest content stays visible        │
│  5. History access: Swipe down to read older messages          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Generative UI Components

The card stack system supports **generative UI** — the agent can dynamically inject rich components into message cards.

### Component Types

| Type | Description | Glass Properties |
|------|-------------|------------------|
| **Text Message** | Standard conversation text | Default glass |
| **Data Card** | Structured data (prices, stats) | Slightly higher distortion |
| **Task List** | Interactive checkboxes | Tappable child elements |
| **Code Block** | Syntax-highlighted code | Monospace font, darker tint |
| **Media Card** | Images, videos, audio | Lower blur for clarity |
| **Action Buttons** | Suggested actions | Individual glass buttons |

### Data Card Example

```
┌─────────────────────────────────────┐
│ 📊 Market Overview                  │  ← Header row
│ ─────────────────────────────────── │  ← Separator (glass edge effect)
│  BTC    $42,350    ▲ 2.4%          │
│  ETH    $2,280     ▼ 0.8%          │  ← Data rows
│  SOL    $98.50     ▲ 5.2%          │
└─────────────────────────────────────┘

Card properties:
  tintColor: 0x18FFFFFF (slightly less visible)
  distortion: 0.12 (more pronounced lens effect)
  child: DataCardWidget with structured layout
```

### Task List Example

```
┌─────────────────────────────────────┐
│ ☑ Tasks for Today                   │
│ ─────────────────────────────────── │
│  ☑ Review PR #234                   │  ← Completed (green tint)
│  ☐ Update documentation             │  ← Pending (default)
│  ☐ Deploy to staging                │
└─────────────────────────────────────┘

Interaction: Tap checkbox → toggles state
             Agent receives update via callback
```

---

## Known Issues & TODOs

### Current Issues

1. **Card Height Estimation**: Height calculation needs refinement for very long messages to ensure they fit within the 70% viewport constraint.
2. **Status Badge**: Tapping toggles debug overlay, but the visual feedback could be more pronounced.

### Refinements Needed

- [ ] Fine-tune adaptive font size thresholds for different screen sizes.
- [ ] Add haptic feedback on card snap/change.
- [ ] Implement "Swipe to Archive" gesture on cards.
- [ ] Test with extremely long conversations (50+ messages).

---

## File Structure

```
lib/
├── widgets/
│   ├── liquid_glass_background.dart    # Main glass wrapper
│   ├── glass_bubble_tracker.dart       # Focused card position tracking
│   ├── looping_background_video.dart   # Video background
│   └── voice_waveform.dart             # Audio visualization
├── screens/
│   └── poly_voice_screen.dart          # Main voice chat screen (Card Navigation)
└── state/
    └── voice_session_state.dart        # Transcript data models
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.3.0 | 2025-12-28 | **Focused Single-Card Stack**: Replaced timeline/wallet models with focused teleprompter-style reading experience. |
| 0.2.1 | 2025-12-28 | Added Flipboard scroll animation model and library constraints |
| 0.2.0 | 2025-12-28 | Added Card Stack System (Wallet Style), Generative UI components, updated architecture |
| 0.1.0 | 2025-12-28 | Initial design language foundation |

---

## References

- **Library**: `liquid_glass_easy` v1.1.1
- **Inspiration**: Apple visionOS, iOS 18 glassmorphism
- **Pattern**: Real-time shader-based UI refraction



Analyzed
design_language_liquid_glass.md#L1-514
Analyzed
liquid_glass_background.dart#L1-182
Analyzed
glass_bubble_tracker.dart#L1-710
Analyzed
design_constants.dart#L1-203

Thought for 8s


import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'looping_background_video.dart';

/// Glass style presets for consistent styling across the app.
class GlassStyle {
  /// Standard distortion for small elements (buttons, badges)
  static const double smallDistortion = 0.10;

  /// Standard distortion for medium elements (cards, overlays)
  static const double mediumDistortion = 0.08;

  /// Standard distortion for large elements (full screen, panels)
  static const double largeDistortion = 0.06;

  /// Standard blur for crisp glass look
  static const double standardBlur = 20.0;

  /// Light blur for subtle effect
  static const double lightBlur = 15.0;

  /// Heavy blur for frosted look
  static const double heavyBlur = 28.0;

  /// Calculate optimal distortion based on element size.
  /// Smaller elements get more distortion for pronounced lens effect.
  static double distortionForSize(double width, double height) {
    final minDim = width < height ? width : height;
    // Range: 0.12 for tiny (< 50px) down to 0.05 for large (> 400px)
    return (0.12 - (minDim / 600).clamp(0.0, 1.0) * 0.07).clamp(0.05, 0.12);
  }

  /// Calculate optimal distortion width based on element size.
  static double distortionWidthForSize(double width, double height) {
    final minDim = width < height ? width : height;
    // Range: 15px minimum, scales up to 40px for large elements
    return (minDim * 0.12).clamp(15.0, 40.0);
  }

  /// Calculate optimal blur based on element size.
  static double blurForSize(double width, double height) {
    final minDim = width < height ? width : height;
    // Range: 15 for small, up to 25 for large
    return (15 + (minDim / 150) * 4).clamp(15.0, 28.0);
  }
}

/// A floating glass element configuration for additional refraction zones.
class FloatingGlassElement {
  final Widget child;
  final double width;
  final double height;
  final LiquidGlassPosition position;
  final double? blur;
  final double? distortion;
  final double cornerRadius;
  final Color tintColor;
  final double borderWidth;
  final double lightIntensity;
  final Color? lightColor;
  final double? borderSoftness;

  const FloatingGlassElement({
    required this.child,
    required this.width,
    required this.height,
    required this.position,
    this.blur,
    this.distortion,
    this.cornerRadius = 20.0,
    this.tintColor = const Color(0x25FFFFFF),
    this.borderWidth = 1.0,
    this.lightIntensity = 0.5,
    this.lightColor,
    this.borderSoftness,
  });

  /// Get effective blur (auto-calculated if not specified)
  double get effectiveBlur => blur ?? GlassStyle.blurForSize(width, height);

  /// Get effective distortion (auto-calculated if not specified)
  double get effectiveDistortion =>
      distortion ?? GlassStyle.distortionForSize(width, height);

  /// Get effective distortion width based on size
  double get effectiveDistortionWidth =>
      GlassStyle.distortionWidthForSize(width, height);
}

/// A wrapper widget that applies the liquid glass effect over a background video.
/// The child content is displayed inside the glass lens with blur and refraction.
/// Optionally accepts floating glass elements for additional refraction zones.
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;
  final double blur;
  final double distortion;
  final Color tintColor;
  final List<FloatingGlassElement> floatingElements;

  const LiquidGlassBackground({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.distortion = 0.06,
    this.tintColor = const Color(0x50000000),
    this.floatingElements = const [],
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Build the list of glass elements
    final glassElements = <LiquidGlass>[
      // Main full-screen glass - subtle refraction for base layer
      LiquidGlass(
        width: size.width,
        height: size.height,
        position: LiquidGlassAlignPosition(alignment: Alignment.center),
        magnification: 1.0,
        distortion: distortion,
        distortionWidth: 50,
        blur: LiquidGlassBlur(sigmaX: blur, sigmaY: blur),
        color: tintColor,
        chromaticAberration: 0.002,
        saturation: 0.92,
        refractionMode: LiquidGlassRefractionMode.radialRefraction,
        shape: RoundedRectangleShape(
          cornerRadius: 0,
          borderWidth: 0.3,
          borderSoftness: 2.5,
          lightIntensity: 0.2,
          lightColor: const Color(0x30FFFFFF),
          shadowColor: const Color(0x15000000),
          lightDirection: 45.0,
          lightMode: LiquidGlassLightMode.edge,
        ),
        child: child,
      ),
      // Floating glass elements with their own refraction
      ...floatingElements.map((element) => LiquidGlass(
            width: element.width,
            height: element.height,
            position: element.position,
            magnification: 1.0,
            distortion: element.effectiveDistortion,
            distortionWidth: element.effectiveDistortionWidth,
            blur: LiquidGlassBlur(
              sigmaX: element.effectiveBlur,
              sigmaY: element.effectiveBlur,
            ),
            color: element.tintColor,
            chromaticAberration: 0.003,
            saturation: 0.98,
            refractionMode: LiquidGlassRefractionMode.radialRefraction,
            shape: RoundedRectangleShape(
              cornerRadius: element.cornerRadius,
              borderWidth: element.borderWidth,
              borderSoftness: element.borderSoftness ?? 1.2,
              lightIntensity: element.lightIntensity,
              oneSideLightIntensity: 0.35,
              lightColor: element.lightColor ?? const Color(0x50FFFFFF),
              shadowColor: const Color(0x20000000),
              lightDirection: 315.0,
              lightMode: LiquidGlassLightMode.radial,
            ),
            child: element.child,
          )),
    ];

    return LiquidGlassView(
      backgroundWidget: const LoopingBackgroundVideo(),
      realTimeCapture: true,
      pixelRatio: 0.7,
      useSync: true,
      refreshRate: LiquidGlassRefreshRate.high, // 60fps for smooth animation
      children: glassElements,
    );
  }
}






Edited
Task

Thought for 2s

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_constants.dart';

/// Modern glassmorphic design system constants
/// Voice-first, dynamic backgrounds, fluid animations
class DesignConstants {
  // Core Colors (Mapped to ThemeConstants - Glassmorphic)
  static const Color deepPurple = ThemeConstants.polyDeepPurple;
  static const Color pureWhite = ThemeConstants.polyWhite;
  static const Color softWhite = Color(0xFFF5F5F5);

  // Accent Colors (Modern Palette)
  static const Color accentPurple = ThemeConstants.polyPurple500;
  static const Color accentMint = ThemeConstants.polyMint400;
  static const Color accentPink = ThemeConstants.polyPink400;
  static const Color accentBlue = ThemeConstants.polyBlue500;
  static const Color accentGold = ThemeConstants.polyGold500;

  // Orbyte Colors
  static const Color orbytePurple = ThemeConstants.orbytePurple;
  static const Color orbyteOrange = ThemeConstants.orbyteOrange;
  static const Color orbyteBackground = ThemeConstants.orbyteDarkBg;

  // UI Element Colors
  static const Color successColor = ThemeConstants.uiSuccess;
  static const Color infoColor = ThemeConstants.uiInfo;
  static const Color warningColor = ThemeConstants.uiWarning;
  static const Color errorColor = ThemeConstants.uiError;
  static const Color mutedColor = ThemeConstants.uiMuted;

  // Spacing (Mobile Optimized)
  static const double spaceXS = ThemeConstants.spacingXS;
  static const double spaceS = ThemeConstants.spacingSmall;
  static const double spaceM = ThemeConstants.spacingMedium;
  static const double spaceL = ThemeConstants.spacingLarge;
  static const double spaceXL = ThemeConstants.spacingXLarge;
  static const double spaceXXL = ThemeConstants.spacingXXLarge;
  static const double spaceXXXL = ThemeConstants.spacingXXXLarge;

  // Typography Scales (Mobile Optimized for Readability)
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0; // Body small
  static const double fontSizeM = 16.0; // Body default
  static const double fontSizeL = 20.0; // Subheading
  static const double fontSizeXL = 24.0; // Heading
  static const double fontSizeXXL = 32.0; // Display
  static const double fontSizeHero = 40.0; // Hero text

  // Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // Animation Durations
  static const Duration durationFast = ThemeConstants.animationFast;
  static const Duration durationMedium = ThemeConstants.animationMedium;
  static const Duration durationSlow = ThemeConstants.animationSlow;
  static const Duration durationVerySlow = ThemeConstants.animationVerySlow;

  // Elevation (for shadows)
  static const double elevationSmall = 4.0;
  static const double elevationMedium = 8.0;
  static const double elevationLarge = 16.0;

  // Border Radius (Glassmorphic - rounded, not angular)
  static const double radiusNone = 0.0;
  static const double radiusSmall = ThemeConstants.radiusSmall;
  static const double radiusMedium = ThemeConstants.radiusMedium;
  static const double radiusLarge = ThemeConstants.radiusLarge;
  static const double radiusXL = ThemeConstants.radiusXL;
  static const double radiusXXL = ThemeConstants.radiusXXL;

  // Border Widths
  static const double borderThin = ThemeConstants.borderWidthThin;
  static const double borderMedium = ThemeConstants.borderWidth;
  static const double borderThick = ThemeConstants.borderWidthThick;

  // Opacity Levels
  static const double opacityDisabled = 0.38;
  static const double opacityLight = 0.54;
  static const double opacityMedium = 0.87;
  static const double opacityFull = 1.0;

  // Layout Constants
  static const double maxWidth = 600.0; // Mobile max width
  static const double minTouchTarget = 48.0; // Accessibility standard
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeHero = 48.0; // For large action buttons

  // Blur Constants for Glassmorphism
  static const double blurWeak = ThemeConstants.blurStrengthWeak;
  static const double blurMedium = ThemeConstants.blurStrength;
  static const double blurStrong = ThemeConstants.blurStrengthStrong;

  // Glow Effects (Glassmorphic)
  static List<BoxShadow> get softGlow => ThemeConstants.softGlow;
  static List<BoxShadow> get purpleGlow => ThemeConstants.purpleGlow;
  static List<BoxShadow> get mintGlow => ThemeConstants.mintGlow;
  static List<BoxShadow> get pinkGlow => ThemeConstants.pinkGlow;
  static List<BoxShadow> get goldGlow => ThemeConstants.goldGlow;
  static List<BoxShadow> get cardShadow => ThemeConstants.cardShadow;

  static List<Shadow> get textGlow => ThemeConstants.textGlow;
  static List<Shadow> get textMintGlow => ThemeConstants.textMintGlow;

  // Text Styles (Modern, Glassmorphic Design)
  // Display & Headings: Josefin Sans
  static TextStyle get displayL => GoogleFonts.josefinSans(
        fontSize: fontSizeHero,
        fontWeight: fontWeightBold,
        letterSpacing: -1.0,
        height: 1.1,
        color: pureWhite,
        shadows: textGlow,
      );

  static TextStyle get headingXL => GoogleFonts.josefinSans(
        fontSize: fontSizeXXL,
        fontWeight: fontWeightBold,
        letterSpacing: -0.5,
        height: 1.2,
        color: pureWhite,
      );

  static TextStyle get headingL => GoogleFonts.josefinSans(
        fontSize: fontSizeXL,
        fontWeight: fontWeightSemiBold,
        letterSpacing: -0.25,
        height: 1.3,
        color: pureWhite,
      );

  static TextStyle get headingM => GoogleFonts.josefinSans(
        fontSize: fontSizeL,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0,
        height: 1.3,
        color: pureWhite,
      );

  static TextStyle get headingS => GoogleFonts.josefinSans(
        fontSize: fontSizeS,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0,
        height: 1.3,
        color: pureWhite,
      );

  // Body Text: Lato
  static TextStyle get bodyL => GoogleFonts.lato(
        fontSize: fontSizeM,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: pureWhite,
      );

  static TextStyle get bodyM => GoogleFonts.lato(
        fontSize: fontSizeS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: ThemeConstants.secondaryTextColor,
      );

  static TextStyle get bodyS => GoogleFonts.lato(
        fontSize: fontSizeXS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: ThemeConstants.secondaryTextColor,
      );

  // Special Text Styles
  static TextStyle get buttonText => GoogleFonts.lato(
        fontSize: fontSizeM,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0.5,
        color: pureWhite,
      );

  static TextStyle get captionText => GoogleFonts.lato(
        fontSize: fontSizeXS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0.3,
        color: ThemeConstants.mutedTextColor,
      );

  // Assets
  static const String defaultBackgroundImage =
      'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=2574&auto=format&fit=crop';

  // Deprecated - keeping for backward compatibility
  static TextStyle get systemText =>
      bodyM.copyWith(fontWeight: fontWeightMedium, color: successColor);
}




Thought for 1s




I've completed the investigation into the "Liquid Glass" implementation. Here is the analysis report.

Phase 1: Analysis & Report
1. System Mapping
A. Visual Architecture (Layering Stack) This system is not just "frosted glass"; it renders a real-time refractive loop.

┌──────────────────────────────────────────────────────────────┐
│  LAYER 4: INTERACTIVE OVERLAYS (Buttons, Status Badges)      │
│  • High Distortion (0.10) | Sharp Edge Lighting              │
├──────────────────────────────────────────────────────────────┤
│  LAYER 3: FOCUSED CONTENT (The "Teleprompter")               │
│  • Medium Distortion (0.08) | Adaptive Text Sizing           │
│  • [Previous Card] (Peeking top, faded)                      │
│  • [Current Card]  (Center, full opacity)                    │
│  • [Next Card]     (Peeking bottom, faded)                   │
├──────────────────────────────────────────────────────────────┤
│  LAYER 2: MAIN GLASS SHEET (LiquidGlassBackground)           │
│  • Low Distortion (0.06) | Heavy Blur (28.0)                 │
│  • Acts as the "lens" for the whole screen                   │
├──────────────────────────────────────────────────────────────┤
│  LAYER 1: LOOPING VIDEO (LoopingBackgroundVideo)             │
│  • Source of color and movement for refraction               │
└──────────────────────────────────────────────────────────────┘
B. Class Relationships & Data Flow

[PolyVoiceScreen]
       │
       ▼
[LiquidGlassBackground] ──────── uses ──────────┐
       │                                        ▼
       ├── contains ── [LoopingBackgroundVideo] (Asset)
       │
       └── renders ──> [LiquidGlass] (Shader Widget)
                               │
                               ▼
                        [GlassStyle] (Math Engine)
                        - distortionForSize()
                        - blurForSize()
2. Function Analysis
LiquidGlassBackground.dart: This is the core wrapper. It stacks a video background behind the content and applies a shader.
Refraction Logic: It doesn't use simple opacity. It uses the 
liquid_glass_easy
 library to apply optical refraction, chromatic aberration, and edge lighting based on the underlying video.
Config: refreshRate: LiquidGlassRefreshRate.high forces 60fps for smooth glass physics.
GlassStyle
 (The Math): This class ensures consistency by calculating physics properties based on element size rather than hardcoded values.
Optimization: 
(0.12 - (minDim / 600).clamp(0.0, 1.0) * 0.07)
 — Smaller items (bubbles) get more distortion to look like thick glass gems; larger items (panels) get less to remain readable.
CardStackCalculator
 (The "Teleprompter"):
Logic: Implements a specific "Focus-First" UI where only one card is fully visible.
Adaptive Height: Complexity exists in 
calculateCardHeight
 which tries to estimate text wrapping to prevent overflow, clamped to 70% of viewport.

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../state/voice_session_state.dart';
import 'liquid_glass_background.dart';

/// Data model for a conversation card.
class GlassCardData {
  final String id;
  final String text;
  final String label;
  final bool isUser;
  final bool isPartial;

  const GlassCardData({
    required this.id,
    required this.text,
    required this.label,
    required this.isUser,
    this.isPartial = false,
  });
}

/// Builds focused single-card display for voice conversations.
/// Shows ONE card at a time, centered, with large readable text.
/// Swipe up/down to navigate between cards.
class CardStackCalculator {
  /// Horizontal margin from screen edges
  static const double horizontalMargin = 24.0;

  /// Padding inside each card
  static const double cardPaddingH = 28.0;
  static const double cardPaddingV = 24.0;

  /// Corner radius for cards
  static const double cardRadius = 24.0;

  /// Top padding (below status bar / debug area)
  static const double topPadding = 80.0;

  /// Bottom padding (above mic button)
  static const double bottomPadding = 160.0;

  /// Minimum font size for long text
  static const double minFontSize = 18.0;

  /// Maximum font size for short text
  static const double maxFontSize = 28.0;

  /// Character threshold for font size scaling
  static const int shortTextThreshold = 80;
  static const int longTextThreshold = 300;

  /// Convert transcripts to card data.
  static List<GlassCardData> fromTranscripts(
    List<TranscriptEntry> transcripts,
    String currentTranscript,
  ) {
    final cards = <GlassCardData>[];

    for (int i = 0; i < transcripts.length; i++) {
      final entry = transcripts[i];
      cards.add(GlassCardData(
        id: 'card_$i',
        text: entry.text,
        label: entry.isUser ? 'You' : 'Poly',
        isUser: entry.isUser,
      ));
    }

    // Add real-time partial transcript as a card (streaming)
    if (currentTranscript.isNotEmpty) {
      cards.add(GlassCardData(
        id: 'card_streaming',
        text: currentTranscript,
        label: 'Poly',
        isUser: false,
        isPartial: true,
      ));
    }

    return cards;
  }

  /// Calculate adaptive font size based on text length.
  /// Short text = large font, long text = smaller font.
  static double calculateFontSize(String text) {
    final length = text.length;

    if (length <= shortTextThreshold) {
      return maxFontSize;
    } else if (length >= longTextThreshold) {
      return minFontSize;
    } else {
      // Linear interpolation between thresholds
      final ratio = (length - shortTextThreshold) /
          (longTextThreshold - shortTextThreshold);
      return maxFontSize - (ratio * (maxFontSize - minFontSize));
    }
  }

  /// Calculate card height based on screen and text content.
  static double calculateCardHeight({
    required String text,
    required double screenWidth,
    required double screenHeight,
    required double fontSize,
  }) {
    final availableWidth =
        screenWidth - (horizontalMargin * 2) - (cardPaddingH * 2);
    final viewportHeight = screenHeight - topPadding - bottomPadding;

    // Estimate text height
    final charsPerLine = (availableWidth / (fontSize * 0.55)).clamp(15.0, 40.0);
    final lineCount = (text.length / charsPerLine).ceil().clamp(1, 20);
    final lineHeight = fontSize * 1.5;
    final textHeight = lineCount * lineHeight;

    // Label height + text + padding
    final contentHeight = 24 + 12 + textHeight + (cardPaddingV * 2);

    // Cap at 70% of viewport, minimum 120
    return contentHeight.clamp(120.0, viewportHeight * 0.7);
  }

  /// How much of the previous/next card peeks from top/bottom
  static const double peekAmount = 50.0;

  /// Height of peek preview cards (taller to show some content)
  static const double peekCardHeight = 100.0;

  /// Gap between stacked cards
  static const double cardGap = 12.0;

  /// Build the card stack with peek effect.
  /// Returns up to 3 cards: previous (peeking top), current (center), next (peeking bottom).
  static List<FloatingGlassElement> buildCardStack({
    required List<GlassCardData> cards,
    required int currentIndex,
    required double screenWidth,
    required double screenHeight,
    required double swipeOffset, // -1 to 1 for swipe animation
    Map<String, double>? heightOverrides,
  }) {
    if (cards.isEmpty || currentIndex < 0 || currentIndex >= cards.length) {
      return [];
    }

    final result = <FloatingGlassElement>[];
    final cardWidth = screenWidth - (horizontalMargin * 2);
    final viewportHeight = screenHeight - topPadding - bottomPadding;

    // Calculate center position for the current card
    final currentCard = cards[currentIndex];
    final currentFontSize = calculateFontSize(currentCard.text);
    final currentCardHeight = heightOverrides?[currentCard.id] ??
        calculateCardHeight(
          text: currentCard.text,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          fontSize: currentFontSize,
        );
    final centerY = topPadding + (viewportHeight - currentCardHeight) / 2;

    // --- PREVIOUS CARD (peeking from top) ---
    if (currentIndex > 0) {
      final prevCard = cards[currentIndex - 1];
      final prevFontSize = calculateFontSize(prevCard.text);

      // When peeking: show small preview. When swiping in: show full card
      final isPeeking = swipeOffset >= 0;
      final prevCardHeight = isPeeking
          ? peekCardHeight
          : heightOverrides?[prevCard.id] ??
              calculateCardHeight(
                text: prevCard.text,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                fontSize: prevFontSize,
              );

      // Base position: just above viewport edge
      final prevBaseY = topPadding - peekCardHeight + peekAmount;
      // Target when fully swiped in
      final prevTargetY = topPadding + (viewportHeight - prevCardHeight) / 2;
      // Interpolate based on swipe (offset < 0 means swiping down to see previous)
      final swipeProgress = (-swipeOffset).clamp(0.0, 1.0);
      final prevAnimatedY =
          prevBaseY + swipeProgress * (prevTargetY - prevBaseY);

      // Opacity: faded when peeking, full when swiping into view
      final prevOpacity =
          isPeeking ? 0.5 : (0.5 + swipeProgress * 0.5).clamp(0.5, 1.0);

      // Scale: smaller when peeking, grows when coming into view
      final prevScale =
          isPeeking ? 0.95 : (0.95 + swipeProgress * 0.05).clamp(0.95, 1.0);

      result.add(_buildCardElement(
        card: prevCard,
        cardWidth: cardWidth,
        cardHeight: prevCardHeight,
        positionY: prevAnimatedY,
        fontSize: isPeeking ? 14.0 : prevFontSize,
        opacity: prevOpacity,
        scale: prevScale,
        zIndex: 0,
        isPeek: isPeeking,
        peekFromTop: true,
      ));
    }

    // --- NEXT CARD (peeking from bottom) ---
    if (currentIndex < cards.length - 1) {
      final nextCard = cards[currentIndex + 1];
      final nextFontSize = calculateFontSize(nextCard.text);

      // When peeking: show small preview. When swiping in: show full card
      final isPeeking = swipeOffset <= 0;
      final nextCardHeight = isPeeking
          ? peekCardHeight
          : heightOverrides?[nextCard.id] ??
              calculateCardHeight(
                text: nextCard.text,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                fontSize: nextFontSize,
              );

      // Base position: just below viewport edge (position is top of card)
      final nextBaseY = screenHeight - bottomPadding - peekAmount;
      // Target when fully swiped in
      final nextTargetY = topPadding + (viewportHeight - nextCardHeight) / 2;
      // Interpolate based on swipe (offset > 0 means swiping up to see next)
      final swipeProgress = swipeOffset.clamp(0.0, 1.0);
      final nextAnimatedY =
          nextBaseY + swipeProgress * (nextTargetY - nextBaseY);

      // Opacity: faded when peeking, full when swiping into view
      final nextOpacity =
          isPeeking ? 0.5 : (0.5 + swipeProgress * 0.5).clamp(0.5, 1.0);

      // Scale: smaller when peeking, grows when coming into view
      final nextScale =
          isPeeking ? 0.95 : (0.95 + swipeProgress * 0.05).clamp(0.95, 1.0);

      result.add(_buildCardElement(
        card: nextCard,
        cardWidth: cardWidth,
        cardHeight: nextCardHeight,
        positionY: nextAnimatedY,
        fontSize: isPeeking ? 14.0 : nextFontSize,
        opacity: nextOpacity,
        scale: nextScale,
        zIndex: 0,
        isPeek: isPeeking,
        peekFromTop: false,
      ));
    }

    // --- CURRENT CARD (center, on top) ---
    // When swiping, current card moves in swipe direction and fades
    final currentAnimatedY = centerY + (swipeOffset * viewportHeight * 0.4);
    final currentOpacity = (1.0 - swipeOffset.abs() * 0.5).clamp(0.4, 1.0);
    final currentScale = (1.0 - swipeOffset.abs() * 0.05).clamp(0.95, 1.0);

    result.add(_buildCardElement(
      card: currentCard,
      cardWidth: cardWidth,
      cardHeight: currentCardHeight,
      positionY: currentAnimatedY,
      fontSize: currentFontSize,
      opacity: currentOpacity,
      scale: currentScale,
      zIndex: 1,
      isPeek: false,
    ));

    return result;
  }

  /// Helper to build a single card element with all visual properties.
  static FloatingGlassElement _buildCardElement({
    required GlassCardData card,
    required double cardWidth,
    required double cardHeight,
    required double positionY,
    required double fontSize,
    required double opacity,
    required double scale,
    required int zIndex,
    required bool isPeek,
    bool peekFromTop = false,
  }) {
    final tintColor = Color.fromRGBO(0, 0, 0, 0.7 * opacity);

    // Apply scale by adjusting width/height and centering
    final scaledWidth = cardWidth * scale;
    final scaledHeight = cardHeight * scale;
    final scaleOffsetX = (cardWidth - scaledWidth) / 2;
    final scaleOffsetY = (cardHeight - scaledHeight) / 2;

    return FloatingGlassElement(
      width: scaledWidth,
      height: scaledHeight,
      position: LiquidGlassOffsetPosition(
        top: positionY + scaleOffsetY,
        left: horizontalMargin + scaleOffsetX,
      ),
      cornerRadius: cardRadius * scale,
      tintColor: tintColor,
      blur: 25.0,
      borderWidth: isPeek ? 0.8 : 1.2,
      lightIntensity: 0.65 * opacity,
      lightColor: const Color(0x80FFFFFF),
      borderSoftness: 2.0,
      // Peek cards show truncated content, full cards show everything
      child: isPeek
          ? _PeekCardContent(
              label: card.label,
              text: card.text,
              isUser: card.isUser,
              opacity: opacity,
              peekFromTop: peekFromTop,
            )
          : _FocusedCardContent(
              label: card.label,
              text: card.text,
              isUser: card.isUser,
              isPartial: card.isPartial,
              fontSize: fontSize * scale,
              opacity: opacity,
            ),
    );
  }

  /// Build the card position indicator (e.g., "2 / 5").
  static FloatingGlassElement? buildCardIndicator({
    required int currentIndex,
    required int totalCards,
    required double screenWidth,
    required double screenHeight,
    required bool isFollowingLatest,
    required VoidCallback onTapLatest,
  }) {
    if (totalCards <= 1) {
      return null;
    }

    // Show "Jump to latest" button if not following
    if (!isFollowingLatest && currentIndex < totalCards - 1) {
      final indicatorWidth = 140.0;
      final indicatorHeight = 36.0;

      return FloatingGlassElement(
        width: indicatorWidth,
        height: indicatorHeight,
        position: LiquidGlassOffsetPosition(
          bottom: bottomPadding + 10,
          left: (screenWidth - indicatorWidth) / 2,
        ),
        cornerRadius: 18,
        tintColor: const Color(0x75000000),
        blur: 25.0,
        borderWidth: 1.0,
        lightIntensity: 0.6,
        lightColor: const Color(0x60FFFFFF),
        borderSoftness: 1.8,
        child: GestureDetector(
          onTap: onTapLatest,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentIndex + 1} / $totalCards',
                  style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_double_arrow_down_rounded,
                  color: Color(0xFF00D4FF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Simple position indicator when following latest
    final indicatorWidth = 60.0;
    final indicatorHeight = 28.0;

    return FloatingGlassElement(
      width: indicatorWidth,
      height: indicatorHeight,
      position: LiquidGlassOffsetPosition(
        bottom: bottomPadding + 10,
        left: (screenWidth - indicatorWidth) / 2,
      ),
      cornerRadius: 14,
      tintColor: const Color(0x75000000),
      blur: 25.0,
      borderWidth: 0.6,
      lightIntensity: 0.6,
      lightColor: const Color(0x40FFFFFF),
      borderSoftness: 1.5,
      child: Center(
        child: Text(
          '${currentIndex + 1} / $totalCards',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Content for peek cards - shows label and truncated message text.
/// peekFromTop: true = previous card peeking from top (show end of message)
/// peekFromTop: false = next card peeking from bottom (show start of message)
class _PeekCardContent extends StatelessWidget {
  final String label;
  final String text;
  final bool isUser;
  final double opacity;
  final bool peekFromTop;

  const _PeekCardContent({
    required this.label,
    required this.text,
    required this.isUser,
    required this.opacity,
    required this.peekFromTop,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isUser
        ? Colors.white.withValues(alpha: 0.6 * opacity)
        : Color.fromRGBO(0, 212, 255, 0.7 * opacity);
    final textColor = Colors.white.withValues(alpha: 0.55 * opacity);

    // Truncate text - show end for top peek, start for bottom peek
    final displayText = _truncateText(text, peekFromTop: peekFromTop);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisAlignment:
            peekFromTop ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // For top peek (previous card), show text first then label at bottom
          if (peekFromTop) ...[
            Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isUser ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 6),
          ],
          // Label row
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 212, 255, 0.6 * opacity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // For bottom peek (next card), show label first then text
          if (!peekFromTop) ...[
            const SizedBox(height: 6),
            Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isUser ? TextAlign.right : TextAlign.left,
            ),
          ],
        ],
      ),
    );
  }

  /// Truncate text for peek display
  String _truncateText(String text, {required bool peekFromTop}) {
    const maxChars = 80;
    if (text.length <= maxChars) return text;

    if (peekFromTop) {
      // Show end of message for top peek (previous card)
      return '...${text.substring(text.length - maxChars)}';
    } else {
      // Show start of message for bottom peek (next card)
      return '${text.substring(0, maxChars)}...';
    }
  }
}

/// Content widget for the focused glass card with adaptive text size.
class _FocusedCardContent extends StatelessWidget {
  final String label;
  final String text;
  final bool isUser;
  final bool isPartial;
  final double fontSize;
  final double opacity;

  const _FocusedCardContent({
    required this.label,
    required this.text,
    required this.isUser,
    required this.isPartial,
    required this.fontSize,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final textAlpha = (isPartial ? 0.85 : 1.0) * opacity;
    final labelColor = isUser
        ? Colors.white.withValues(alpha: 0.7 * opacity)
        : Color.fromRGBO(0, 212, 255, 0.9 * opacity);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CardStackCalculator.cardPaddingH,
        vertical: CardStackCalculator.cardPaddingV,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label row with indicator
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                if (isPartial)
                  const _PulsingStreamDot()
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (isPartial) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: labelColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Main text content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                text,
                textAlign: isUser ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: textAlpha),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.2,
                  fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingStreamDot extends StatefulWidget {
  const _PulsingStreamDot();

  @override
  State<_PulsingStreamDot> createState() => _PulsingStreamDotState();
}

class _PulsingStreamDotState extends State<_PulsingStreamDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _controller.value;
        final scale = 0.9 + (pulse * 0.4);
        final glowAlpha = 0.25 + (pulse * 0.55);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: glowAlpha),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

