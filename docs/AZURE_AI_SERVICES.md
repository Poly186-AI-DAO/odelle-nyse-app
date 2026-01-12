# Azure AI Services Integration Guide

This document explains how to use the Azure AI services in the Odelle app, including chat completions (GPT-5.2-chat, GPT-5-nano) and image generation (FLUX.2-pro).

## Overview

The app uses Azure AI Foundry for all AI capabilities, running **on-device** (no custom backend required):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ARCHITECTURE                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐     HTTPS      ┌─────────────────────────────────────┐  │
│   │              │ ─────────────► │       Azure AI Foundry              │  │
│   │  Flutter App │                │  ┌─────────────────────────────────┐│  │
│   │              │ ◄───────────── │  │ GPT-5.2-chat (heavy reasoning)  ││  │
│   │  On-Device   │                │  │ GPT-5-nano   (fast/cheap)       ││  │
│   │              │                │  │ FLUX.2-pro   (image generation) ││  │
│   └──────────────┘                │  └─────────────────────────────────┘│  │
│                                   └─────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Services

### 1. AzureAgentService (Chat + Tool Calling)

**File:** `lib/services/azure_agent_service.dart`

Provides chat completions with tool/function calling support.

#### Models Available

| Model | Deployment | Use Case |
|-------|------------|----------|
| GPT-5.2-chat | `gpt-5.2-chat` | Heavy reasoning, complex tasks |
| GPT-5-nano | `gpt-5-nano` | Fast responses, simple tasks |

#### Basic Usage

```dart
import 'package:odelle/services/azure_agent_service.dart';

final agent = AzureAgentService();

// Simple completion (fast, cheap)
final answer = await agent.complete(
  prompt: 'What is the capital of France?',
  systemPrompt: 'Be concise.',
);
print(answer); // "Paris"

// Use heavy model for complex reasoning
final analysis = await agent.complete(
  prompt: 'Analyze the benefits of meditation for athletes',
  deployment: AzureAIDeployment.gpt5Chat,
  temperature: 0.7,
  maxTokens: 500,
);
```

#### Tool Calling (Agent Mode)

```dart
// Define tools
final tools = [
  ToolDefinition(
    name: 'log_workout',
    description: 'Log a workout to the fitness tracker',
    parameters: {
      'type': 'object',
      'properties': {
        'type': {'type': 'string', 'description': 'Type of workout'},
        'duration_minutes': {'type': 'integer'},
        'calories': {'type': 'integer'},
      },
      'required': ['type', 'duration_minutes'],
    },
  ),
  ToolDefinition(
    name: 'get_workout_stats',
    description: 'Get workout statistics',
    parameters: {
      'type': 'object',
      'properties': {
        'period': {'type': 'string', 'enum': ['today', 'week', 'month']},
      },
      'required': ['period'],
    },
  ),
];

// Run agent loop
final response = await agent.runAgent(
  messages: [
    ChatMessage.system('You are a fitness assistant.'),
    ChatMessage.user('I just did a 30 minute run. Log it for me.'),
  ],
  tools: tools,
  executor: (name, args) async {
    // Execute tool and return result
    switch (name) {
      case 'log_workout':
        await workoutRepo.log(args!);
        return 'Logged workout successfully';
      case 'get_workout_stats':
        final stats = await workoutRepo.getStats(args!['period']);
        return jsonEncode(stats);
      default:
        return 'Unknown tool';
    }
  },
);

print(response.message.content);
// "Great job! I've logged your 30-minute run..."
```

### 2. AzureImageService (Image Generation)

**File:** `lib/services/azure_image_service.dart`

Generates images using FLUX.2-pro via Azure AI Foundry.

#### Usage

```dart
import 'package:odelle/services/azure_image_service.dart';

final imageService = AzureImageService();

// Generate image
final result = await imageService.generateImage(
  prompt: 'A serene mountain landscape at sunset, photorealistic',
  size: ImageSize.landscape, // 1536x1024
);

// Use in Image widget
Image.memory(result.bytes);

// Or use data URL
Image.network(result.dataUrl);
```

#### Size Options

| Size | Dimensions | Use Case |
|------|------------|----------|
| `ImageSize.square` | 1024x1024 | Profile pics, icons |
| `ImageSize.portrait` | 1024x1536 | Stories, mobile wallpapers |
| `ImageSize.landscape` | 1536x1024 | Banners, desktop wallpapers |

---

## Environment Variables

### Required in `.env`

