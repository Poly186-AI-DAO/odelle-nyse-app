# Local Development Guide

## Quick Reference

### Run App Commands

```bash
# List available devices
flutter devices

# Run on a specific device (use device ID or name)
flutter run -d "iPhone 14"
flutter run -d "iPhone 16 Pro Max"
flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848

# Run on macOS desktop
flutter run -d macos

# Run on Chrome (web)
flutter run -d chrome

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
# Quit: Press 'q' in terminal
```

---

## iOS Simulator Management

### List All Simulators

```bash
xcrun simctl list devices
```

### Common Simulator Device IDs (iOS 18.2)

| Device | UUID |
|--------|------|
| iPhone 14 | `84BD4C47-F305-4829-91EB-5789D8EE0848` |
| iPhone 14 Fresh | `B45149ED-3117-4FB4-81B6-3BE37491A705` |
| iPhone 14 iOS 18.2 | `E3F9DA62-F0B2-41EE-8D7B-3FDF6E11D678` |
| iPhone 15 | `E9774B34-5E8B-4890-B985-6879F9D342C9` |
| iPhone 16 | `27EBAFEA-F982-479F-A437-B3CF2BF60A2B` |
| iPhone 16 Pro | `33D50B96-D85C-4156-B2F7-2BB20E2C340F` |
| iPhone 16 Pro Max | `FA4E71FC-C33E-4C16-8F4F-8ACDC2D25CCF` |
| iPad Pro 11-inch (M4) | `11F303D7-5D37-438F-862B-3C6C7528345F` |

### Common Simulator Device IDs (iOS 18.6)

| Device | UUID |
|--------|------|
| iPhone 16 Pro Max | `800D80B9-3AFD-4B9A-9F08-0708A6EED552` |
| iPhone 16 Pro | `F74EC387-125C-4763-9A3E-B78941EBBEA3` |
| iPhone 16 | `A713A1E9-F065-43B6-989D-9DFDDBC7654B` |

### Boot a Simulator

```bash
# Boot by UUID
xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848

# Open Simulator app
open -a Simulator

# Then run Flutter
flutter run -d "iPhone 14"
```

### Shutdown a Simulator

```bash
xcrun simctl shutdown 84BD4C47-F305-4829-91EB-5789D8EE0848
```

---

## Initial Setup

### 1. Install Dependencies

```bash
cd /Users/princeps/Projects/Poly186/odelle-nyse-app
flutter pub get
```

### 2. Environment Variables

The app requires a `.env` file in the project root with:

```env
# Azure AI Foundry - Voice/Audio Models (Required)
AZURE_AI_FOUNDRY_ENDPOINT=https://poly-ai-foundry.cognitiveservices.azure.com
AZURE_AI_FOUNDRY_KEY=your_azure_key

# HuggingFace API token (Required)
HF_TOKEN=your_huggingface_token

# iOS Signing (Only for TestFlight/App Store builds)
IOS_P12_BASE64=...
IOS_PROVISIONING_PROFILE=...
IOS_P12_PASSWORD=...
```

### 3. Verify Setup

```bash
flutter doctor
flutter analyze
```

---

## Running the App

### Method 1: By Device Name (Easiest)

```bash
# First, boot the simulator if not running
xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848

# Then run
flutter run -d "iPhone 14"
```

### Method 2: By Device UUID (Most Reliable)

```bash
flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848
```

### Method 3: Interactive Selection

```bash
flutter run
# Flutter will prompt you to select a device
```

---

## Troubleshooting

### "No devices found" Error

1. Check if simulator is booted:
   ```bash
   xcrun simctl list devices | grep Booted
   ```

2. Boot the simulator:
   ```bash
   xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848
   ```

3. Wait a few seconds, then try again:
   ```bash
   flutter devices
   flutter run -d "iPhone 14"
   ```

### Simulator Won't Start

```bash
# Kill all simulators
killall Simulator

# Reset simulator (if corrupted)
xcrun simctl erase 84BD4C47-F305-4829-91EB-5789D8EE0848

# Reboot
xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848
```

### Build Issues

```bash
# Clean build
flutter clean
flutter pub get

# iOS specific
cd ios && pod install && cd ..

# Rebuild
flutter run -d "iPhone 14"
```

### Analyzer Errors

```bash
# Check for issues
flutter analyze

# Auto-fix some issues
dart fix --apply
```

---

## Development Workflow

### Hot Reload vs Hot Restart

| Action | Shortcut | When to Use |
|--------|----------|-------------|
| Hot Reload | `r` | UI changes, widget updates |
| Hot Restart | `R` | State changes, new dependencies |
| Full Restart | `q` then `flutter run` | Major code changes |

### Useful Commands

```bash
# Check connected devices
flutter devices

# Build without running
flutter build ios --debug

# Run with verbose logging
flutter run -d "iPhone 14" --verbose

# Run in release mode
flutter run -d "iPhone 14" --release

# Open DevTools
flutter run -d "iPhone 14"
# Then press 'd' in terminal
```

---

## Project Structure

```
odelle-nyse-app/
├── lib/
│   ├── main.dart           # App entry point
│   ├── screens/            # UI screens (body, mind, soul)
│   ├── widgets/            # Reusable components
│   ├── services/           # API integrations
│   ├── models/             # Data models
│   ├── providers/          # State management
│   ├── repositories/       # Data access layer
│   └── utils/              # Utilities & helpers
├── assets/                 # Images, icons, animations
├── ios/                    # iOS native code
├── android/                # Android native code
├── docs/                   # Documentation
└── .env                    # Environment variables
```

---

## Quick Copy-Paste Commands

```bash
# === MOST COMMON ===

# Run on iPhone 14 (iOS 18.2)
xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848 && flutter run -d "iPhone 14"

# Run on iPhone 16 Pro Max (iOS 18.6)
xcrun simctl boot 800D80B9-3AFD-4B9A-9F08-0708A6EED552 && flutter run -d "iPhone 16 Pro Max"

# Clean and rebuild
flutter clean && flutter pub get && flutter run -d "iPhone 14"

# Check for issues
flutter analyze && flutter test
```
