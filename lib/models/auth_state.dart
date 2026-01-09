enum AuthStatus {
  idle, // Initial/logged out state
  initializing, // During setup
  ready, // Setup complete, not authenticated
  authenticating, // During login
  authenticated, // Logged in
  error // Any error state
}

class NetworkInfo {
  final String blockNumber;
  final String gasPrice;
  final String transactionCount;

  NetworkInfo({
    required this.blockNumber,
    required this.gasPrice,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() => {
        'blockNumber': blockNumber,
        'gasPrice': gasPrice,
        'transactionCount': transactionCount,
      };

  factory NetworkInfo.fromJson(Map<String, dynamic> json) => NetworkInfo(
        blockNumber: json['blockNumber'] as String,
        gasPrice: json['gasPrice'] as String,
        transactionCount: json['transactionCount'] as String,
      );
}

class AuthenticationError implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AuthenticationError(this.message, this.code, {this.originalError});

  @override
  String toString() => 'AuthenticationError: $message (Code: $code)';
}
