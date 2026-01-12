// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test script for DailyContentService functionality
/// Tests GPT-5 Nano and GPT-5.2 Chat for generating meditations/affirmations
/// Saves content to JSON file for app to load
/// 
/// Run with: dart run test/daily_content_test.dart
/// 
/// Token limits from Azure docs (Jan 2026):
/// ┌────────────────┬────────────┬─────────────┐
/// │ Model          │ Context    │ Max Output  │
/// ├────────────────┼────────────┼─────────────┤
/// │ GPT-5.2-chat   │ 128,000    │ 16,384      │
/// │ GPT-5-nano     │ 400,000    │ 128,000     │  <- Cheapest, needs 1k+ tokens
/// │ GPT-5-mini     │ 400,000    │ 128,000     │
/// │ GPT-5-chat     │ 128,000    │ 16,384      │
/// └────────────────┴────────────┴─────────────┘
void main() async {
  print('================================================================');
  print('       DAILY CONTENT SERVICE - LOCAL TEST                       ');
  print('================================================================\n');

  // Read .env file
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERROR: .env file not found');
    exit(1);
  }

  final env = _parseEnvFile(envFile.readAsStringSync());

  final apiKey = env['AZURE_AI_FOUNDRY_KEY'] ?? '';
  final endpoint = env['AZURE_AI_FOUNDRY_ENDPOINT'] ?? '';
  final nanoDeployment = env['AZURE_GPT_5_NANO_DEPLOYMENT'] ?? 'gpt-5-nano';
  final chatDeployment = env['AZURE_GPT_5_CHAT_DEPLOYMENT'] ?? 'gpt-5.2-chat';

  print('Configuration:');
  print('   Endpoint: $endpoint');
  print('   API Key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "MISSING"}');
  print('   Nano: $nanoDeployment (cheap, 128k max output)');
  print('   Chat: $chatDeployment (quality, 16k max output)');

  if (apiKey.isEmpty || endpoint.isEmpty) {
    print('\nERROR: Missing API key or endpoint in .env');
    exit(1);
  }

  int passed = 0;
  int failed = 0;
  
  // Store generated content for saving to file/DB
  final generatedContent = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'date': DateTime.now().toIso8601String().split('T')[0],
  };

  // Test 1: Load mantras
  print('\n--- Test 1: Load Princeps_Mantras.md ---');
  final mantras = await testLoadMantras();
  if (mantras.isNotEmpty) {
    print('   ✓ Loaded ${mantras.length} mantras');
    generatedContent['mantrasLoaded'] = mantras.length;
    generatedContent['sampleMantras'] = mantras.take(5).toList();
    passed++;
  } else {
    print('   ✗ Failed to load mantras');
    failed++;
  }

  // Test 2: Load prime data
  print('\n--- Test 2: Load Princeps_Prime.md ---');
  final primeData = await testLoadPrime();
  if (primeData.isNotEmpty) {
    print('   ✓ Loaded Prime data');
    print('   Archetypes: ${primeData['archetypes']}');
    generatedContent['archetypes'] = primeData['archetypes'];
    generatedContent['mission'] = primeData['mission'];
    passed++;
  } else {
    print('   ✗ Failed to load prime data');
    failed++;
  }

  // Test 3: GPT-5 Nano (cheap, needs higher token limit)
  print('\n--- Test 3: GPT-5 Nano - Quick Affirmation ---');
  print('   Note: Nano needs 1000+ max_completion_tokens to work properly');
  final nanoAffirmation = await testGenerateContent(
    endpoint: endpoint,
    apiKey: apiKey,
    deployment: nanoDeployment,
    systemPrompt: 'You create powerful, personalized affirmations. Be concise.',
    userPrompt: _buildAffirmationPrompt(mantras.take(3).toList()),
    maxTokens: 1000, // Nano needs higher minimum
  );
  if (nanoAffirmation != null && nanoAffirmation.isNotEmpty) {
    print('   ✓ Nano affirmation: "$nanoAffirmation"');
    generatedContent['nanoAffirmation'] = nanoAffirmation;
    passed++;
  } else {
    print('   ✗ Nano failed (may need higher tokens or different prompt)');
    failed++;
  }

  // Test 4: GPT-5.2 Chat (quality)
  print('\n--- Test 4: GPT-5.2 Chat - Quality Affirmation ---');
  final chatAffirmation = await testGenerateContent(
    endpoint: endpoint,
    apiKey: apiKey,
    deployment: chatDeployment,
    systemPrompt: 'You create powerful, personalized affirmations. Be concise and empowering.',
    userPrompt: _buildAffirmationPrompt(mantras.take(5).toList()),
    maxTokens: 500, // Chat works with lower tokens
  );
  if (chatAffirmation != null && chatAffirmation.isNotEmpty) {
    print('   ✓ Chat affirmation: "$chatAffirmation"');
    generatedContent['chatAffirmation'] = chatAffirmation;
    passed++;
  } else {
    print('   ✗ Chat failed');
    failed++;
  }

  // Test 5: GPT-5.2 Chat - Meditation Script
  print('\n--- Test 5: GPT-5.2 Chat - Meditation Script ---');
  final meditationScript = await testGenerateContent(
    endpoint: endpoint,
    apiKey: apiKey,
    deployment: chatDeployment,
    systemPrompt: 'You are a wise meditation guide embodying Zen philosophy.',
    userPrompt: _buildMeditationPrompt(mantras, primeData),
    maxTokens: 2000, // Longer for meditation script
  );
  if (meditationScript != null && meditationScript.isNotEmpty) {
    print('   ✓ Generated meditation script (${meditationScript.length} chars)');
    print('   Preview: ${meditationScript.substring(0, meditationScript.length > 200 ? 200 : meditationScript.length)}...');
    generatedContent['meditationScript'] = meditationScript;
    passed++;
  } else {
    print('   ✗ Meditation script failed');
    failed++;
  }

  // Save generated content to JSON file
  print('\n--- Saving Content to File ---');
  try {
    final outputFile = File('data/generated/daily_content_${generatedContent['date']}.json');
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(generatedContent),
    );
    print('   ✓ Saved to: ${outputFile.path}');
    passed++;
  } catch (e) {
    print('   ✗ Failed to save: $e');
    failed++;
  }

  // Summary
  print('\n================================================================');
  print('                        TEST SUMMARY                            ');
  print('================================================================');
  print('  Passed: $passed / ${passed + failed}');
  print('  Failed: $failed');
  print('================================================================');

  // Print usage recommendations
  print('\n📋 Model Recommendations:');
  print('   • GPT-5 Nano: Use for simple tasks with max_tokens >= 1000');
  print('   • GPT-5.2 Chat: Use for quality content, works with 500+ tokens');
  print('   • For meditation scripts: Use Chat with 2000-4000 tokens');
  print('');

  exit(failed > 0 ? 1 : 0);
}

