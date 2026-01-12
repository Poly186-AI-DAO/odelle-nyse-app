# ElevenLabs Integration

## Configured Voices

We use specific custom voices mapped to different content types in `ElevenLabsConfig`.

| Voice Name | ID | Category | Description | Use Case |
|------------|----|----------|-------------|----------|
| **Theo Silk** | `UmQN7jS1Ee8B1czsUtQh` | Professional | British Deep Sleep & Meditation. Profoundly calm, grounding, low-register. | **Meditation**, Conversational (Default) |
| **Brittney** | `pjcYQlDFKMbcOUp6F5GD` | Professional | Relaxing, Calm, Meditative. Smooth, measured, youthful but clear. | **Affirmation** |
| **Calm Lady** | `AiJZqQzutCDRG8cUOJwK` | Generated | Calm, soothing, clear with natural cadence. | **Guidance** |
| **Edward** | `goT3UYdM9bhm0n2lmKQx` | Professional | British, Dark, Seductive, Low. Strong British leader. | **Motivation**, **Workout** |

## Usage & Quota

**Plan:** Starter Tier
**Monthly Quota:** 40,000 characters
**Reset Date:** Monthly (check `logs` or `ElevenLabs Console`)

### Cost Estimates
- **Daily Meditation (5 min script):** ~3,000 - 4,000 chars
- **Affirmation (Short):** ~200 - 500 chars
- **Workout Cues:** ~500 - 1,000 chars

**Note:** If we generate daily content every day, 40k characters will last about **10-12 days**. We should only generate on demand or upgrade the plan.

## Service Architecture

The `DailyContentService` handles generation:
1.  **Script:** Azure GPT-5 (context-aware)
2.  **Image:** Azure FLUX.2-pro
3.  **Audio:** ElevenLabs API (using above voices)

Audio files are saved locally to `ApplicationDocumentsDirectory/generated/`.
