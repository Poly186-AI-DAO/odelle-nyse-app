# Voice Live API Architecture

## Overview

Odelle uses the **Azure OpenAI Realtime API** (`/realtime` endpoint) for real-time voice interactions via WebSocket. This provides low-latency, speech-in/speech-out conversational capabilities with GPT-4o.

## Three Core Modes

### 1. Live Conversation Mode
Full bidirectional voice conversation with AI responding in audio.

```
┌─────────────┐     audio (pcm16)     ┌─────────────────┐
│   User      │ ───────────────────→  │  Azure OpenAI   │
│   (mic)     │                       │  Realtime API   │
│             │ ←───────────────────  │                 │
│   (speaker) │     audio + text      │  (gpt-realtime) │
└─────────────┘                       └─────────────────┘
```

**Session Config:**
```json
{
  "type": "session.update",
  "session": {
    "modalities": ["text", "audio"],
    "voice": "alloy",
    "turn_detection": { "type": "server_vad" },
    "input_audio_format": "pcm16",
    "output_audio_format": "pcm16",
    "input_audio_transcription": { "model": "whisper-1" }
  }
}
```

**Use Case:** Kitchen Confessional conversations, AI coaching

---

### 2. Transcription-Only Mode
Voice input → text transcription, no AI audio response.

```
┌─────────────┐     audio (pcm16)     ┌─────────────────┐
│   User      │ ───────────────────→  │  Azure OpenAI   │
│   (mic)     │                       │  Realtime API   │
│             │ ←───────────────────  │                 │
│             │     transcription     │  (whisper-1)    │
└─────────────┘         only          └─────────────────┘
```

**Session Config:**
```json
{
  "type": "session.update",
  "session": {
    "modalities": ["text"],
    "turn_detection": { "type": "server_vad" },
    "input_audio_format": "pcm16",
    "input_audio_transcription": { "model": "whisper-1" }
  }
}
```

**Use Case:** Voice journaling, note-taking, quick captures

---

### 3. Tool Calling Mode (Agent)
Real-time voice with function/tool calling capabilities.

```
┌─────────────┐     audio + tools     ┌─────────────────┐
│   User      │ ───────────────────→  │  Azure OpenAI   │
│   (voice)   │                       │  Realtime API   │
│             │ ←───────────────────  │                 │
│             │  audio + tool_calls   │  + tool defs    │
│             │                       │                 │
│   App       │ ─── tool_response ──→ │                 │
│             │ ←── continue resp ──  │                 │
└─────────────┘                       └─────────────────┘
```

**Session Config:**
```json
{
  "type": "session.update",
  "session": {
    "modalities": ["text", "audio"],
    "voice": "alloy",
    "turn_detection": { "type": "server_vad" },
    "input_audio_format": "pcm16",
    "output_audio_format": "pcm16",
    "input_audio_transcription": { "model": "whisper-1" },
    "tools": [
      {
        "type": "function",
        "name": "save_journal_entry",
        "description": "Saves a journal entry to the database",
        "parameters": {
          "type": "object",
          "properties": {
            "content": { "type": "string", "description": "Journal entry text" },
            "mood": { "type": "string", "enum": ["happy", "sad", "neutral", "anxious", "excited"] }
          },
          "required": ["content"]
        }
      }
    ]
  }
}
```

**Use Case:** Voice commands, AI agent actions, workflow automation

---

## WebSocket Protocol

### Connection URL
```
wss://<resource>.cognitiveservices.azure.com/openai/realtime
  ?api-version=2024-10-01-preview
  &deployment=<deployment-name>
  &api-key=<api-key>
```

### Message Flow

