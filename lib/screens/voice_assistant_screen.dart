import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_protocol/livekit_protocol.dart' show TrackKind; // Added this import
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isLoading = true;
  bool _isMicEnabled = false;
  String _transcription = ""; // Or a list of transcriptions

  // --- CONFIG (Move to a config file or pass as params) ---
  final String _backendBaseUrl = 'http://localhost:8000'; // YOUR PYTHON BACKEND
  final String _liveKitWsUrl = 'ws://localhost:7880';    // YOUR LIVEKIT SERVER (local dev)
  final String _identity = 'flutter-user-${DateTime.now().millisecondsSinceEpoch}'; // Unique identity
  final String _roomName = 'odelle-voice-agent-room';
  // --- END CONFIG ---

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  Future<String?> _fetchToken() async {
    final url = Uri.parse('$_backendBaseUrl/token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': _identity, 'room': _roomName}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['token'];
      }
      print('Failed to fetch token: ${response.statusCode}');
    } catch (e) {
      print('Error fetching token: $e');
    }
    return null;
  }

  Future<void> _connect() async {
    setState(() { _isLoading = true; });
    final token = await _fetchToken();
    if (token == null) {
      print("Failed to get token, cannot connect.");
      setState(() { _isLoading = false; });
      // Show error to user
      return;
    }

    _room = Room();
    _listener = _room!.createListener();

    // Setup listeners before connecting
    _listener!
      ..on<RoomDisconnectedEvent>((event) {
        print('Room disconnected: ${event.reason}');
        if (mounted) setState(() { _isLoading = false; /* Update UI */ });
      })
      ..on<LocalTrackPublishedEvent>((event) {
          if (event.publication.kind == TrackKind.AUDIO) {
              if (mounted) setState(() { _isMicEnabled = true; });
          }
      })
      ..on<LocalTrackUnpublishedEvent>((event) {
          if (event.publication.kind == TrackKind.AUDIO) {
              if (mounted) setState(() { _isMicEnabled = false; });
          }
      })
      ..on<DataReceivedEvent>((event) {
        final data = utf8.decode(event.data);
        print('Data received: $data');
        if (mounted) {
          setState(() {
            _transcription = "$_transcription$data\n"; // Append or process
          });
        }
      })
      // Add other listeners: ParticipantConnected, TrackSubscribed for agent audio, etc.
      ..on<ParticipantConnectedEvent>((event) {
        print('Participant connected: ${event.participant.identity} (${event.participant.kind})');
        // You might want to handle tracks from other participants if needed
      })
      ..on<TrackSubscribedEvent>((event) {
        print('Track subscribed: ${event.track.sid} from ${event.participant.identity}');
        // Agent audio will play automatically
      });


    try {
      await _room!.connect(
        _liveKitWsUrl,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(dtx: true),
          // No video needed for voice agent
        ),
      );
      print('Connected to room: ${_room!.name}');
      await _room!.localParticipant!.setMicrophoneEnabled(true); // Enable mic by default
      // _isMicEnabled will be updated by the LocalTrackPublishedEvent listener

    } catch (e) {
      print('Error connecting to room: $e');
      // show error
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _disconnect() async {
    if (_room != null) {
      await _listener?.dispose();
      await _room!.disconnect();
      _room = null;
      print('Disconnected.');
      if (mounted) setState(() { /* Update UI */ });
    }
  }

  void _toggleMic() async {
    if (_room?.localParticipant == null) return;
    final newMicState = !(_room!.localParticipant!.isMicrophoneEnabled());
    await _room!.localParticipant!.setMicrophoneEnabled(newMicState);
    // State (_isMicEnabled) will be updated by LocalTrackPublished/Unpublished events
    print("Mic toggled to: $newMicState");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: GlassMorphism(
          blur: 18,
          opacity: 0.13,
          color: AppColors.background,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.mintLight,  // Light teal at top
              AppColors.primary,    // Mint in the upper middle
              AppColors.secondary,  // Purple in the lower middle
              AppColors.accent1,    // Orange at the bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GlassMorphism(
                          // TODO: Replace with actual AudioWaveformVisualizer
                          child: Center(child: Text("AudioWaveformVisualizer: Mic is ${_isMicEnabled ? 'ON' : 'OFF'}")),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        flex: 2,
                        child: GlassMorphism(
                          child: Center(
                            child: SingleChildScrollView(child: Text(_transcription.isEmpty ? "TranscriptionView: Waiting for agent..." : _transcription)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: GlassMorphism(
                          child: Center(
                            // TODO: Build a proper VoiceControlBar widget
                            child: IconButton(
                              icon: Icon(_isMicEnabled ? Icons.mic : Icons.mic_off, size: 40, color: AppColors.textPrimary),
                              onPressed: _toggleMic,
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
