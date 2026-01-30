import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_session_helper.dart';
import 'logger.dart';

class FileAudioQueue {
  final AudioPlayer _player;
  final List<AudioSource> _sources = [];
  int _chunkIndex = 0;
  bool _sessionConfigured = false;

  FileAudioQueue(this._player);

  Future<void> init() async {
    // Configure audio session for playback through speaker
    if (!_sessionConfigured) {
      await AudioSessionHelper.configureForPlayback();
      _sessionConfigured = true;
    }
  }

  Future<void> addChunk(Uint8List pcmData) async {
    // Ensure audio session is configured before first chunk
    if (!_sessionConfigured) {
      await AudioSessionHelper.configureForPlayback();
      _sessionConfigured = true;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}_$_chunkIndex.wav');
      _chunkIndex++;

      // Add WAV header
      final wavBytes = _addWavHeader(pcmData);
      await file.writeAsBytes(wavBytes);

      final source = AudioSource.file(file.path);
      _sources.add(source);

      // Set audio sources and play using the new playlist API
      await _player.setAudioSources(
        _sources,
        initialIndex: _sources.length - 1,
      );

      // Ensure playback starts/resumes
      if (_player.processingState == ProcessingState.completed) {
        // If finished, seek to the new item and play
        await _player.seek(Duration.zero, index: _sources.length - 1);
        _player.play();
      } else if (!_player.playing) {
        _player.play();
      }
    } catch (e) {
      Logger.error('Error adding audio chunk', tag: 'FileAudioQueue', error: e);
    }
  }

  Future<void> clear() async {
    await _player.stop();
    _sources.clear();
    _chunkIndex = 0;
    // Ideally clean up files too, but OS handles temp files eventually
  }

  Uint8List _addWavHeader(Uint8List pcmData) {
    final int sampleRate = 24000;
    final int channels = 1;
    final int byteRate = sampleRate * channels * 2;

    final header = Uint8List(44);
    final view = ByteData.view(header.buffer);

    _writeString(view, 0, 'RIFF');
    view.setUint32(4, 36 + pcmData.length, Endian.little);
    _writeString(view, 8, 'WAVE');
    _writeString(view, 12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    _writeString(view, 36, 'data');
    view.setUint32(40, pcmData.length, Endian.little);

    final result = Uint8List(44 + pcmData.length);
    result.setRange(0, 44, header);
    result.setRange(44, 44 + pcmData.length, pcmData);
    return result;
  }

  void _writeString(ByteData view, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
