// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ElevenLabs TTS API Test
/// Run with: dart run test/elevenlabs_test.dart
void main() async {
  print('================================================================');
  print('           ELEVENLABS TTS API - TEST                            ');
  print('================================================================\n');

  // Read .env file
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERROR: .env file not found');
    exit(1);
  }

  final envContent = envFile.readAsStringSync();
  final env = <String, String>{};
  for (final line in envContent.split('\n')) {
    if (line.contains('=') && !line.startsWith('#')) {
      final parts = line.split('=');
      final key = parts[0].trim();
      var value = parts.sublist(1).join('=').trim();
      // Remove surrounding quotes if present
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }

  final apiKey = env['ELEVENLABS_API_KEY'] ?? '';

  print('Configuration:');
  print('   API Key: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 8)}..." : "MISSING"}');
  print('');

  if (apiKey.isEmpty) {
    print('ERROR: Missing ELEVENLABS_API_KEY in .env');
    print('');
    print('To obtain an API key:');
    print('  1. Go to https://elevenlabs.io');
    print('  2. Sign up or log in');
    print('  3. Navigate to Profile > API Keys');
    print('  4. Create a new API key');
    print('  5. Add to .env: ELEVENLABS_API_KEY=your_key_here');
    exit(1);
  }

  int passed = 0;
  int failed = 0;

  // Test 1: List available voices
  print('\n----------------------------------------------------------------');
  print(' Test 1: List Available Voices                                  ');
  print('----------------------------------------------------------------');
  if (await testListVoices(apiKey)) {
    passed++;
  } else {
    failed++;
  }

  // Test 2: List available models
  print('\n----------------------------------------------------------------');
  print(' Test 2: List Available Models                                  ');
  print('----------------------------------------------------------------');
  if (await testListModels(apiKey)) {
    passed++;
  } else {
    failed++;
  }

  // Test 3: Text-to-Speech generation
  print('\n----------------------------------------------------------------');
  print(' Test 3: Text-to-Speech Generation                              ');
  print('----------------------------------------------------------------');
  if (await testTextToSpeech(apiKey)) {
    passed++;
  } else {
    failed++;
  }

  // Test 4: Get subscription info (quota usage)
  print('\n----------------------------------------------------------------');
  print(' Test 4: Subscription Info (Quota)                              ');
  print('----------------------------------------------------------------');
  if (await testSubscriptionInfo(apiKey)) {
    passed++;
  } else {
    failed++;
  }

  // Summary
  print('\n================================================================');
  print('                        TEST SUMMARY                            ');
  print('================================================================');
  print('  Passed: $passed');
  print('  Failed: $failed');
  print('================================================================');

  exit(failed > 0 ? 1 : 0);
}

