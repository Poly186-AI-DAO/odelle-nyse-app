import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class DigitalWorkerChatState extends Equatable {
  const DigitalWorkerChatState();

  @override
  List<Object?> get props => [];
}

class DigitalWorkerChatInitial extends DigitalWorkerChatState {}

class DigitalWorkerChatLoading extends DigitalWorkerChatState {}

class DigitalWorkerChatConnecting extends DigitalWorkerChatState {
  final String message;

  const DigitalWorkerChatConnecting({required this.message});

  @override
  List<Object?> get props => [message];
}

class DigitalWorkerChatReady extends DigitalWorkerChatState {
  final String currentTranscript;
  final List<dynamic> messages;
  final bool isRecording;
  final bool isProcessing;
  final RTCVideoRenderer? webrtcRenderer;

  const DigitalWorkerChatReady({
    required this.currentTranscript,
    required this.messages,
    required this.isRecording,
    required this.isProcessing,
    this.webrtcRenderer,
  });

  DigitalWorkerChatReady copyWith({
    String? currentTranscript,
    List<dynamic>? messages,
    bool? isRecording,
    bool? isProcessing,
    RTCVideoRenderer? webrtcRenderer,
  }) {
    return DigitalWorkerChatReady(
      currentTranscript: currentTranscript ?? this.currentTranscript,
      messages: messages ?? this.messages,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      webrtcRenderer: webrtcRenderer ?? this.webrtcRenderer,
    );
  }

  @override
  List<Object?> get props => [
        currentTranscript,
        messages,
        isRecording,
        isProcessing,
        webrtcRenderer,
      ];
}

class DigitalWorkerChatError extends DigitalWorkerChatState {
  final String message;

  const DigitalWorkerChatError(this.message);

  @override
  List<Object?> get props => [message];
}
