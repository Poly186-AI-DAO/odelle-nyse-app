import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

class PcmStreamSource extends StreamAudioSource {
  final Stream<List<int>> _stream;
  final int _sampleRate;
  final int _channels;

  PcmStreamSource(this._stream, {int sampleRate = 24000, int channels = 1})
      : _sampleRate = sampleRate,
        _channels = channels;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // For a live stream, we ignore start/end and just stream from the beginning (or current point)
    // We return a null contentLength to indicate unknown length.
    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: 0, // Always start at 0 for the stream wrapper
      stream: _createWavStream(),
      contentType: 'audio/wav',
    );
  }

  Stream<List<int>> _createWavStream() async* {
    // Yield WAV header
    yield _createWavHeader();
    // Yield PCM data
    yield* _stream;
  }

  List<int> _createWavHeader() {
    final int sampleRate = _sampleRate;
    final int channels = _channels;
    final int byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes

    final header = Uint8List(44);
    final view = ByteData.view(header.buffer);

    // RIFF chunk
    _writeString(view, 0, 'RIFF');
    view.setUint32(4, 0xFFFFFFFF, Endian.little); // Unknown length
    _writeString(view, 8, 'WAVE');

    // fmt chunk
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // Subchunk1Size
    view.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little); // BlockAlign
    view.setUint16(34, 16, Endian.little); // BitsPerSample

    // data chunk
    _writeString(view, 36, 'data');
    view.setUint32(40, 0xFFFFFFFF, Endian.little); // Unknown length

    return header;
  }

  void _writeString(ByteData view, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
