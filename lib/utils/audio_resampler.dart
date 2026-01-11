import 'dart:typed_data';

/// Audio converter for fixing macOS mic output (48kHz stereo) 
/// to Azure API requirements (24kHz mono)
class AudioResampler {
  /// Convert macOS mic output (48kHz stereo) to Azure format (24kHz mono)
  /// 1. Stereo → Mono (average left + right channels)
  /// 2. 48kHz → 24kHz (take every 2nd sample)
  /// Combined: Take every 4th sample pair, average L+R
  static Uint8List convertMacOSToAzure(Uint8List input) {
    // PCM16 stereo: 4 bytes per frame (2 bytes L + 2 bytes R)
    // We need at least 4 bytes (1 stereo frame)
    if (input.length < 4) return Uint8List(0);
    
    // Input: 48kHz stereo PCM16
    // Each frame = 4 bytes (2 bytes left + 2 bytes right)
    final frameCount = input.length ~/ 4;
    
    // Output: 24kHz mono PCM16
    // Half the frames (downsampling), 2 bytes each
    final outputFrameCount = frameCount ~/ 2;
    final output = Uint8List(outputFrameCount * 2);
    
    // Process every 2nd stereo frame (for 48→24kHz downsampling)
    for (var i = 0; i < outputFrameCount; i++) {
      final srcOffset = i * 2 * 4; // Every 2nd frame, 4 bytes per stereo frame
      
      // Read left and right samples (little-endian PCM16)
      final left = _readInt16LE(input, srcOffset);
      final right = _readInt16LE(input, srcOffset + 2);
      
      // Average to mono
      final mono = ((left + right) ~/ 2).clamp(-32768, 32767);
      
      // Write mono sample (little-endian PCM16)
      _writeInt16LE(output, i * 2, mono);
    }
    
    return output;
  }
  
  /// Original stereo→mono conversion (no sample rate change)
  static Uint8List stereoToMono(Uint8List input) {
    if (input.length < 4) return Uint8List(0);
    
    final frameCount = input.length ~/ 4;
    final output = Uint8List(frameCount * 2);
    
    for (var i = 0; i < frameCount; i++) {
      final srcOffset = i * 4;
      final left = _readInt16LE(input, srcOffset);
      final right = _readInt16LE(input, srcOffset + 2);
      final mono = ((left + right) ~/ 2).clamp(-32768, 32767);
      _writeInt16LE(output, i * 2, mono);
    }
    
    return output;
  }
  
  /// Simple mono 2x downsample (48kHz → 24kHz mono input)
  static Uint8List downsample2x(Uint8List input) {
    if (input.length < 4) return input;
    
    final sampleCount = input.length ~/ 2;
    final outputCount = sampleCount ~/ 2;
    final output = Uint8List(outputCount * 2);
    
    for (var i = 0; i < outputCount; i++) {
      final srcOffset = i * 4; // Every 2nd sample
      final sample = _readInt16LE(input, srcOffset);
      _writeInt16LE(output, i * 2, sample);
    }
    
    return output;
  }
  
  // Read little-endian Int16
  static int _readInt16LE(Uint8List data, int offset) {
    if (offset + 1 >= data.length) return 0;
    final low = data[offset];
    final high = data[offset + 1];
    var value = (high << 8) | low;
    if (value >= 0x8000) value -= 0x10000; // Sign extend
    return value;
  }
  
  // Write little-endian Int16
  static void _writeInt16LE(Uint8List data, int offset, int value) {
    if (offset + 1 >= data.length) return;
    data[offset] = value & 0xFF;
    data[offset + 1] = (value >> 8) & 0xFF;
  }
}
