import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../utils/logger.dart';

/// Image size options for FLUX.2-pro
enum ImageSize {
  square('1024x1024'),
  portrait('1024x1536'),
  landscape('1536x1024');

  final String value;
  const ImageSize(this.value);

  /// Parse width and height from size string
  (int width, int height) get dimensions {
    final parts = value.split('x');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}

/// Result of image generation
class ImageGenerationResult {
  /// Base64 encoded image data (with data URL prefix)
  final String imageData;

  /// Raw bytes of the image
  final Uint8List bytes;

  /// The prompt that was used (may be revised by the model)
  final String prompt;

  /// Image dimensions
  final int width;
  final int height;

  /// Generation metadata
  final String model;
  final DateTime generatedAt;

  const ImageGenerationResult({
    required this.imageData,
    required this.bytes,
    required this.prompt,
    required this.width,
    required this.height,
    required this.model,
    required this.generatedAt,
  });

  /// Get image as data URL for display
  String get dataUrl => imageData.startsWith('data:')
      ? imageData
      : 'data:image/png;base64,$imageData';
}

/// Azure AI Foundry Image Generation Service
///
/// Supports FLUX.2-pro model via Black Forest Labs API.
/// Runs on-device, calling Azure directly.
///
/// Features:
/// - Text-to-image generation
/// - Multiple size options (1024x1024, 1024x1536, 1536x1024)
/// - 4MP output quality
/// - Production-grade results
///
/// Usage:
/// ```dart
/// final imageService = AzureImageService();
/// final result = await imageService.generateImage(
///   prompt: 'A beautiful sunset over mountains',
///   size: ImageSize.landscape,
/// );
/// // Use result.dataUrl for Image widget
/// // Use result.bytes to save to file
/// ```
class AzureImageService {
  static const String _tag = 'AzureImageService';

  final http.Client _client;
  late final String _apiKey;
  late final String _endpoint;
  late final String _model;
  bool _isInitialized = false;

  AzureImageService({http.Client? client}) : _client = client ?? http.Client() {
    _initialize();
  }

  void _initialize() {
    // FLUX.2-pro uses separate key/endpoint from chat models
    _apiKey = dotenv.env['FLUX_2_PRO_KEY'] ??
        dotenv.env['AZURE_AI_FOUNDRY_KEY'] ??
        '';
    _endpoint = dotenv.env['FLUX_2_PRO_AZURE_URL'] ?? '';
    _model = dotenv.env['FLUX_2_PRO_DEPLOYMENT'] ?? 'FLUX.2-pro';

    if (_apiKey.isEmpty || _endpoint.isEmpty) {
      Logger.error(
        'FLUX.2-pro API key or endpoint not found in environment',
        tag: _tag,
      );
      return;
    }

    Logger.info('Azure Image Service initialized', tag: _tag);
    Logger.debug('Model: $_model', tag: _tag);
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  /// Generate an image from a text prompt
  ///
  /// [prompt] - Text description of the image to generate
  /// [size] - Image dimensions (default: 1024x1024)
  ///
  /// Returns [ImageGenerationResult] with the generated image data
  Future<ImageGenerationResult> generateImage({
    required String prompt,
    ImageSize size = ImageSize.square,
  }) async {
    if (!_isInitialized) {
      throw StateError('AzureImageService not initialized');
    }

    // Build URL with api-version query param
    final baseUrl = _endpoint.endsWith('/')
        ? _endpoint.substring(0, _endpoint.length - 1)
        : _endpoint;
    final uri = Uri.parse('$baseUrl?api-version=preview');

    // FLUX.2-pro API payload
    final body = {
      'prompt': prompt,
      'model': _model.toLowerCase(), // API expects lowercase
      'n': 1,
      'size': size.value,
    };

    Logger.info('Generating image with FLUX.2-pro', tag: _tag);
    Logger.debug(
        'Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...',
        tag: _tag);
    Logger.debug('Size: ${size.value}', tag: _tag);

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // FLUX.2-pro uses Api-Key header (capital A and K)
          'Api-Key': _apiKey,
        },
        body: jsonEncode(body),
      );

      Logger.debug('Response status: ${response.statusCode}', tag: _tag);

      if (response.statusCode != 200) {
        Logger.error(
          'Image generation failed',
          tag: _tag,
          data: {'status': response.statusCode, 'body': response.body},
        );
        throw Exception(
          'Image generation failed: ${response.statusCode} - ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseResponse(json, prompt, size);
    } catch (e, stackTrace) {
      Logger.error('Image generation error: $e', tag: _tag, data: {
        'stackTrace': stackTrace.toString(),
      });
      rethrow;
    }
  }

  /// Parse the API response into ImageGenerationResult
  ImageGenerationResult _parseResponse(
    Map<String, dynamic> json,
    String prompt,
    ImageSize size,
  ) {
    String? base64Data;

    // Try different response formats
    if (json.containsKey('data') && (json['data'] as List).isNotEmpty) {
      final imageData = (json['data'] as List).first as Map<String, dynamic>;

      // Try b64_json first (most common)
      if (imageData.containsKey('b64_json')) {
        base64Data = imageData['b64_json'] as String;
      }
      // Try base64
      else if (imageData.containsKey('base64')) {
        base64Data = imageData['base64'] as String;
      }
      // Try image
      else if (imageData.containsKey('image')) {
        base64Data = imageData['image'] as String;
      }
      // Try url - would need to fetch
      else if (imageData.containsKey('url')) {
        throw UnimplementedError(
          'URL-based response not yet supported. Got URL: ${imageData['url']}',
        );
      }
    }
    // Try direct image field (alternate format)
    else if (json.containsKey('image')) {
      base64Data = json['image'] as String;
    }

    if (base64Data == null) {
      Logger.error('No image data in response', tag: _tag, data: json);
      throw Exception('No image data found in response: ${json.keys}');
    }

    // Ensure we have raw base64 (strip data URL prefix if present)
    if (base64Data.startsWith('data:')) {
      base64Data = base64Data.split(',').last;
    }

    final bytes = base64Decode(base64Data);
    final dims = size.dimensions;

    Logger.info('Image generated successfully', tag: _tag, data: {
      'size': '${dims.$1}x${dims.$2}',
      'bytes': bytes.length,
    });

    return ImageGenerationResult(
      imageData: 'data:image/png;base64,$base64Data',
      bytes: bytes,
      prompt: prompt,
      width: dims.$1,
      height: dims.$2,
      model: _model,
      generatedAt: DateTime.now(),
    );
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
