# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-10

### Added
- **iOS CI/CD Pipeline**: Automated build and TestFlight deployment via GitHub Actions
- **Code Signing**: Proper provisioning profile and certificate configuration
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

### Fixed
- iOS signing certificate and provisioning profile mismatch
- Build configuration for Release and Profile schemes

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

