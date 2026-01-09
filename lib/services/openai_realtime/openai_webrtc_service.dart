import 'package:odelle_nyse/services/openai_realtime/handlers/message/openai_realtime_message_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../../config/digital_worker_config.dart';
import 'utils/sdp_connection_util.dart';
import 'utils/session_update_util.dart';
import 'base_webrtc_service.dart';
import 'openai_session_service.dart';

/// A service that manages WebRTC connections specifically for OpenAI's Realtime API.
///
/// This service extends the base WebRTC functionality to add:
/// - OpenAI session management
/// - Response creation and interruption
/// - Session configuration updates
/// - Response event handling (created, done)
///
/// Response events provide information about:
/// - Response status (in_progress, completed)
/// - Output messages and their content
/// - Token usage statistics
class OpenAIWebRTCService extends BaseWebRTCService {
  final OpenAISessionService _sessionService = OpenAISessionService();
  OpenAIRealtimeMessageHandler? _messageHandler;
  bool _isDataChannelOpen = false;
  bool _hasUpdatedSession = false;

  /// Gets the web-specific renderer for audio playback
  @override
  RTCVideoRenderer? get webRenderer => super.webRenderer;

  /// Called when a new response is created and in progress
  OnResponseCreated? _onResponseCreated;
  OnResponseCreated? get onResponseCreated => _onResponseCreated;
  set onResponseCreated(OnResponseCreated? value) {
    _onResponseCreated = value;
    _updateMessageHandler();
  }

  /// Called when a response is completed
  OnResponseDone? _onResponseDone;
  OnResponseDone? get onResponseDone => _onResponseDone;
  set onResponseDone(OnResponseDone? value) {
    _onResponseDone = value;
    _updateMessageHandler();
  }

  /// Called when a conversation is created
  OnConversationCreated? _onConversationCreated;
  OnConversationCreated? get onConversationCreated => _onConversationCreated;
  set onConversationCreated(OnConversationCreated? value) {
    _onConversationCreated = value;
    _updateMessageHandler();
  }

  /// Called when a conversation item is created
  OnConversationItemCreated? _onConversationItemCreated;
  OnConversationItemCreated? get onConversationItemCreated =>
      _onConversationItemCreated;
  set onConversationItemCreated(OnConversationItemCreated? value) {
    _onConversationItemCreated = value;
    _updateMessageHandler();
  }

  /// Called when a conversation item is truncated
  OnConversationItemTruncated? _onConversationItemTruncated;
  OnConversationItemTruncated? get onConversationItemTruncated =>
      _onConversationItemTruncated;
  set onConversationItemTruncated(OnConversationItemTruncated? value) {
    _onConversationItemTruncated = value;
    _updateMessageHandler();
  }

  /// Called when a conversation item is deleted
  OnConversationItemDeleted? _onConversationItemDeleted;
  OnConversationItemDeleted? get onConversationItemDeleted =>
      _onConversationItemDeleted;
  set onConversationItemDeleted(OnConversationItemDeleted? value) {
    _onConversationItemDeleted = value;
    _updateMessageHandler();
  }

  /// Child handler for processing messages after base handling
  OnMessage? _childHandler;
  OnMessage? get childHandler => _childHandler;
  set childHandler(OnMessage? value) {
    _childHandler = value;
    _updateMessageHandler();
  }

  /// Updates the message handler with current callback configurations
  void _updateMessageHandler() {
    _messageHandler = OpenAIRealtimeMessageHandler(
        onResponseCreated: _onResponseCreated,
        onResponseDone: _onResponseDone,
        onConversationCreated: _onConversationCreated,
        onConversationItemCreated: _onConversationItemCreated,
        onConversationItemTruncated: _onConversationItemTruncated,
        onConversationItemDeleted: _onConversationItemDeleted,
        childHandler: _childHandler,
        sendEvent: sendEvent);
  }

