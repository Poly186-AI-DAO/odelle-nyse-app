import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Comprehensive test for Azure AI Services
/// Run with: dart run test/new_azure_agent_test.dart
void main() async {
  print('================================================================');
  print('          AZURE AI SERVICES - COMPREHENSIVE TEST                ');
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
      // Handle values that might contain = or quotes
      var value = parts.sublist(1).join('=').trim();
      // Remove surrounding quotes if present
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      env[key] = value;
    }
  }

  // Chat API config
  final chatApiKey = env['AZURE_AI_FOUNDRY_KEY'] ?? '';
  final chatEndpoint = env['AZURE_AI_FOUNDRY_ENDPOINT'] ?? '';

  // Image API config (FLUX.2-pro)
  final imageApiKey = env['FLUX_2_PRO_KEY'] ?? chatApiKey;
  final imageEndpoint = env['FLUX_2_PRO_AZURE_URL'] ?? '';
  final imageModel = env['FLUX_2_PRO_DEPLOYMENT'] ?? 'FLUX.2-pro';

  print('Configuration:');
  print('   Chat Endpoint: $chatEndpoint');
  print(
      '   Chat API Key: ${chatApiKey.isNotEmpty ? chatApiKey.substring(0, 8) + "..." : "MISSING"}');
  print('   Image Endpoint: $imageEndpoint');
  print('   Image Model: $imageModel');
  print('');

  if (chatApiKey.isEmpty || chatEndpoint.isEmpty) {
    print('ERROR: Missing chat API key or endpoint in .env');
    exit(1);
  }

  int passed = 0;
  int failed = 0;

  // Test 1: Simple chat with GPT-5.2-chat
  print('----------------------------------------------------------------');
  print(' Test 1: Simple Chat Completion (GPT-5.2-chat)                  ');
  print('----------------------------------------------------------------');
  if (await testSimpleChat(chatEndpoint, chatApiKey, 'gpt-5.2-chat')) {
    passed++;
  } else {
    failed++;
  }

  // Test 2: Tool calling with GPT-5.2-chat
  print('\n----------------------------------------------------------------');
  print(' Test 2: Tool/Function Calling (GPT-5.2-chat)                   ');
  print('----------------------------------------------------------------');
  if (await testToolCalling(chatEndpoint, chatApiKey, 'gpt-5.2-chat')) {
    passed++;
  } else {
    failed++;
  }

  // Test 3: Agent loop with tool execution
  print('\n----------------------------------------------------------------');
  print(' Test 3: Agent Loop with Tool Execution                         ');
  print('----------------------------------------------------------------');
  if (await testAgentLoop(chatEndpoint, chatApiKey, 'gpt-5.2-chat')) {
    passed++;
  } else {
    failed++;
  }

  // Test 4: Image generation with FLUX.2-pro
  print('\n----------------------------------------------------------------');
  print(' Test 4: Image Generation (FLUX.2-pro)                          ');
  print('----------------------------------------------------------------');
  if (imageEndpoint.isEmpty) {
    print('   SKIPPED: FLUX_2_PRO_AZURE_URL not configured');
  } else if (await testImageGeneration(
      imageEndpoint, imageApiKey, imageModel)) {
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

Future<bool> testSimpleChat(
    String endpoint, String apiKey, String deployment) async {
  final uri = Uri.parse(
    '$endpoint/openai/deployments/$deployment/chat/completions?api-version=2025-01-01-preview',
  );

  final body = {
    'messages': [
      {'role': 'system', 'content': 'You are a helpful assistant. Be concise.'},
      {'role': 'user', 'content': 'What is 2+2? Reply with just the number.'},
    ],
    'max_completion_tokens': 100,
  };

  print('   Sending request...');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'api-key': apiKey},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['choices'][0]['message']['content'] as String?;
      final tokens = json['usage']['total_tokens'] as int?;
      print('   SUCCESS');
      print('   Response: ${message ?? "(empty)"}');
      print('   Tokens used: $tokens');
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

Future<bool> testToolCalling(
    String endpoint, String apiKey, String deployment) async {
  final uri = Uri.parse(
    '$endpoint/openai/deployments/$deployment/chat/completions?api-version=2025-01-01-preview',
  );

  final body = {
    'messages': [
      {'role': 'user', 'content': 'What is the weather in San Francisco?'},
    ],
    'tools': [
      {
        'type': 'function',
        'function': {
          'name': 'get_weather',
          'description': 'Get current weather for a city',
          'parameters': {
            'type': 'object',
            'properties': {
              'city': {'type': 'string', 'description': 'City name'},
            },
            'required': ['city'],
          },
        },
      },
    ],
    'max_completion_tokens': 200,
  };

  print('   Sending request with tools...');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'api-key': apiKey},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['choices'][0]['message'] as Map<String, dynamic>;
      final toolCalls = message['tool_calls'] as List?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        final call = toolCalls[0];
        final funcName = call['function']['name'];
        final args = call['function']['arguments'];
        print('   SUCCESS - Model requested tool call');
        print('   Tool: $funcName');
        print('   Arguments: $args');
        return true;
      } else {
        print('   WARNING: Model responded without tool call');
        print('   Content: ${message['content']}');
        return false;
      }
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

