/// Represents token usage details for input and output
class TokenDetails {
  final int textTokens;
  final int audioTokens;

  TokenDetails({
    required this.textTokens,
    required this.audioTokens,
  });

  factory TokenDetails.fromJson(Map<String, dynamic> json) {
    return TokenDetails(
      textTokens: json['text_tokens'] as int,
      audioTokens: json['audio_tokens'] as int,
    );
  }
}

/// Represents cached token details
class CachedTokenDetails {
  final int textTokens;
  final int audioTokens;

  CachedTokenDetails({
    required this.textTokens,
    required this.audioTokens,
  });

  factory CachedTokenDetails.fromJson(Map<String, dynamic> json) {
    return CachedTokenDetails(
      textTokens: json['text_tokens'] as int,
      audioTokens: json['audio_tokens'] as int,
    );
  }
}

/// Represents input token usage details
class InputTokenDetails {
  final int cachedTokens;
  final int textTokens;
  final int audioTokens;
  final CachedTokenDetails cachedTokensDetails;

  InputTokenDetails({
    required this.cachedTokens,
    required this.textTokens,
    required this.audioTokens,
    required this.cachedTokensDetails,
  });

  factory InputTokenDetails.fromJson(Map<String, dynamic> json) {
    return InputTokenDetails(
      cachedTokens: json['cached_tokens'] as int,
      textTokens: json['text_tokens'] as int,
      audioTokens: json['audio_tokens'] as int,
      cachedTokensDetails: CachedTokenDetails.fromJson(
        json['cached_tokens_details'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Represents token usage statistics
class Usage {
  final int totalTokens;
  final int inputTokens;
  final int outputTokens;
  final InputTokenDetails inputTokenDetails;
  final TokenDetails outputTokenDetails;

  Usage({
    required this.totalTokens,
    required this.inputTokens,
    required this.outputTokens,
    required this.inputTokenDetails,
    required this.outputTokenDetails,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      totalTokens: json['total_tokens'] as int,
      inputTokens: json['input_tokens'] as int,
      outputTokens: json['output_tokens'] as int,
      inputTokenDetails: InputTokenDetails.fromJson(
        json['input_token_details'] as Map<String, dynamic>,
      ),
      outputTokenDetails: TokenDetails.fromJson(
        json['output_token_details'] as Map<String, dynamic>,
      ),
    );
  }
}
