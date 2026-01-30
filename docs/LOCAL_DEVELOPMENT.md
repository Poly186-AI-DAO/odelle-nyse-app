# Local Development Guide

## Quick Start - Physical iPhone (Recommended for Full Testing)

**✅ VERIFIED WORKING: January 30, 2026** - This is the primary development method!

For testing Live Activities, HealthKit, Push Notifications, and real device features.

### Physical Device Info
| Property | Value |
|----------|-------|
| Model | iPhone 13 |
| iOS Version | 18.6.2 |
| Device ID | `00008110-000124C81AD3601E` |
| CoreDevice ID | `08E2380D-3B96-5AB5-9FA3-06B92C6B44B3` |
| Team ID | `R9FF38AP48` (POWER MOVES DEVELOPMENT LLC) |
| Bundle ID | `com.poly186.odelle` |

### Run on Physical iPhone

```bash
# 1. Connect iPhone via USB cable
# 2. Unlock the phone and trust the computer if prompted
# 3. Verify device is detected
flutter devices

# 4. Run the app (takes ~5-6 minutes first time, ~45s after)
flutter run -d 00008110-000124C81AD3601E --debug
```

### Expected Output (Success)
```
Launching lib/main.dart on iPhone in debug mode...
Automatically signing iOS for device deployment using specified
development team in Xcode project: R9FF38AP48
Running pod install...                                              20.8s
Running Xcode build...
Xcode build done.                                           339.2s
Installing and launching...                                          45.1s
flutter: [AzureSpeechService]: Azure Realtime Service initialized with endpoint: wss://poly-ai-foundry.cognitiveservices.azure.com/openai/realtime
flutter: [SyncService]: Starting periodic sync every 5 minutes
flutter: [HomeScreen]: Starting bootstrap...
flutter: [AzureAgentService]: Azure Agent Service initialized
```

### Features Only Available on Physical Device

| Feature | Simulator | Physical iPhone |
|---------|-----------|-----------------|
| **Live Activities / Dynamic Island** | ❌ No | ✅ Yes |
| **HealthKit (real data)** | ❌ Fake data only | ✅ Real health data |
| **Push Notifications (APNs)** | ❌ No | ✅ Yes |
| **Apple Watch pairing** | ❌ No | ✅ Yes |
| **Background App Refresh** | ⚠️ Limited | ✅ Full |
| **WeatherKit** | ⚠️ May fail | ✅ Yes |
| **Camera/Microphone** | ⚠️ Simulated | ✅ Real hardware |
| **Location Services** | ⚠️ Simulated | ✅ Real GPS |

### Setup Required (One-Time)

These steps were done on Jan 30, 2026 and are preserved in the project:

1. **Install XcodeSystemResources** (fixes "developer disk image" error):
   ```bash
   sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /
   ```

2. **Enable Automatic Signing for Debug** in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Check "Automatically manage signing"
   - Select Team: POWER MOVES DEVELOPMENT LLC (R9FF38AP48)

3. **Sign in to Xcode** with Apple Developer account:
   - Xcode → Settings → Accounts → Add Apple ID

> **Note**: Release/Profile configurations still use Manual signing for CI/CD.
> This change only affects local Debug builds.

---

## Quick Start - Simulator (For UI Development)

**Tested: January 10, 2026** - These exact commands work:

```bash
# 1. Open Simulator app and boot iPhone 14
open -a Simulator && xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848

# 2. Verify device is detected
flutter devices

# 3. Run the app
cd /Users/princeps/Projects/Poly186/odelle-nyse-app
flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848 --debug
```

**Expected output:**
```
Launching lib/main.dart on iPhone 14 in debug mode...
Running Xcode build...
Xcode build done.                                           19.3s
Syncing files to device iPhone 14...
flutter: [AzureSpeechService]: Azure Realtime Service initialized with endpoint: wss://poly-ai-foundry.cognitiveservices.azure.com/openai/realtime
```

---

## Quick Reference

### Run App Commands

```bash
# List available devices
flutter devices

# === PHYSICAL DEVICE (Recommended) ===
# Run on physical iPhone (for Live Activities, HealthKit, Notifications)
flutter run -d 00008110-000124C81AD3601E --debug

# Run in release mode (faster performance)
flutter run -d 00008110-000124C81AD3601E --release

# === SIMULATORS ===
# Run on a specific simulator (use device ID or name)
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

## Physical iPhone Setup

### Prerequisites

1. **Developer Mode enabled** on iPhone (Settings → Privacy & Security → Developer Mode)
2. **Apple Developer account** signed into Xcode
3. **USB cable** connected (or paired for wireless debugging)

### First-Time Setup

```bash
# 1. Connect iPhone via USB
# 2. Trust the computer on your iPhone when prompted
# 3. Check device is recognized
flutter devices
xcrun devicectl list devices

# 4. If device shows "unavailable", ensure:
#    - iPhone is unlocked
#    - Developer Mode is ON
#    - You've trusted the computer
```

### Code Signing Configuration

The project is configured with:
- **Team ID**: `R9FF38AP48` (POWER MOVES DEVELOPMENT LLC)
- **Bundle ID**: `com.poly186.odelle`
- **Signing Certificate**: iPhone Distribution

### Wireless Debugging (Optional)

After initial USB pairing, you can debug wirelessly:

```bash
# 1. Connect iPhone to same WiFi as Mac
# 2. In Xcode: Window → Devices and Simulators
# 3. Select your iPhone → Check "Connect via network"
# 4. Disconnect USB, device should remain available
flutter devices
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

### Physical Device Issues

#### "Developer disk image could not be mounted" Error

**This is the most common error when running on physical iPhone.**