/// Test 1: List available voices
Future<bool> testListVoices(String apiKey) async {
  const baseUrl = 'https://api.elevenlabs.io/v1';
  final uri = Uri.parse('$baseUrl/voices');

  // Specific voice IDs to check
  final targetVoiceIds = {
    'UmQN7jS1Ee8B1czsUtQh', // Theo Silk?
    'AiJZqQzutCDRG8cUOJwK', // Calm Lady
    'Wuv1s5YTNCjL9mFJTqo4a',
    'pjcYQlDFKMbcOUp6F5GD',
    'goT3UYdM9bhm0n2lmKQx',
  };

  print('   Fetching voices...');

  try {
    final response = await http.get(
      uri,
      headers: {'xi-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final voices = json['voices'] as List;

      print('   SUCCESS - Found ${voices.length} voices');
      print('');
      print('   Target Voices found:');
      
      for (final v in voices) {
        final voice = v as Map<String, dynamic>;
        final id = voice['voice_id'] as String;
        
        if (targetVoiceIds.contains(id)) {
          print('     - Name: ${voice['name']}');
          print('       ID: $id');
          print('       Category: ${voice['category']}');
          print('       Labels: ${voice['labels']}');
          print('       Description: ${voice['description']}');
          print('');
        }
      }
      return true;
    } else {
      print('   FAILED: ${response.statusCode}');
      print('   ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ERROR: $e');
    return false;
  }
}

/// Test 2: List available models
Future<bool> testListModels(String apiKey) async {
  const baseUrl = 'https://api.elevenlabs.io/v1';
  final uri = Uri.parse('$baseUrl/models');

  print('   Fetching models...');

  try {
    final response = await http.get(
      uri,
      headers: {'xi-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final models = jsonDecode(response.body) as List;

      print('   SUCCESS - Found ${models.length} models');
      print('');
      print('   Available models:');
      for (final model in models) {
        final m = model as Map<String, dynamic>;
        final canTts = m['can_do_text_to_speech'] ?? false;
        final langs = (m['languages'] as List?)?.length ?? 0;
        print('     - ${m['model_id']}');
        print('       Name: ${m['name']}');
        print('       TTS: $canTts, Languages: $langs');
      }
      return true;
    } else {
      print('   FAILED: ${response.statusCode}');
      print('   ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ERROR: $e');
    return false;
  }
}

/// Test 3: Text-to-Speech generation
Future<bool> testTextToSpeech(String apiKey) async {
  const baseUrl = 'https://api.elevenlabs.io/v1';
  
  // Using a default voice ID (Rachel - good for testing)
  // You can get voice IDs from the /voices endpoint
  const voiceId = 'EXAVITQu4vr4xnSDxMaL'; // Bella - warm, calm
  
  final uri = Uri.parse('$baseUrl/text-to-speech/$voiceId?output_format=mp3_22050_32');

  final body = {
    'text': 'Hello! This is a test of the ElevenLabs text to speech API. '
        'I am speaking clearly and calmly.',
    'model_id': 'eleven_flash_v2_5', // Fast, affordable model
    'voice_settings': {
      'stability': 0.75,
      'similarity_boost': 0.75,
      'style': 0.35,
      'use_speaker_boost': true,
    },
  };

  print('   Voice ID: $voiceId');
  print('   Model: eleven_flash_v2_5');
  print('   Generating speech...');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': apiKey,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Response is raw audio bytes
      final audioBytes = response.bodyBytes;
      final sizeKb = (audioBytes.length / 1024).toStringAsFixed(1);
      
      // Save audio for verification
      final outputFile = File('test/output/elevenlabs_test.mp3');
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(audioBytes);
      
      print('   SUCCESS - Generated ${sizeKb}KB audio');
      print('   Saved to: test/output/elevenlabs_test.mp3');
      print('');
      print('   To play: open test/output/elevenlabs_test.mp3');
      return true;
    } else {
      print('   FAILED: ${response.statusCode}');
      print('   ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ERROR: $e');
    return false;
  }
}

/// Test 4: Get subscription info (quota usage)
Future<bool> testSubscriptionInfo(String apiKey) async {
  const baseUrl = 'https://api.elevenlabs.io/v1';
  final uri = Uri.parse('$baseUrl/user/subscription');

  print('   Fetching subscription info...');

  try {
    final response = await http.get(
      uri,
      headers: {'xi-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      final tier = json['tier'] ?? 'unknown';
      final charLimit = json['character_limit'] ?? 0;
      final charUsed = json['character_count'] ?? 0;
      final charRemaining = charLimit - charUsed;
      final nextReset = json['next_character_count_reset_unix'] as int?;
      
      print('   SUCCESS');
      print('');
      print('   Subscription Tier: $tier');
      print('   Character Limit:   $charLimit');
      print('   Characters Used:   $charUsed');
      print('   Characters Left:   $charRemaining');
      if (nextReset != null) {
        final resetDate = DateTime.fromMillisecondsSinceEpoch(nextReset * 1000);
        print('   Resets: ${resetDate.toLocal()}');
      }
      
      // Warning if low on quota
      if (charRemaining < 1000) {
        print('');
        print('   ⚠️  WARNING: Low character quota remaining!');
      }
      
      return true;
    } else {
      print('   FAILED: ${response.statusCode}');
      print('   ${response.body}');
      return false;
    }
  } catch (e) {
    print('   ERROR: $e');
    return false;
  }
}