  /// Helper method to update connection state and trigger callbacks
  void _updateConnectionState(WebRTCConnectionState newState) {
    developer.log(
        'Updating connection state to: $newState\n'
        'Data channel open: $_isDataChannelOpen\n'
        'Peer connection state: ${peerConnection?.connectionState}',
        name: 'OpenAIWebRTCService');

    if (newState == WebRTCConnectionState.connected &&
        (!_isDataChannelOpen ||
            peerConnection?.connectionState !=
                RTCPeerConnectionState.RTCPeerConnectionStateConnected)) {
      developer.log('Blocking connected state update - conditions not met',
          name: 'OpenAIWebRTCService');
      return;
    }

    super.onConnectionStateChange?.call(newState);
    if (newState == WebRTCConnectionState.connected) {
      onSessionStarted?.call();
      updateSession();
    }
  }

  @override
  Future<void> endSession() async {
    developer.log('Ending OpenAI WebRTC session', name: 'OpenAIWebRTCService');

    try {
      // First update state to prevent any new events
      _isDataChannelOpen = false;
      _hasUpdatedSession = false;

      // Close data channel
      if (dataChannel != null) {
        developer.log('Closing data channel', name: 'OpenAIWebRTCService');
        await dataChannel!.close();
        dataChannel = null;
      }

      // Stop and dispose media tracks
      if (localStream != null) {
        developer.log('Stopping media tracks', name: 'OpenAIWebRTCService');
        localStream!.getTracks().forEach((track) {
          track.stop();
        });
        localStream = null;
      }

      // Close peer connection
      if (peerConnection != null) {
        developer.log('Closing peer connection', name: 'OpenAIWebRTCService');
        await peerConnection!.close();
        peerConnection = null;
      }

      // Dispose web renderer
      if (webRenderer != null) {
        developer.log('Disposing web renderer', name: 'OpenAIWebRTCService');
        await webRenderer!.dispose();
      }

      // Reset message handler
      _messageHandler = null;

      developer.log('WebRTC session cleanup completed',
          name: 'OpenAIWebRTCService');
    } catch (e, stackTrace) {
      developer.log('Error during WebRTC cleanup: ${e.toString()}',
          error: e, stackTrace: stackTrace, name: 'OpenAIWebRTCService');
      rethrow;
    }

    // Call base class cleanup as final step
    await super.endSession();
  }

  @override
  Future<void> initialize({
    required DigitalWorkerConfig config,
  }) async {
    try {
      developer.log('Initializing OpenAI WebRTC connection',
          name: 'OpenAIWebRTCService');

      // Initialize web renderer for audio playback
      await initializeWebRenderer();

      // Get ephemeral token from OpenAI
      final sessionResponse = await _sessionService.createSession(
        modalities: config.modalities,
        instructions: config.instructions,
        voice: config.voice,
        vadThreshold: config.vadThreshold,
        prefixPaddingMs: config.prefixPaddingMs,
        silenceDurationMs: config.silenceDurationMs,
      );
      final ephemeralKey =
          OpenAISessionService.getEphemeralToken(sessionResponse);

      // Create and configure peer connection using utility class
      final configuration = SDPConnectionUtil.getDefaultPeerConfiguration();
      developer.log('Creating peer connection', name: 'OpenAIWebRTCService');
      peerConnection = await createPeerConnection(configuration);

      // Set up connection state monitoring
      peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            super
                .onConnectionStateChange
                ?.call(WebRTCConnectionState.connecting);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            // Only update state if data channel is open
            if (_isDataChannelOpen) {
              _updateConnectionState(WebRTCConnectionState.connected);
            }
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            super.onConnectionStateChange?.call(WebRTCConnectionState.failed);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            super
                .onConnectionStateChange
                ?.call(WebRTCConnectionState.disconnected);
            break;
          default:
            break;
        }
      };

      // Initialize message handler and set up data channel for events
      _updateMessageHandler();
      if (_messageHandler == null) {
        throw Exception('Failed to initialize message handler');
      }

      dataChannel = await peerConnection!
          .createDataChannel('oai-events', RTCDataChannelInit());

      dataChannel!.onMessage = _messageHandler!.handleDataChannelMessage;

