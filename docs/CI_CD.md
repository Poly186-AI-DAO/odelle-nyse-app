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
│  JOB: build-ios                                                  │
├─────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                │
│  2. Setup Flutter 3.35.3                                         │
│  3. Create .env file                                             │
│  4. Install dependencies (flutter pub get)                       │
│  5. Run Flutter analyze (--no-fatal-infos)                       │
│  6. Run tests (flutter test)                                     │
│  7. Build iOS (no codesign)                                      │
│  8. Upload artifact                                              │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  JOB: deploy-testflight (main branch only)                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Checkout code                                                │
│  2. Setup Flutter 3.35.3                                         │
│  3. Create .env file                                             │
│  4. Install dependencies                                         │
│  5. Import P12 certificate (Keychain)                            │
│  6. Setup provisioning profile                                   │
│  7. Create ExportOptions.plist                                   │
│  8. Build & Archive iOS app                                      │
│  9. Export IPA with signing                                      │
│ 10. Upload to TestFlight via altool                              │
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
| 2026-01-10 | ✅ First successful TestFlight deployment |
| 2026-01-10 | Fixed iPad orientation validation for App Store |
| 2026-01-09 | Fixed P12 certificate mismatch with provisioning profile |
| 2026-01-09 | Initial CI/CD setup with TestFlight deployment |
| 2026-01-09 | Updated Bundle ID to `com.poly186.odelle` |
| 2026-01-09 | Created Odelle Distribution provisioning profile |