```bash
# Azure AI Foundry - Chat Models
AZURE_AI_FOUNDRY_ENDPOINT=https://poly-ai-foundry.cognitiveservices.azure.com
AZURE_AI_FOUNDRY_KEY=your_key_here

# Chat Model Deployments (optional - defaults shown)
AZURE_GPT_5_2_CHAT_DEPLOYMENT=gpt-5.2-chat
AZURE_GPT_5_NANO_DEPLOYMENT=gpt-5-nano

# Azure AI Foundry - Image Generation (FLUX.2-pro)
FLUX_2_PRO_AZURE_URL=https://poly-ai-foundry.cognitiveservices.azure.com/providers/blackforestlabs/v1/flux-2-pro
FLUX_2_PRO_KEY=your_key_here  # Can use same key as AZURE_AI_FOUNDRY_KEY
FLUX_2_PRO_DEPLOYMENT=FLUX.2-pro
```

---

## GitHub Secrets (CI/CD)

Add these secrets in **GitHub Repository → Settings → Secrets and variables → Actions**:

### Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_AI_FOUNDRY_ENDPOINT` | Azure OpenAI endpoint URL | `https://poly-ai-foundry.cognitiveservices.azure.com` |
| `AZURE_AI_FOUNDRY_KEY` | Azure OpenAI API key | `4Dywjoi40Lj...` |
| `AZURE_GPT_5_2_CHAT_DEPLOYMENT` | GPT-5.2 deployment name | `gpt-5.2-chat` |
| `AZURE_GPT_5_NANO_DEPLOYMENT` | GPT-5 Nano deployment name | `gpt-5-nano` |
| `FLUX_2_PRO_AZURE_URL` | FLUX.2-pro endpoint URL | `https://...blackforestlabs/v1/flux-2-pro` |
| `FLUX_2_PRO_KEY` | FLUX API key (can be same as Foundry key) | `4Dywjoi40Lj...` |
| `FLUX_2_PRO_DEPLOYMENT` | FLUX model name | `FLUX.2-pro` |

### How to Add Secrets

1. Go to: `https://github.com/Poly186-AI-DAO/odelle-nyse-app/settings/secrets/actions`
2. Click "New repository secret"
3. Add each secret from the table above
4. The workflow already creates `.env` from these secrets

---

## API Reference

### Chat Completions API

**Endpoint Pattern:**
```
POST {AZURE_AI_FOUNDRY_ENDPOINT}/openai/deployments/{deployment}/chat/completions?api-version=2025-01-01-preview
```

**Headers:**
```
Content-Type: application/json
api-key: {AZURE_AI_FOUNDRY_KEY}
```

**Request Body:**
```json
{
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "max_completion_tokens": 100,
  "temperature": 0.7,
  "tools": [...],  // Optional: function definitions
  "response_format": {"type": "json_object"}  // Optional: force JSON output
}
```

**Note:** GPT-5-nano does NOT support `temperature` parameter.

### Image Generation API (FLUX.2-pro)

**Endpoint:**
```
POST {FLUX_2_PRO_AZURE_URL}?api-version=preview
```

**Headers:**
```
Content-Type: application/json
Api-Key: {FLUX_2_PRO_KEY}
```

**Request Body:**
```json
{
  "prompt": "A beautiful sunset over mountains",
  "model": "flux.2-pro",
  "n": 1,
  "size": "1024x1024"
}
```

**Response:**
```json
{
  "data": [
    {
      "b64_json": "iVBORw0KGgo..."
    }
  ]
}
```

---

## Testing

Run the test suite to verify everything is working:

```bash
dart run test/new_azure_agent_test.dart
```

Expected output:
```
================================================================
          AZURE AI SERVICES - COMPREHENSIVE TEST                
================================================================

  Test 1: Simple Chat Completion (GPT-5.2-chat) ✓
  Test 2: Tool/Function Calling (GPT-5.2-chat) ✓
  Test 3: Agent Loop with Tool Execution ✓
  Test 4: Image Generation (FLUX.2-pro) ✓

================================================================
                        TEST SUMMARY                            
================================================================
  Passed: 4
  Failed: 0
================================================================
```

---

## Troubleshooting

### "Azure AI Foundry key or endpoint not found"
- Ensure `.env` file exists in project root
- Check that `flutter_dotenv` is loading the file in `main.dart`

### "401 Unauthorized"
- Verify API key is correct
- Check if key has expired or been rotated in Azure Portal

### "404 Not Found" on chat
- Verify deployment name matches exactly (case-sensitive)
- Check API version in URL

### Image generation returns empty
- FLUX.2-pro requires `model` in lowercase (`flux.2-pro`)
- Use `Api-Key` header (capital A and K), not `api-key`

---

## File Structure

```
lib/
├── config/
│   └── azure_ai_config.dart    # Deployment enums, URI builders
├── services/
│   ├── azure_agent_service.dart # Chat + Tool calling
│   └── azure_image_service.dart # Image generation
test/
└── new_azure_agent_test.dart    # Comprehensive test suite
```
