import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:developer' as developer;
import '../config/app_config.dart';
import '../openai_realtime/base_webrtc_service.dart';
import '../openai_realtime/utils/sdp_connection_util.dart';
import '../../models/digital_worker_voice.dart';
import '../../config/digital_worker_config.dart';

class AzureWebRTCService extends BaseWebRTCService {
  WebSocketChannel? _channel;
  StreamSubscription? _wsSubscription;
  bool _isAvatarConnected = false;

  // Callback for when avatar is connected
  VoidCallback? onAvatarConnected;

  @override
  Future<void> initialize({
    required DigitalWorkerConfig config,
  }) async {
    // Azure initialization is handled via connect()
    throw UnimplementedError('Use connect() instead');
  }

  Future<void> connect({
    required String workerId,
    required DigitalWorkerConfig config,
  }) async {
    try {
      developer.log('Connecting to Azure Voice Live via WebSocket',
          name: 'AzureWebRTCService');

      // Initialize web renderer if needed
      await initializeWebRenderer();

      // Connect to WebSocket
      // Using Ngrok for physical device support + Valid JWT Token (expires 2025-11-29 20:24 UTC)
      final wsUrl = Uri.parse(
          'wss://4b1db0965b44.ngrok-free.app/ws/user-meeting?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MDY4Mjc1MC0yNjFiLTRmMmMtYWI1ZS03MzY5MWYxN2RlZDA6OjEuMCIsImV4cCI6MTc2NDQ0Nzg1OCwiaWF0IjoxNzY0MzYxNDU4LCJ0b2tlbl90eXBlIjoiYXBwX3Rva2VuIn0.2zuAImnsMgKYPU9kV6sowv7nGERqvDjvx9N7zFOBt_E');
      developer.log('WebSocket URL: $wsUrl', name: 'AzureWebRTCService');

      _channel = WebSocketChannel.connect(wsUrl);

      // Listen to WebSocket messages
      _wsSubscription = _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          developer.log('WebSocket error: $error',
              name: 'AzureWebRTCService', error: error);
          onError?.call('WebSocket error: $error');
        },
        onDone: () {
          developer.log('WebSocket connection closed',
              name: 'AzureWebRTCService');
          endSession();
        },
      );

      // Send initialize message
      // Protocol Step 2: Send initialize
      final initMsg = {
        'type': 'initialize',
        'worker_id': workerId,
        'session_context': {
          'user_name': 'Poly Mobile User',
        }
      };
      _sendJson(initMsg);

      developer.log('Sent initialize message', name: 'AzureWebRTCService');