```
Client                                   Server
  │                                         │
  │──── [connect WebSocket] ───────────────→│
  │                                         │
  │←──── session.created ──────────────────│
  │                                         │
  │───── session.update ───────────────────→│ (configure session)
  │←──── session.updated ──────────────────│
  │                                         │
  │───── input_audio_buffer.append ────────→│ (stream audio)
  │───── input_audio_buffer.append ────────→│
  │───── input_audio_buffer.append ────────→│
  │                                         │
  │←──── input_audio_buffer.speech_started ─│ (VAD detected speech)
  │                                         │
  │←──── input_audio_buffer.speech_stopped ─│ (VAD detected silence)
  │                                         │
  │←──── conversation.item.created ────────│
  │←──── conversation.item.audio_           │
  │      transcription.completed ──────────│ (user transcription)
  │                                         │
  │←──── response.created ─────────────────│
  │←──── response.output_item.added ───────│
  │←──── response.audio.delta ─────────────│ (streaming audio)
  │←──── response.audio_transcript.delta ──│ (streaming text)
  │←──── response.done ────────────────────│
  │                                         │
```

---

## Key Events Reference

### Server → Client Events

| Event | Description |
|-------|-------------|
| `session.created` | Connection established, session ID provided |
| `session.updated` | Session configuration acknowledged |
| `input_audio_buffer.speech_started` | VAD detected user speech (includes `audio_start_ms`) |
| `input_audio_buffer.speech_stopped` | VAD detected end of speech (includes `audio_end_ms`) |
| `input_audio_buffer.committed` | Audio buffer committed (by client or server VAD) |
| `input_audio_buffer.cleared` | Audio buffer cleared (confirmation) |
| `conversation.item.created` | New conversation item created (user message or AI response) |
| `conversation.item.input_audio_transcription.completed` | User speech transcribed |
| `response.created` | AI response generation started |
| `response.audio.delta` | Streaming audio response chunk |
| `response.audio_transcript.delta` | Streaming text of audio response |
| `response.function_call_arguments.delta` | Streaming function call args |
| `response.done` | Response complete |
| `error` | Error occurred |

### Client → Server Commands

| Command | Description |
|---------|-------------|
| `session.update` | Configure session (first thing after connect) |
| `input_audio_buffer.append` | Send audio chunk (base64 encoded) |
| `input_audio_buffer.commit` | Manually commit audio (for `turn_detection: none`) |
| `input_audio_buffer.clear` | Clear audio buffer (reset for next turn) |
| `response.create` | Manually trigger response generation |
| `response.cancel` | Cancel in-progress response |
| `conversation.item.create` | Add item to conversation (text, tool response) |

---

## Audio Format Requirements

| Property | Value |
|----------|-------|
| Format | PCM 16-bit |
| Sample Rate | 24,000 Hz |
| Channels | Mono (1) |
| Encoding | Little-endian |
| Base64 | Yes (for WebSocket JSON) |

**Flutter mic_stream config:**
```dart
MicStream.microphone(
  sampleRate: 24000,
  channelConfig: ChannelConfig.CHANNEL_IN_MONO,
  audioFormat: AudioFormat.ENCODING_PCM_16BIT,
)
```

---

## Turn Detection Modes

### `server_vad` (Voice Activity Detection)
- Server automatically detects speech start/stop
- Triggers response generation on silence
- Best for natural conversation

```json
"turn_detection": {
  "type": "server_vad",
  "threshold": 0.5,
  "silence_duration_ms": 500
}
```

### `none` (Manual Control)
- Client controls turn boundaries
- Must call `input_audio_buffer.commit` + `response.create`
- Best for push-to-talk or file playback

```json
"turn_detection": null
```

---

## Implementation in Odelle

### Current Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         VoiceScreen                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ GestureDetector                                          │   │
│  │   onTap → _connect()         (tap to connect)            │   │
│  │   onLongPressStart → _startRecording()                   │   │
│  │   onLongPressEnd → _stopRecording()                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ AzureSpeechService                                       │   │
│  │   - WebSocket connection                                 │   │
│  │   - Audio buffer management                              │   │
│  │   - Event callbacks                                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ MicStream                                                │   │
│  │   - PCM16 @ 24kHz                                        │   │
│  │   - Mono channel                                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