      dataChannel!.onDataChannelState = (RTCDataChannelState state) {
        developer.log('Data channel state changed to: $state',
            name: 'OpenAIWebRTCService');

        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _isDataChannelOpen = true;
          developer.log(
              'Data channel opened. Checking peer connection state: ${peerConnection?.connectionState}',
              name: 'OpenAIWebRTCService');

          if (peerConnection?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _updateConnectionState(WebRTCConnectionState.connected);
          }
        } else if (state == RTCDataChannelState.RTCDataChannelClosed ||
            state == RTCDataChannelState.RTCDataChannelClosing) {
          _isDataChannelOpen = false;
          developer.log(
              'Data channel closed/closing. Session active: $isSessionActive',
              name: 'OpenAIWebRTCService');

          super
              .onConnectionStateChange
              ?.call(WebRTCConnectionState.disconnected);

          if (isSessionActive) {
            endSession();
          }
        }
      };

      // Add local audio track with proper constraints from utility class
      final Map<String, dynamic> mediaConstraints =
          SDPConnectionUtil.getDefaultAudioConstraints();

      developer.log('Getting user media with constraints: $mediaConstraints',
          name: 'OpenAIWebRTCService');

      final mediaStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);

      localStream = mediaStream;
      mediaStream.getTracks().forEach((track) {
        peerConnection!.addTrack(track, mediaStream);
      });

      // Create and exchange SDP offer using utility class
      developer.log('Creating offer', name: 'OpenAIWebRTCService');
      final offer = await peerConnection!.createOffer(
          {'offerToReceiveAudio': true, 'offerToReceiveVideo': false});

      await peerConnection!.setLocalDescription(offer);

      // Exchange SDP with OpenAI
      const realtimeUrl = '${AppConfig.openAiBaseUrl}/realtime';
      const model = 'gpt-4o-realtime-preview-2024-12-17';

      final answerSdp = await SDPConnectionUtil.exchangeSDP(
        url: realtimeUrl,
        offer: offer,
        headers: {'Authorization': 'Bearer $ephemeralKey'},
        queryParams: {'model': model},
      );

      // Set remote description with answer
      final answer = RTCSessionDescription(answerSdp, 'answer');
      await peerConnection!.setRemoteDescription(answer);

      developer.log('Remote description set', name: 'OpenAIWebRTCService');

      // Check if we can start the session
      if (_isDataChannelOpen &&
          peerConnection?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _updateConnectionState(WebRTCConnectionState.connected);

        if (isSessionActive) {
          await startSession();
          developer.log('Session started', name: 'OpenAIWebRTCService');
        }
      }
    } catch (e) {
      onError?.call('OpenAI WebRTC initialization error: $e');
      rethrow;
    }
  }

  /// Updates the session configuration with tools and other settings
  Future<void> updateSession() async {
    developer.log(
        'Attempting to update session. Previous update status: $_hasUpdatedSession',
        name: 'OpenAIWebRTCService');

    if (!_hasUpdatedSession) {
      try {
        final updateEvent = SessionUpdateUtil.createSessionUpdateEvent();
        developer.log('Created session update event: ${updateEvent.toString()}',
            name: 'OpenAIWebRTCService');

        await sendEvent(updateEvent);
        developer.log(
            'Session update event sent successfully. Event ID: ${updateEvent['event_id']}',
            name: 'OpenAIWebRTCService');

        _hasUpdatedSession = true;
      } catch (e, stackTrace) {
        developer.log('Failed to send session update event',
            name: 'OpenAIWebRTCService', error: e, stackTrace: stackTrace);
        rethrow;
      }
    } else {
      developer.log('Session already updated, skipping',
          name: 'OpenAIWebRTCService');
    }
  }

  /// Creates a new response with the given instructions
  Future<void> createResponse({
    required String instructions,
    List<String>? modalities,
  }) async {
    final event = {
      'type': 'response.create',
      'response': {
        'instructions': instructions,
        if (modalities != null) 'modalities': modalities,
      }
    };
    await sendEvent(event);
  }

  /// Interrupts the current response
  Future<void> interrupt() async {
    if (isReadyToSendEvents()) {
      await sendEvent({
        'type': 'response.interrupt',
      });
    } else {
      developer.log('Cannot send interrupt; WebRTC service is not connected.',
          name: 'OpenAIWebRTCService',
          error: 'Current state: $connectionState');
    }
  }
}