/// Test 3: Full agent loop with tool execution
Future<bool> testAgentLoop(
    String endpoint, String apiKey, String deployment) async {
  final uri = Uri.parse(
    '$endpoint/openai/deployments/$deployment/chat/completions?api-version=2025-01-01-preview',
  );

  // Define tools
  final tools = [
    {
      'type': 'function',
      'function': {
        'name': 'log_workout',
        'description': 'Log a workout to the fitness tracker',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'description': 'Type of workout (running, weights, yoga, etc.)'
            },
            'duration_minutes': {
              'type': 'integer',
              'description': 'Duration in minutes'
            },
            'calories': {
              'type': 'integer',
              'description': 'Estimated calories burned'
            },
          },
          'required': ['type', 'duration_minutes'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_workout_stats',
        'description': 'Get workout statistics for a time period',
        'parameters': {
          'type': 'object',
          'properties': {
            'period': {
              'type': 'string',
              'enum': ['today', 'week', 'month'],
              'description': 'Time period for stats'
            },
          },
          'required': ['period'],
        },
      },
    },
  ];

  // Simulated tool executor
  String executeToolCall(String name, Map<String, dynamic> args) {
    switch (name) {
      case 'log_workout':
        return jsonEncode({
          'success': true,
          'message':
              'Logged ${args['type']} workout for ${args['duration_minutes']} minutes',
          'workout_id': 'wkt_12345',
        });
      case 'get_workout_stats':
        return jsonEncode({
          'period': args['period'],
          'total_workouts': 5,
          'total_minutes': 180,
          'total_calories': 850,
        });
      default:
        return jsonEncode({'error': 'Unknown tool'});
    }
  }

  print('   Starting agent loop...');
  print('   User: "I just did a 30 minute run and burned about 300 calories"');

  // Initial message
  var messages = <Map<String, dynamic>>[
    {
      'role': 'system',
      'content':
          'You are a fitness assistant. Use the available tools to help users track their workouts.'
    },
    {
      'role': 'user',
      'content':
          'I just did a 30 minute run and burned about 300 calories. Log it for me.'
    },
  ];

  try {
    // First request
    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'api-key': apiKey},
      body: jsonEncode({
        'messages': messages,
        'tools': tools,
        'max_completion_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      print('   FAILED: ${response.statusCode}');
      return false;
    }

    var json = jsonDecode(response.body) as Map<String, dynamic>;
    var assistantMessage =
        json['choices'][0]['message'] as Map<String, dynamic>;
    var toolCalls = assistantMessage['tool_calls'] as List?;

    if (toolCalls == null || toolCalls.isEmpty) {
      print('   WARNING: No tool calls made');
      print('   Response: ${assistantMessage['content']}');
      return false;
    }

    print('   -> Model called tool: ${toolCalls[0]['function']['name']}');

    // Add assistant message and tool results to history
    messages.add(assistantMessage);

    for (final call in toolCalls) {
      final toolName = call['function']['name'] as String;
      final toolArgs = jsonDecode(call['function']['arguments'] as String)
          as Map<String, dynamic>;
      final toolResult = executeToolCall(toolName, toolArgs);

      print('   -> Executed: $toolName(${jsonEncode(toolArgs)})');
      print('   -> Result: $toolResult');

      messages.add({
        'role': 'tool',
        'tool_call_id': call['id'],
        'content': toolResult,
      });
    }

    // Second request with tool results
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', 'api-key': apiKey},
      body: jsonEncode({
        'messages': messages,
        'tools': tools,
        'max_completion_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      print('   FAILED on follow-up: ${response.statusCode}');
      return false;
    }

    json = jsonDecode(response.body) as Map<String, dynamic>;
    final finalMessage = json['choices'][0]['message']['content'] as String?;

    print('   SUCCESS - Agent loop completed');
    print('   Final response: ${finalMessage ?? "(empty)"}');
    return true;
  } catch (e) {
    print('   ERROR: $e');
    return false;
  }
}

/// Test 4: Image generation with FLUX.2-pro
Future<bool> testImageGeneration(
    String endpoint, String apiKey, String model) async {
  // Build URL with api-version query param
  final baseUrl = endpoint.endsWith('/')
      ? endpoint.substring(0, endpoint.length - 1)
      : endpoint;
  final uri = Uri.parse('$baseUrl?api-version=preview');

  final body = {
    'prompt':
        'A beautiful sunset over mountains with vibrant orange and purple colors, photorealistic, 8k quality',
    'model': model.toLowerCase(),
    'n': 1,
    'size': '1024x1024',
  };

  print('   Endpoint: $uri');
  print('   Model: $model');
  print('   Sending image generation request...');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Api-Key': apiKey, // FLUX uses Api-Key (capital A and K)
      },
      body: jsonEncode(body),
    );

    print('   Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Try to find image data in response
      String? base64Data;
      if (json.containsKey('data') && (json['data'] as List).isNotEmpty) {
        final imageData = (json['data'] as List).first as Map<String, dynamic>;
        base64Data = imageData['b64_json'] as String? ??
            imageData['base64'] as String? ??
            imageData['image'] as String?;

        if (base64Data != null) {
          // Calculate size
          final sizeKb = (base64Data.length * 0.75 / 1024).round();
          print('   SUCCESS - Image generated');
          print('   Image size: ~${sizeKb}KB');
          print('   Response keys: ${imageData.keys.toList()}');
          return true;
        }
      } else if (json.containsKey('image')) {
        base64Data = json['image'] as String;
        final sizeKb = (base64Data.length * 0.75 / 1024).round();
        print('   SUCCESS - Image generated (direct format)');
        print('   Image size: ~${sizeKb}KB');
        return true;
      }

      print('   No image data in response');
      print('   Response keys: ${json.keys.toList()}');
      return false;
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
