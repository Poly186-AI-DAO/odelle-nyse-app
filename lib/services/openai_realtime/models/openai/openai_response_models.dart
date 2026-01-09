export './audio_transcription_models.dart';
export './base_models.dart';
export './conversation_event_models.dart';
export './token_models.dart';

import './base_models.dart';
import './token_models.dart';

/// Represents an OpenAI realtime response
class OpenAIResponse {
  final String id;
  final String object;
  final String status;
  final Map<String, dynamic>? statusDetails;
  final List<MessageItem> output;
  final Usage? usage;

  OpenAIResponse({
    required this.id,
    required this.object,
    required this.status,
    this.statusDetails,
    required this.output,
    this.usage,
  });

  factory OpenAIResponse.fromJson(Map<String, dynamic> json) {
    return OpenAIResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      status: json['status'] as String,
      statusDetails: json['status_details'] != null
          ? Map<String, dynamic>.from(json['status_details'] as Map)
          : null,
      output: (json['output'] as List<dynamic>)
          .map((e) => MessageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }
}