      // If avatar mode is enabled, start WebRTC handshake
      // Note: We usually wait for some confirmation or just start it if we know it's an avatar session
      if (config.modalities.contains('avatar')) {
        await _initiateAvatarHandshake();
      }
    } catch (e, stackTrace) {
      developer.log('Error connecting to Azure Voice Live',
          name: 'AzureWebRTCService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initiateAvatarHandshake() async {
    try {
      developer.log('Initiating Avatar WebRTC handshake',
          name: 'AzureWebRTCService');

      // Create peer connection with default config (ICE servers will be added later)
      final configuration = SDPConnectionUtil.getDefaultPeerConfiguration();

      // Create peer connection
      peerConnection = await createPeerConnection(configuration);

      // Handle ICE candidates
      peerConnection!.onIceCandidate = (candidate) {
        // Azure might not need us to send candidates if we send a complete offer
        // But if we did, we'd send them here.
        // For now, we wait for gathering to complete before sending offer.
      };

      peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        developer.log('Peer connection state: $state',
            name: 'AzureWebRTCService');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _isAvatarConnected = true;
          onAvatarConnected?.call();
          super.onConnectionStateChange?.call(WebRTCConnectionState.connected);
        }
      };

      peerConnection!.onTrack = (RTCTrackEvent event) {
        developer.log('Received remote track: ${event.track.kind}',
            name: 'AzureWebRTCService');
        if (event.streams.isNotEmpty) {
          if (event.track.kind == 'video') {
            onRemoteStreamReceived?.call(event.streams[0]);
          }
          // Audio is also handled here
        }
      };

      // Add transceivers
      await peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      await peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Create offer
      final offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      // Wait for ICE gathering to complete (simple version)
      // In a real app, we might want to wait for 'complete' state
      // await _waitForIceGatheringComplete();

      // Send offer via WebSocket
      // Azure expects: { "type": "session.avatar.connect", "client_sdp": "..." }
      // The backend proxy expects us to send this, and it forwards to Azure.

      final sdpOffer = offer.sdp;
      // Note: The backend/Azure might expect the SDP to be wrapped in a JSON string or base64
      // Based on docs: "client_sdp": "<browser SDP offer string>"
      // And "Azure requires client_sdp ... to be Base64 strings that wrap a JSON blob"
      // BUT the integration guide says: "The proxy now handles this automatically... the browser receives plain v=0 SDP"
      // So we should send plain SDP? Or the JSON wrapper?
      // "Browser sends session.avatar.connect with client_sdp Base64-wrapped JSON... exactly as the Azure sample."
      // Let's try sending the JSON wrapper first as per common WebRTC practices with Azure.

      final sdpJson = jsonEncode({'type': 'offer', 'sdp': sdpOffer});
      // The docs say "client_sdp Base64-wrapped JSON"
      final sdpBase64 = base64Encode(utf8.encode(sdpJson));

      final connectMsg = {
        'type': 'session.avatar.connect',
        'client_sdp': sdpBase64,
      };

      _sendJson(connectMsg);
      developer.log('Sent session.avatar.connect', name: 'AzureWebRTCService');
    } catch (e) {
      developer.log('Error initiating avatar handshake',
          name: 'AzureWebRTCService', error: e);
    }
  }

  // Callbacks
  Function(String)? onTranscriptDelta;
  Function(String)? onTranscriptDone;
  Function(Uint8List)? onAudioChunk;
  Function(String)? onUserTranscript;
  VoidCallback? onSessionConnected;

  void _handleWebSocketMessage(dynamic message) async {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'];
      developer.log('Received message: $type', name: 'AzureWebRTCService');

      switch (type) {
        case 'session_created':
          developer.log('Session created: ${data['meeting_id']}',
              name: 'AzureWebRTCService');
          // Notify UI that we are connected
          onSessionConnected?.call();

          _sendJson({'type': 'start_conversation'});
          developer.log('Sent start_conversation', name: 'AzureWebRTCService');
          break;

        case 'response.audio.delta':
          if (data['delta'] != null) {
            final bytes = base64Decode(data['delta']);
            // developer.log('Received audio chunk: ${bytes.length} bytes', name: 'AzureWebRTCService');
            onAudioChunk?.call(bytes);
          }
          break;

        case 'response.audio_transcript.delta':
          if (data['delta'] != null) {
            developer.log('Transcript delta: ${data['delta']}',
                name: 'AzureWebRTCService');
            onTranscriptDelta?.call(data['delta']);
          }
          break;

        case 'response.audio_transcript.done':
          if (data['transcript'] != null) {
            developer.log('Transcript done: ${data['transcript']}',
                name: 'AzureWebRTCService');
            onTranscriptDone?.call(data['transcript']);
          }
          break;

        case 'user_transcription':
          if (data['transcript'] != null) {
            developer.log('User transcription: ${data['transcript']}',
                name: 'AzureWebRTCService');
            onUserTranscript?.call(data['transcript']);
          }
          break;

        case 'response_complete':
          developer.log('Response complete', name: 'AzureWebRTCService');
          break;

        case 'session.avatar.connecting':
          await _handleAvatarConnecting(data);
          break;

        default:
          // Forward other messages
          onMessage?.call(data);
      }
    } catch (e) {
      developer.log('Error handling WebSocket message',
          name: 'AzureWebRTCService', error: e);
    }
  }

  void sendAudioChunk(Uint8List pcmData) {
    if (_channel == null) return;

    final base64Audio = base64Encode(pcmData);
    _sendJson({
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    });
    // developer.log('Sent audio chunk: ${pcmData.length} bytes', name: 'AzureWebRTCService');
  }

  Future<void> _handleAvatarConnecting(Map<String, dynamic> data) async {
    developer.log('Received session.avatar.connecting',
        name: 'AzureWebRTCService');

    // Extract SDP answer and ICE servers
    // Azure sends: { "type": "session.avatar.connecting", "server_sdp": "...", "ice_servers": [...] }

    if (data.containsKey('server_sdp')) {
      String serverSdp = data['server_sdp'];

      // Decode if it's base64 wrapped JSON (as per docs "proxy ... decodes answers before forwarding")
      // But let's check if it looks like SDP first
      if (!serverSdp.startsWith('v=0')) {
        try {
          // Try decoding base64
          final decoded = utf8.decode(base64Decode(serverSdp));
          final jsonSdp = jsonDecode(decoded);
          serverSdp = jsonSdp['sdp'];
        } catch (e) {
          developer.log('Failed to decode server SDP, assuming plain text',
              name: 'AzureWebRTCService');
        }
      }

      final answer = RTCSessionDescription(serverSdp, 'answer');
      await peerConnection!.setRemoteDescription(answer);
    }

    if (data.containsKey('ice_servers')) {
      final iceServers = data['ice_servers'] as List;
      for (var server in iceServers) {
        // Add ICE candidate? No, these are ICE Servers (STUN/TURN)
        // We should have initialized the PeerConnection with these!
        // But we already created it.
        // WebRTC allows updating configuration?
        // Or maybe we should have waited for this before creating PC?
        // Actually, Azure sends ICE servers in this message.
        // We might need to restart ICE or add them.
        // "Azure-provided ICE servers ... are persisted inside avatarIceServers"
        // "Each RTCPeerConnection is created with ... the Azure TURN credentials"

        // If we receive ICE servers here, we might need to recreate the PC or add them.
        // Flutter WebRTC supports setConfiguration.

        final List<Map<String, dynamic>> iceServerConfig = [];
        for (var s in iceServers) {
          iceServerConfig.add({
            'urls': s['urls'],
            'username': s['username'],
            'credential': s['credential'],
          });
        }

        final config = {
          'iceServers': iceServerConfig,
          'sdpSemantics': 'unified-plan',
          'bundlePolicy': 'max-bundle',
        };

        await peerConnection!.setConfiguration(config);
      }
    }
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  @override
  Future<void> endSession() async {
    await _wsSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isAvatarConnected = false;
    await super.endSession();
  }
}
