# CI/CD Documentation

## Overview

Odelle uses GitHub Actions for continuous integration and deployment. The pipeline automatically builds, tests, and deploys the iOS app to TestFlight.

---

## Workflows

### iOS Build & Deploy (`ios-build.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`

**Jobs:**

| Job | Description | Runs On |
|-----|-------------|---------|
| `build-ios` | Build and test without signing | Every push/PR |
| `deploy-testflight` | Sign and upload to TestFlight | Push to `main` only |

---

## Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────┐
│                        PUSH TO MAIN                              │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB: build-ios (macos-14, Xcode 16.2)                           │
├─────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                │
│  2. Select Xcode 16.2                                            │
│  3. Setup Flutter 3.35.3                                         │
│  4. Create .env file                                             │
│  5. Create GoogleService-Info.plist                              │
│  6. Install dependencies (flutter pub get)                       │
│  7. Cache CocoaPods (ios/Pods, ~/.cocoapods)                     │
│  8. Configure Git buffer (500MB for large pods)                  │
│  9. Install CocoaPods (with 5 retries + exponential backoff)     │
│ 10. Run Flutter analyze (--no-fatal-infos)                       │
│ 11. Build iOS (no codesign)                                      │
│ 12. Upload artifact                                              │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB: deploy-testflight (main branch only)                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                │
│  2. Select Xcode 16.2                                            │
│  3. Setup Flutter 3.35.3                                         │
│  4. Create .env file                                             │
│  5. Create GoogleService-Info.plist                              │
│  6. Install dependencies                                         │
│  7. Cache CocoaPods                                              │
│  8. Configure Git buffer                                         │
│  9. Setup iOS build environment                                  │
│ 10. Import P12 certificate (Keychain)                            │
│ 11. Setup provisioning profile                                   │
│ 12. Create ExportOptions.plist                                   │
│ 13. Build & Archive iOS app (with pod install retry)             │
│ 14. Export IPA with signing                                      │
│ 15. Upload to TestFlight via altool                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## GitHub Secrets

All secrets are stored in GitHub repository settings under **Settings → Secrets and variables → Actions**.

### Required Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `APPSTORE_API_KEY_ID` | App Store Connect API Key ID | App Store Connect → Users → Keys |
| `APPSTORE_API_PRIVATE_KEY` | The `.p8` file contents | Download from App Store Connect (one-time) |
| `APPSTORE_ISSUER_ID` | Your App Store Connect Issuer ID | App Store Connect → Users → Keys |
| `IOS_P12_BASE64` | Base64-encoded P12 certificate | `base64 -i certificate.p12` |
| `IOS_P12_PASSWORD` | Password for the P12 certificate | Set when exporting from Keychain |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded provisioning profile | `base64 -i profile.mobileprovision` |
| `HF_TOKEN` | HuggingFace API token | huggingface.co → Settings → Access Tokens |

### Optional Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_AI_FOUNDRY_ENDPOINT` | Azure AI Foundry endpoint URL |
| `AZURE_AI_FOUNDRY_KEY` | Azure AI Foundry API key |
| `AZURE_SPEECH_REGION` | Azure Speech region (e.g., `eastus2`) |

---

## Secret Classification

### ✅ Reusable Across Apps (Organization-level)

These can be shared across multiple apps in the same Apple Developer account:

| Secret | Why Reusable |
|--------|--------------|
| `APPSTORE_API_KEY_ID` | Same API key works for all apps |
| `APPSTORE_API_PRIVATE_KEY` | Same key file works for all apps |
| `APPSTORE_ISSUER_ID` | Same issuer for your team |
| `IOS_P12_BASE64` | Distribution certificate works for all apps |
| `IOS_P12_PASSWORD` | Same password for the certificate |
| `AZURE_*` secrets | Same Azure resource for all apps |
| `HF_TOKEN` | Same HuggingFace account |

### ❌ App-Specific (Must Create New)

These must be created separately for each app:

| Secret | Why App-Specific |
|--------|------------------|
| `IOS_PROVISIONING_PROFILE` | Tied to specific Bundle ID |

---

## Current Configuration

### App Identity

| Property | Value |
|----------|-------|
| Bundle ID | `com.poly186.odelle` |
| Team ID | `R9FF38AP48` |
| Team Name | POWER MOVES DEVELOPMENT LLC |

### Provisioning Profile

| Property | Value |
|----------|-------|
| Name | Odelle Distribution |
| Type | App Store (Distribution) |
| Bundle ID | `com.poly186.odelle` |
| Expiration | December 26, 2026 |

### App Store Connect API

| Property | Value |
|----------|-------|
| Key ID | `JP9GX2UYXJ` |
| Key Type | App Manager (All Apps) |
| Issuer ID | `e57a3bae-ee54-4759-8a3d-be2473467fd4` |

---

## Analyzer Configuration

The workflow runs `flutter analyze --no-fatal-infos`:

| Issue Severity | Build Behavior |
|----------------|----------------|
| Error | ❌ Fails build |
| Warning | ❌ Fails build |
| Info | ✅ Ignored |

See [ANALYZER_ISSUES.md](ANALYZER_ISSUES.md) for current analyzer status.

---

## Troubleshooting

### Common Issues

#### CocoaPods CDN HTTP 500 Errors (Transient)

**Error:**
```
error: RPC failed; HTTP 500 curl 22 The requested URL returned error: 500
fatal: expected 'packfile'
Error running pod install
```

**Root Cause:** This is a **transient server-side error** from the CocoaPods CDN infrastructure. It's a known issue ([GitHub #12000](https://github.com/CocoaPods/CocoaPods/issues/12000), [#12865](https://github.com/cocoapods/cocoapods/issues/12865)) that affects GitHub Actions intermittently.

**Solution (Implemented Jan 2026):**

1. **CocoaPods Caching** - Added `actions/cache@v4` to cache:
   - `ios/Pods`
   - `~/Library/Caches/CocoaPods`
   - `~/.cocoapods`
   
2. **Separate pod install step** - Moved pod install to its own step with:
   - 5 retry attempts (exponential backoff: 30s, 60s, 90s, 120s, 150s)
   - Clears corrupted cache on failure
   
3. **Git buffer configuration**:
   ```bash
   git config --global http.postBuffer 524288000  # 500MB
   git config --global http.lowSpeedLimit 0
   git config --global http.lowSpeedTime 999999
   ```

**If it still fails:** Simply re-run the GitHub Action. It's a transient CDN issue.

#### iOS 26 SDK Requirement (April 2026 Deadline)

**Warning from App Store Connect:**
```
SDK version issue. This app was built with the iOS 18.5 SDK. Starting April 2026, 
all iOS and iPadOS apps must be built with the iOS 26 SDK or later, included in 
Xcode 26 or later, in order to be uploaded to App Store Connect.
```

**Current Status:** Using Xcode 16.2 on `macos-14` runner. This provides iOS 18.2 SDK.

**Action Required:** Before April 2026, update to Xcode 26 when available:
```yaml
- name: Select Xcode 26
  uses: maxim-lobanov/setup-xcode@v1
  with:
    xcode-version: "26"
```

**Note:** The `Install iOS Platform` step was removed as Xcode 16.2 includes the required SDK. This step was causing unnecessary delays and wasn't needed.

#### "No provisioning profile was found"
- Check `IOS_PROVISIONING_PROFILE` secret is base64 encoded
- Verify profile is for correct Bundle ID (`com.poly186.odelle`)
- Ensure profile is not expired

#### "Certificate not found"
- Check `IOS_P12_BASE64` is properly base64 encoded
- Verify `IOS_P12_PASSWORD` is correct
- Ensure certificate is a Distribution certificate (not Development)

#### "Unable to authenticate with App Store Connect"
- Verify `APPSTORE_API_KEY_ID` matches the key filename
- Check `APPSTORE_API_PRIVATE_KEY` contains the full `.p8` file contents
- Ensure `APPSTORE_ISSUER_ID` is correct

#### "Analyzer failed"
- Check for warnings in `flutter analyze` output
- Run locally: `flutter analyze --no-fatal-infos`
- Fix all Warning-level issues (Info-level is ignored)

#### Swift Files Not in Xcode Project (Cannot find 'X' in scope)

**Error:**
```
error: Cannot find 'AgentActivityAttributes' in scope
/ios/Runner/AppDelegate.swift:106:33: error: Cannot find 'AgentActivityAttributes' in scope
```

**Root Cause:** Swift files exist in `ios/Runner/` but are not registered in `project.pbxproj`. This happens when files are added manually via file system rather than through Xcode.

**Solution:** Add the Swift file to `ios/Runner.xcodeproj/project.pbxproj` in these sections:

1. **PBXBuildFile section** - Add compilation reference:
   ```
   AAAA00001CF900000000001A /* AgentActivityAttributes.swift in Sources */ = {isa = PBXBuildFile; fileRef = AAAA00001CF900000000001B /* AgentActivityAttributes.swift */; };
   ```

2. **PBXFileReference section** - Declare the file:
   ```
   AAAA00001CF900000000001B /* AgentActivityAttributes.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AgentActivityAttributes.swift; sourceTree = "<group>"; };
   ```

3. **PBXGroup (Runner)** - Add to children array:
   ```
   AAAA00001CF900000000001B /* AgentActivityAttributes.swift */,
   ```

4. **PBXSourcesBuildPhase** - Add to compilation sources:
   ```
   AAAA00001CF900000000001A /* AgentActivityAttributes.swift in Sources */,
   ```

**Prevention:** Always add Swift files through Xcode, or open the project in Xcode after adding files to let it regenerate the project structure.

**Files currently in project.pbxproj:**
- `AppDelegate.swift` (Live Activities, MethodChannel)
- `AgentActivityAttributes.swift` (ActivityKit attributes for Live Activities)
- `GeneratedPluginRegistrant.m` (Flutter plugin registration)

