import 'dart:typed_data';

/// Wraps raw little-endian PCM16 mono samples in the RIFF/WAV container the
/// server validates (8–48 kHz, 16-bit, one channel).
abstract final class Pcm16WavEncoder {
  static const sampleRate = 16000;
  static const _headerBytes = 44;

  static Uint8List encode(Uint8List pcm, {int sampleRate = sampleRate}) {
    if (pcm.length.isOdd) throw ArgumentError('Incomplete PCM16 sample');
    const channels = 1;
    const bitsPerSample = 16;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final out = Uint8List(_headerBytes + pcm.length);
    final header = ByteData.sublistView(out, 0, _headerBytes);
    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        out[offset + i] = value.codeUnitAt(i);
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, out.length - 8, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * blockAlign, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    out.setRange(_headerBytes, out.length, pcm);
    return out;
  }
}
