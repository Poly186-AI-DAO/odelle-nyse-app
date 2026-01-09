import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../config/digital_worker_config.dart';

/// Represents the current state of the WebRTC connection
enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

/// Type definition for handling WebRTC messages
typedef MessageHandler = void Function(Map<String, dynamic> message);

/// Type definition for handling WebRTC audio streams
typedef AudioStreamHandler = void Function(MediaStream stream);

/// Type definition for handling connection state changes
typedef ConnectionStateHandler = void Function(WebRTCConnectionState state);

/// Type definition for handling errors
typedef ErrorHandler = void Function(String error);

/// Type definition for handling session events
typedef VoidCallback = void Function();

/// Base service that manages core WebRTC functionality.
///
/// This service handles the fundamental WebRTC operations:
/// - Establishing and managing peer connections
/// - Setting up data channels
/// - Managing audio streams
/// - Connection state management
class BaseWebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  AudioStreamHandler? onRemoteStreamReceived;
  MessageHandler? onMessage;
  ConnectionStateHandler? onConnectionStateChange;
  ErrorHandler? onError;
  VoidCallback? onSessionStarted;
  VoidCallback? onSessionEnded;
  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;
  bool _isSessionActive = false;

  // Web-specific renderer for audio playback
  RTCVideoRenderer? _webRenderer;

  // Protected getters and setters for subclasses
  @protected
  RTCPeerConnection? get peerConnection => _peerConnection;

  @protected
  set peerConnection(RTCPeerConnection? value) => _peerConnection = value;

  @protected
  RTCDataChannel? get dataChannel => _dataChannel;

  @protected
  set dataChannel(RTCDataChannel? value) => _dataChannel = value;

  @protected
  MediaStream? get localStream => _localStream;

  @protected
  set localStream(MediaStream? value) => _localStream = value;

  /// Gets the web-specific renderer for audio playback
  RTCVideoRenderer? get webRenderer => kIsWeb ? _webRenderer : null;

  WebRTCConnectionState get connectionState => _connectionState;
  bool get isSessionActive => _isSessionActive;

  bool get isConnected =>
      _connectionState == WebRTCConnectionState.connected &&
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  /// Initializes the WebRTC service with default configuration.
  ///
  /// This is the main initialization method that subclasses must implement.
  /// It sets up the service with the given modalities and instructions.
  ///
  /// [modalities] specifies the communication modes (e.g., audio, text)
  /// [instructions] provides initial setup instructions
  /// Initializes the web renderer for audio playback on web platforms
  @protected
  Future<void> initializeWebRenderer() async {
    if (kIsWeb) {
      _webRenderer = RTCVideoRenderer();
      await _webRenderer!.initialize();
    }
  }

  Future<void> initialize({
    required DigitalWorkerConfig config,
  }) async {
    throw UnimplementedError('Subclasses must implement initialize()');
  }

  /// Explicitly starts a new WebRTC session
  Future<void> startSession() async {
    if (_isSessionActive) {
      throw Exception('Session is already active');
    }

    _isSessionActive = true;
    if (_connectionState == WebRTCConnectionState.connected) {
      onSessionStarted?.call();
    }
  }

  /// Explicitly ends the current WebRTC session
  Future<void> endSession() async {
    if (!_isSessionActive) return;

    try {
      // Update state first to prevent any new events from being sent
      _connectionState = WebRTCConnectionState.disconnected;
      onConnectionStateChange?.call(_connectionState);

      // Close data channel first to ensure clean shutdown
      if (_dataChannel != null) {
        try {
          await _dataChannel!.close();
        } catch (e) {
          print('Error closing data channel: $e');
        } finally {
          _dataChannel = null;
        }
      }

      // Close peer connection
      if (_peerConnection != null) {
        try {
          await _peerConnection!.close();
        } catch (e) {
          print('Error closing peer connection: $e');
        } finally {
          _peerConnection = null;
        }
      }

      // Dispose media stream
      if (_localStream != null) {
        try {
          await _localStream!.dispose();
        } catch (e) {
          print('Error disposing media stream: $e');
        } finally {
          _localStream = null;
        }
      }

      // Clean up web renderer
      if (kIsWeb && _webRenderer != null) {
        try {
          await _webRenderer!.dispose();
        } catch (e) {
          print('Error disposing web renderer: $e');
        } finally {
          _webRenderer = null;
        }
      }

      _isSessionActive = false;
      onSessionEnded?.call();
    } catch (e) {
      onError?.call('Error ending session: $e');
      // Don't rethrow - ensure session is marked as ended
      _isSessionActive = false;
      onSessionEnded?.call();
    }
  }

  /// Initializes the WebRTC connection with the given configuration.
  ///
  /// This method handles the low-level WebRTC setup:
  /// - Creates and configures the peer connection
  /// - Sets up audio streams
  /// - Establishes the data channel
  /// - Configures state monitoring
  ///
  /// [configuration] The WebRTC configuration object (e.g., ICE servers)
  /// [offer] The SDP offer for the connection
  Future<void> initializeConnection(
    Map<String, dynamic> configuration,
    RTCSessionDescription offer,
  ) async {
    try {
      _connectionState = WebRTCConnectionState.connecting;
      onConnectionStateChange?.call(_connectionState);

      // Create peer connection
      _peerConnection = await createPeerConnection(configuration);

      // Set up remote audio stream handling
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          if (kIsWeb && _webRenderer != null) {
            // For web, attach stream to renderer (audio only)
            _webRenderer!.srcObject = event.streams[0];
          }
          onRemoteStreamReceived?.call(event.streams[0]);
        }
      };

      // Set up local audio stream with web-specific handling
      Map<String, dynamic> mediaConstraints = {
        'audio': kIsWeb
            ? {
                'echoCancellation': true,
                'noiseSuppression': true,
                'autoGainControl': true,
                'sampleRate': 48000,
                'channelCount': 1
              }
            : true,
        'video': false
      };

      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Set up connection state monitoring
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _connectionState = WebRTCConnectionState.connected;
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _connectionState = WebRTCConnectionState.failed;
            onError?.call('WebRTC connection failed');
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            _connectionState = WebRTCConnectionState.disconnected;
            break;
          default:
            break;
        }
        onConnectionStateChange?.call(_connectionState);
      };

      // Create data channel
      _dataChannel = await _peerConnection!
          .createDataChannel('events', RTCDataChannelInit());

      _dataChannel!.onMessage = (RTCDataChannelMessage message) {
        try {
          final data = jsonDecode(message.text);
          onMessage?.call(data);
        } catch (e) {
          onError?.call('Failed to parse message: $e');
        }
      };

      _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _connectionState = WebRTCConnectionState.connected;
          onConnectionStateChange?.call(_connectionState);
          if (_isSessionActive) {
            onSessionStarted?.call();
          }
        } else if (state == RTCDataChannelState.RTCDataChannelClosed ||
            state == RTCDataChannelState.RTCDataChannelClosing) {
          _connectionState = WebRTCConnectionState.disconnected;
          onConnectionStateChange?.call(_connectionState);
          if (_isSessionActive) {
            _isSessionActive = false;
            onSessionEnded?.call();
          }
        }
      };

      // Set local description
      await _peerConnection!.setLocalDescription(offer);
    } catch (e) {
      _connectionState = WebRTCConnectionState.failed;
      onConnectionStateChange?.call(_connectionState);
      onError?.call('WebRTC initialization error: $e');
      rethrow;
    }
  }

  /// Sets the remote description for the peer connection
  Future<void> setRemoteDescription(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  /// Checks if the service is ready to send events
  bool isReadyToSendEvents() {
    return isConnected && _dataChannel != null;
  }

  /// Sends a raw event through the data channel
  Future<void> sendEvent(Map<String, dynamic> event) async {
    // if (!isReadyToSendEvents()) {
    //   throw Exception('WebRTC service is not ready to send events. Current state: $_connectionState');
    // }
    try {
      _dataChannel!.send(RTCDataChannelMessage(jsonEncode(event)));
    } catch (e) {
      onError?.call('Failed to send event: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await endSession();
  }
}