#### Dead Dependencies Causing Build Failures

**Error:**
```
error: 'LoginConfiguration' cannot be constructed because it has no accessible initializers
/Pods/flutter_facebook_auth/FBSDKLoginConfiguration+Extension.swift:7:16
```

**Root Cause:** Unused dependencies (like `flutter_facebook_auth`) can break builds when their native SDKs update with breaking changes.

**Solution:**
1. Search codebase for actual usage:
   ```bash
   grep -r "facebook\|FacebookAuth" lib/
   ```
2. If no usage found, remove from `pubspec.yaml`
3. Clean build:
   ```bash
   flutter clean && flutter pub get
   cd ios && pod install --repo-update
   ```

**Prevention:** Periodically audit dependencies with `flutter pub deps` and remove unused packages.

#### BGTaskSchedulerPermittedIdentifiers Missing

**Error:**
```
Missing Info.plist value. The Info.plist key 'BGTaskSchedulerPermittedIdentifiers' must contain 
a list of identifiers used to submit and handle tasks when 'UIBackgroundModes' has a value of 'processing'.
```

**Root Cause:** When `UIBackgroundModes` contains `processing`, Apple requires a list of task identifiers that can be scheduled.

**Solution:** Add to `ios/Runner/Info.plist`:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.poly186.odelle.refresh</string>
    <string>com.poly186.odelle.processing</string>
</array>
```

**Current Background Modes:**
- `audio` - For ElevenLabs voice playback
- `voip` - For real-time voice communication
- `processing` - For background agent tasks (requires BGTaskSchedulerPermittedIdentifiers)

---

## Local Testing

### Test Build Locally

```bash
# Clean build
flutter clean && flutter pub get

# Analyze
flutter analyze --no-fatal-infos

# Run tests
flutter test

# Build iOS (no signing)
flutter build ios --no-codesign --release
```

### Test Signing Locally

```bash
# Archive
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive

# Export
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
```

---

## Updating Secrets

### Rotate App Store Connect API Key

1. Go to App Store Connect → Users and Access → Keys
2. Generate new key
3. Update GitHub secrets:
   - `APPSTORE_API_KEY_ID`
   - `APPSTORE_API_PRIVATE_KEY`

### Renew Provisioning Profile

1. Go to Apple Developer Portal → Certificates, Identifiers & Profiles
2. Create new provisioning profile for `com.poly186.odelle`
3. Download and encode:
   ```bash
   base64 -i NewProfile.mobileprovision | pbcopy
   ```
4. Update `IOS_PROVISIONING_PROFILE` secret in GitHub

### Renew Distribution Certificate

1. In Keychain Access, export new `.p12` with password
2. Encode:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```
3. Update GitHub secrets:
   - `IOS_P12_BASE64`
   - `IOS_P12_PASSWORD`

---

## Troubleshooting

### iPad Multitasking Validation Error

**Error:**
```
Invalid bundle. The "UIInterfaceOrientationPortrait" orientations were provided 
for UISupportedInterfaceOrientations, but you need to include all of the 
"UIInterfaceOrientationPortrait,UIInterfaceOrientationPortraitUpsideDown,
UIInterfaceOrientationLandscapeLeft,UIInterfaceOrientationLandscapeRight" 
orientations to support iPad multitasking.
```

**Solution:** In `ios/Runner/Info.plist`, add:
```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
<key>UIRequiresFullScreen</key>
<true/>
```

### Provisioning Profile Mismatch

**Error:** `Provisioning profile doesn't include signing certificate`

**Solution:** Ensure the P12 certificate in GitHub secrets matches the one used to create the provisioning profile. Export both from the same machine/Keychain.

---

## Version History

| Date | Change |
|------|--------|
| 2026-01-22 | Added BGTaskSchedulerPermittedIdentifiers for background processing validation |
| 2026-01-22 | Removed Facebook SDK config from Info.plist (dead dependency cleanup) |
| 2026-01-22 | Fixed AgentActivityAttributes.swift not in Xcode project.pbxproj |
| 2026-01-22 | Removed dead dependency `flutter_facebook_auth` causing Swift errors |
| 2026-01-22 | Added CocoaPods caching and 5-retry logic for CDN failures |
| 2026-01-22 | Removed unnecessary `Install iOS Platform` step |
| 2026-01-22 | Added Git buffer config (500MB) for large pods |
| 2026-01-22 | Upgraded to Xcode 16.2 for iOS 26 SDK compliance (April 2026 deadline) |
| 2026-01-10 | ✅ First successful TestFlight deployment |
| 2026-01-10 | Fixed iPad orientation validation for App Store |
| 2026-01-09 | Fixed P12 certificate mismatch with provisioning profile |
| 2026-01-09 | Initial CI/CD setup with TestFlight deployment |
| 2026-01-09 | Updated Bundle ID to `com.poly186.odelle` |
| 2026-01-09 | Created Odelle Distribution provisioning profile |