```
Error: The developer disk image could not be mounted on this device.
Timed out waiting for all destinations matching the provided destination specifier
```

**Solution (verified Jan 30, 2026):**

```bash
# Step 1: Install XcodeSystemResources (requires password)
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /

# Step 2: Retry
flutter run -d 00008110-000124C81AD3601E --debug
```

**If that doesn't work, try these in order:**

1. **Toggle Developer Mode on iPhone:**
   - Settings → Privacy & Security → Developer Mode → OFF
   - Restart iPhone
   - Turn Developer Mode back ON
   - Reconnect to Mac

2. **Clear Trusted Computers:**
   - On iPhone: Settings → Developer → Clear Trusted Computers
   - Reconnect iPhone and trust again

3. **Fix folder permissions:**
   ```bash
   sudo chmod a+w /private/var/tmp/
   ```

4. **Restart iPhone** - Sometimes a simple restart fixes it

5. **Disable VPN/Proxy** - Charles Proxy, Proxyman, or VPNs can interfere

---

#### "No Accounts" or "Provisioning Profile" Errors

```
Error: No Accounts: Add a new account in Accounts settings.
Error: No profiles for 'com.poly186.odelle' were found
```

**Solution:**

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Go to **Xcode → Settings (Cmd+,) → Accounts**

3. Click **+** to add your Apple Developer account

4. Select **Runner** target → **Signing & Capabilities**

5. Check **"Automatically manage signing"**

6. Select Team: **POWER MOVES DEVELOPMENT LLC (R9FF38AP48)**

7. Wait for Xcode to create the provisioning profile

8. Retry:
   ```bash
   flutter run -d 00008110-000124C81AD3601E --debug
   ```

---

#### "Device not found" or "unavailable"

```bash
# 1. Check if device is detected
xcrun devicectl list devices

# 2. If not listed, ensure:
#    - iPhone is unlocked
#    - USB cable is connected (use Apple cable)
#    - You've trusted the computer on iPhone
#    - Developer Mode is ON (Settings → Privacy & Security → Developer Mode)

# 3. Reset device pairing
sudo pkill usbmuxd
# Reconnect iPhone and trust again
```

---

#### Code Signing Errors

```bash
# Check available signing identities
security find-identity -v -p codesigning

# Should show:
# - "Apple Development: princepspolycap@gmail.com (8XR8UFM26J)"
# - "iPhone Distribution: POWER MOVES DEVELOPMENT LLC (R9FF38AP48)"

# If missing, open Xcode → Preferences → Accounts → Download certificates
```

---

#### "Could not launch" or App Crashes on Launch

```bash
# 1. Clean build
flutter clean && flutter pub get

# 2. Rebuild iOS
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..

# 3. Try again
flutter run -d 00008110-000124C81AD3601E --debug
```

---

#### HealthKit Permission Denied

1. On iPhone: Settings → Privacy & Security → Health → Odelle Nyse
2. Enable all required permissions
3. Restart the app

---

#### WeatherKit "Private key missing" Warning

This warning is expected if WeatherKit private key is not configured:
```
[WeatherService]: [WARN] WeatherKit private key missing or invalid format
```

The app will still work - weather features just won't be available.

---

### Simulator Issues

#### "No devices found" Error

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
# ============================================
# 🚀 PHYSICAL IPHONE - PRIMARY DEVELOPMENT METHOD
# ============================================
# ✅ VERIFIED WORKING: January 30, 2026
# Build time: ~5-6 min first run, ~45s subsequent

# Run on physical iPhone (debug mode - RECOMMENDED)
flutter run -d 00008110-000124C81AD3601E --debug

# Run on physical iPhone (release mode - faster app, no hot reload)
flutter run -d 00008110-000124C81AD3601E --release

# Run with verbose logging (for debugging issues)
flutter run -d 00008110-000124C81AD3601E --debug --verbose

# ============================================
# ONE-TIME SETUP (if "developer disk image" error occurs)
# ============================================

# Fix developer disk image error (requires password)
sudo installer -pkg /Applications/Xcode.app/Contents/Resources/Packages/XcodeSystemResources.pkg -target /

# Then open Xcode, sign in, and enable automatic signing:
open ios/Runner.xcworkspace

# ============================================
# SIMULATOR (For quick UI iteration only)
# ============================================
# Tested: January 10, 2026

# Boot simulator + run app (one-liner)
open -a Simulator && xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848 || true && flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848 --debug

# === STEP BY STEP ===

# 1. Open Simulator app
open -a Simulator

# 2. Boot iPhone 14 (ignore error if already booted)
xcrun simctl boot 84BD4C47-F305-4829-91EB-5789D8EE0848 || true

# 3. Verify device shows up
flutter devices

# 4. Run the app
flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848 --debug

# === OTHER SIMULATORS ===

# Run on iPhone 16 Pro (iOS 18.2)
xcrun simctl boot 33D50B96-D85C-4156-B2F7-2BB20E2C340F && flutter run -d 33D50B96-D85C-4156-B2F7-2BB20E2C340F

# Run on iPhone 16 Pro Max (iOS 18.6)
xcrun simctl boot 800D80B9-3AFD-4B9A-9F08-0708A6EED552 && flutter run -d 800D80B9-3AFD-4B9A-9F08-0708A6EED552

# ============================================
# MAINTENANCE
# ============================================

# Clean and rebuild (physical device)
flutter clean && flutter pub get && flutter run -d 00008110-000124C81AD3601E

# Clean and rebuild (simulator)
flutter clean && flutter pub get && flutter run -d 84BD4C47-F305-4829-91EB-5789D8EE0848

# Check for issues
flutter analyze

# Shutdown all simulators
killall Simulator

# Check connected physical devices
xcrun devicectl list devices
```