### Callback Flow

```dart
// User transcription received
_speechService.onTranscription = (text) {
  // Save to journal, display
};

// Partial transcription (streaming)
_speechService.onPartialResult = (text) {
  // Show real-time text
};

// AI audio response
_speechService.onAudioResponse = (audioData) {
  // Play through speaker
};

// AI text response
_speechService.onTextResponse = (text) {
  // Display AI response text
};

// Speech detection
_speechService.onSpeechStarted = () {
  // Show "listening" indicator
};

_speechService.onSpeechStopped = () {
  // Processing...
};
```

---

## Environment Variables

```env
# Azure OpenAI Realtime API
AZURE_GPT_REALTIME_KEY=<your-api-key>
AZURE_GPT_REALTIME_DEPLOYMENT_URL=https://<resource>.cognitiveservices.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=<deployment>
```

---

## Current Implementation Status

### ✅ Completed
- **WebSocket Connection** - Connects to Azure OpenAI Realtime API
- **Session Configuration** - Configures session for conversation or transcription mode
- **Audio Streaming** - Streams PCM16 audio to Azure (24kHz mono)
- **Server VAD** - Voice Activity Detection for natural turn-taking
- **Audio Playback** - Plays AI audio responses through device speaker
- **Interruption Handling** - Stops AI audio when user starts speaking
- **Multi-Turn State Management** - Maintains recording state between turns
- **Diagnostic Logging** - Tracks audio chunks, VAD events, state transitions

### 🔧 Recently Fixed (Jan 2026)
- Added `input_audio_buffer.cleared` event handler
- Added `input_audio_buffer.committed` event handler  
- Added `conversation.item.created` event handler
- State drift detection after `response.done`
- Auto-restore recording state for next turn
- Audio chunk tracking for debugging

### ⚠️ Known Issues
- Multi-turn conversation may require testing after VAD fixes
- Buffer clear timing might need adjustment based on testing

---

## Multi-Turn Conversation Flow

```
TURN 1:
  ┌──────────┐                           ┌──────────┐
  │  Client  │                           │  Azure   │
  └────┬─────┘                           └────┬─────┘
       │                                      │
       │─── input_audio_buffer.append ───────→│
       │─── input_audio_buffer.append ───────→│
       │                                      │
       │←── input_audio_buffer.speech_started │
       │                                      │
       │←── input_audio_buffer.speech_stopped │
       │←── input_audio_buffer.committed ─────│
       │←── conversation.item.created ────────│
       │                                      │
       │←── response.created ─────────────────│
       │←── response.audio.delta ─────────────│
       │←── response.audio_transcript.delta ──│
       │←── response.done ────────────────────│
       │                                      │
       │─── input_audio_buffer.clear ────────→│ (reset for next turn)
       │←── input_audio_buffer.cleared ───────│
       │                                      │

TURN 2+:
       │─── input_audio_buffer.append ───────→│ (new audio)
       │←── input_audio_buffer.speech_started │ (VAD detects new speech)
       │    ... (same flow as Turn 1) ...     │
```

---

## Future Enhancements

### Phase 1: Conversation Polish
1. ~~**Multi-Turn Conversation**~~ ✅ - Fixed VAD state management
2. **Waveform Standardization** - Unify `VoiceWaveformAnimated` and `WaveformVisualizer` components
3. **Typing Animation** - Use `ConversationText` widget for AI response display

### Phase 2: Agentic Voice
4. **Tool Registration** - Dynamic tool registration for different screens
5. **Function Calling** - Enable AI to call functions during conversation
6. **Tool Response Handling** - Send tool results back to continue response

### Phase 3: Advanced Features
7. **Mode Switching UI** - Allow user to toggle between Live, Transcription-Only, and Agent modes
8. **Semantic VAD** - Use Azure's `semantic_vad` for smarter turn detection
9. **Offline Queue** - Queue recordings when offline, sync when connected
10. **Conversation History** - Persist and display conversation threads
