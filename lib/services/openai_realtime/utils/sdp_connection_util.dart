import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// A utility class that handles WebRTC SDP (Session Description Protocol) connection operations.
///
/// This class encapsulates the logic for:
/// - Creating and configuring peer connections
/// - Generating SDP offers
/// - Exchanging SDP information with servers
/// - Setting up media constraints
class SDPConnectionUtil {
  /// Creates an SDP offer for the WebRTC connection with proper certificate handling
  static Future<RTCSessionDescription> createOffer() async {
    developer.log('Creating WebRTC peer connection', name: 'SDPConnectionUtil');

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 1
    };

    final Map<String, dynamic> offerOptions = {
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
      'voiceActivityDetection': true,
      'iceRestart': true
    };

    developer.log('Creating peer connection with config: $configuration',
        name: 'SDPConnectionUtil');

    final peerConnection = await createPeerConnection(configuration);

    try {
      // Add audio transceiver
      await peerConnection.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(
              direction: TransceiverDirection.SendRecv, streams: []));

      // Create and set offer
      final offer = await peerConnection.createOffer(offerOptions);

      developer.log('Offer created, setting local description',
          name: 'SDPConnectionUtil', error: 'SDP Type: ${offer.type}');

      // Set local description before returning
      await peerConnection.setLocalDescription(offer);

      developer.log('Local description set successfully',
          name: 'SDPConnectionUtil');

      return offer;
    } catch (e) {
      developer.log('Error creating offer',
          name: 'SDPConnectionUtil', error: e.toString());
      rethrow;
    } finally {
      await peerConnection.close();
    }
  }

  /// Exchanges SDP information with a server
  ///
  /// [url] The server URL to send the SDP offer to
  /// [offer] The SDP offer to send
  /// [headers] Optional additional headers for the request
  /// [queryParams] Optional query parameters to add to the URL
  static Future<String> exchangeSDP({
    required String url,
    required RTCSessionDescription offer,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      developer.log('Making SDP request',
          name: 'SDPConnectionUtil',
          error: 'URL: $url\nSDP Offer: ${offer.sdp}');

      // Build the URL with query parameters
      var uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Use a raw socket connection to avoid content-type encoding
      final client = http.Client();
      final bytes = offer.sdp!.codeUnits;

      final defaultHeaders = {
        'Content-Type': 'application/sdp',
        'Accept': 'application/sdp',
      };

      // Merge default headers with provided headers
      final mergedHeaders = {...defaultHeaders, ...?headers};

      final sdpResponse = await client
          .send(http.StreamedRequest('POST', uri)
            ..headers.addAll(mergedHeaders)
            ..contentLength = bytes.length
            ..sink.add(bytes)
            ..sink.close())
          .then((streamedResponse) async {
        final response = await http.Response.fromStream(streamedResponse);
        client.close();
        return response;
      });

      developer.log('Received response from server',
          name: 'SDPConnectionUtil',
          error:
              'Status: ${sdpResponse.statusCode}\nHeaders: ${sdpResponse.headers}\nBody: ${sdpResponse.body}');

      // Check for successful response (200 or 201)
      if (sdpResponse.statusCode != 200 && sdpResponse.statusCode != 201) {
        final errorBody = sdpResponse.body;
        try {
          // Only try to parse as JSON if it looks like JSON
          if (errorBody.trim().startsWith('{')) {
            final errorJson = jsonDecode(errorBody);
            throw Exception(
                'Failed to get SDP answer: ${sdpResponse.statusCode} - ${errorJson['error']['message']}');
          } else {
            throw Exception(
                'Failed to get SDP answer: ${sdpResponse.statusCode} - $errorBody');
          }
        } catch (e) {
          throw Exception(
              'Failed to get SDP answer: ${sdpResponse.statusCode} - $errorBody');
        }
      }

      final answerSdp = sdpResponse.body;
      if (answerSdp.isEmpty) {
        throw Exception('Received empty SDP answer from server');
      }

      developer.log('Received SDP answer',
          name: 'SDPConnectionUtil', error: 'SDP: $answerSdp');

      return answerSdp;
    } catch (e) {
      developer.log('Error during SDP exchange',
          name: 'SDPConnectionUtil', error: e.toString());
      rethrow;
    }
  }

  /// Gets the default media constraints for audio
  static Map<String, dynamic> getDefaultAudioConstraints() {
    return {
      'audio': {
        'mandatory': {},
        'optional': [
          {'echoCancellation': true},
          {'googEchoCancellation': true},
          {'googEchoCancellation2': true},
          {'googDAEchoCancellation': true},
          {'googNoiseSuppression': true}
        ]
      },
      'video': false
    };
  }

  /// Gets the default peer connection configuration
  static Map<String, dynamic> getDefaultPeerConfiguration() {
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
  }
}