/// Parse .env file
Map<String, String> _parseEnvFile(String content) {
  final env = <String, String>{};
  for (final line in content.split('\n')) {
    if (line.contains('=') && !line.startsWith('#')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      var value = parts.sublist(1).join('=').trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }
  return env;
}

/// Build affirmation prompt
String _buildAffirmationPrompt(List<String> mantras) {
  final sampleMantras = mantras.map((m) => '- "$m"').join('\n');
  return '''
Create a single powerful affirmation based on these seed mantras:

$sampleMantras

Requirements:
- 1-2 sentences maximum
- First person ("I am...", "I...")
- Empowering, not forced

Return only the affirmation text, no quotes or explanation.
''';
}

/// Build meditation script prompt
String _buildMeditationPrompt(List<String> mantras, Map<String, dynamic> primeData) {
  final archetypes = primeData['archetypes'] as Map<String, dynamic>? ?? {};
  final sampleMantras = mantras.take(3).map((m) => '- "$m"').join('\n');
  final now = DateTime.now();
  final weekday = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][now.weekday % 7];

  return '''
Create a 5-minute guided meditation script.

Context:
- Date: $weekday, ${now.month}/${now.day}/${now.year}
- Weather: ☀️ Clear, peaceful day
- Dominant Archetype: ${archetypes['ego'] ?? 'Hero'} (action), ${archetypes['soul'] ?? 'Creator'} (expression)

Seed Mantras:
$sampleMantras

Structure:
1. Weather-aware greeting (1 paragraph)
2. Breath awareness (1 paragraph)
3. Brief visualization incorporating archetypes (2 paragraphs)
4. Closing affirmation (1 sentence)

Format: Pure spoken text. Use "..." for pauses. No markdown.
''';
}

/// Load and parse mantras from docs/Princeps_Mantras.md
Future<List<String>> testLoadMantras() async {
  try {
    final file = File('docs/Princeps_Mantras.md');
    if (!file.existsSync()) {
      print('   WARNING: docs/Princeps_Mantras.md not found');
      return [];
    }
    
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    final mantras = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('-') ||
          trimmed.contains('?')) {
        continue;
      }
      if (trimmed.startsWith('I ') ||
          trimmed.startsWith('My ') ||
          trimmed.startsWith('We ')) {
        mantras.add(trimmed);
      }
    }
    
    return mantras;
  } catch (e) {
    print('   ERROR: $e');
    return [];
  }
}

/// Load and parse prime data from docs/Princeps_Prime.md
Future<Map<String, dynamic>> testLoadPrime() async {
  try {
    final file = File('docs/Princeps_Prime.md');
    if (!file.existsSync()) {
      print('   WARNING: docs/Princeps_Prime.md not found');
      return {};
    }
    
    final content = file.readAsStringSync();
    
    return {
      'name': 'Princeps Polycap',
      'birthDate': 'June 18, 1996',
      'mission': 'To elevate the conscious awareness of the human race',
      'archetypes': {
        'ego': 'Hero',
        'soul': 'Creator',
        'self': 'Magician',
      },
      'hasContent': content.isNotEmpty,
    };
  } catch (e) {
    print('   ERROR: $e');
    return {};
  }
}

/// Generic content generation function
Future<String?> testGenerateContent({
  required String endpoint,
  required String apiKey,
  required String deployment,
  required String systemPrompt,
  required String userPrompt,
  required int maxTokens,
}) async {
  final uri = Uri.parse(
    '$endpoint/openai/deployments/$deployment/chat/completions?api-version=2025-01-01-preview',
  );

  final body = {
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ],
    'max_completion_tokens': maxTokens,
  };

  try {
    print('   Calling $deployment (max_tokens: $maxTokens)...');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'api-key': apiKey},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>;
        final content = message['content'] as String?;
        final finishReason = choices[0]['finish_reason'] as String?;
        
        if (finishReason == 'length' && (content?.isEmpty ?? true)) {
          print('   ⚠️ Token limit too low (finish_reason: length, empty content)');
          return null;
        }
        
        return content?.trim();
      }
    } else {
      print('   API Error: ${response.statusCode}');
      print('   ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    }
  } catch (e) {
    print('   ERROR: $e');
  }
  return null;
}
