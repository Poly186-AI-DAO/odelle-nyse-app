# Analyzer Issues Tracking

Last updated: 2026-01-09

## Build Configuration
The workflow runs `flutter analyze --no-fatal-infos`, meaning:
- ✅ **Info-level** issues are ignored
- ❌ **Warning-level** issues fail the build

---

## 🔴 BUILD-BLOCKING (Warnings)

| File | Line | Issue | Status |
|------|------|-------|--------|
| `lib/models/user_model.dart` | 521 | Unnecessary cast | ⏳ TODO |
| `lib/screens/home_screen.dart` | 246 | Unused `_disconnect` method | ⏳ TODO |

---

## 🟡 NON-BLOCKING (Info-level)

### Deprecated API Usage

| File | Line | Deprecated | Replacement |
|------|------|------------|-------------|
| `lib/utils/file_audio_queue.dart` | 7, 11 | `ConcatenatingAudioSource` | `AudioPlayer.setAudioSources` |
| `lib/widgets/effects/animated_scanlines.dart` | 76, 94 | `withOpacity` | `withValues(alpha: x)` |
| `lib/widgets/effects/cyber_title.dart` | 77 | `withOpacity` | `withValues(alpha: x)` |
| `lib/widgets/actions/slide_to_action.dart` | 306 | `scale` | `scaleByDouble` |

### Print Statements (should use Logger)

| File | Lines |
|------|-------|
| `lib/utils/file_audio_queue.dart` | 40 |
| `lib/services/google_auth_service.dart` | 48, 81, 91, 102, 105, 108, 130, 144 |

---

## Fix Priority

1. **HIGH** - Fix 2 warnings to unblock build
2. **MEDIUM** - Replace `print` with `Logger` calls
3. **LOW** - Update deprecated API usage (info-level only)

---

## Notes

- The `_disconnect` method in `home_screen.dart` appears to be dead code - defined but never called
- Consider keeping it if it's needed for a disconnect button feature, or remove it
- The `ConcatenatingAudioSource` deprecation may require refactoring the audio queue
