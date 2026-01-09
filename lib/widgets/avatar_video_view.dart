import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class AvatarVideoView extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final bool isMirror;

  const AvatarVideoView({
    super.key,
    required this.renderer,
    this.isMirror = false,
  });

  @override
  State<AvatarVideoView> createState() => _AvatarVideoViewState();
}

class _AvatarVideoViewState extends State<AvatarVideoView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: RTCVideoView(
          widget.renderer,
          mirror: widget.isMirror,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }
}
