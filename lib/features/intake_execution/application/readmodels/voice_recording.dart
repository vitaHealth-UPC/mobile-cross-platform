import 'dart:typed_data';

/// One finished recording, already in the format the server accepts.
final class VoiceRecording {
  const VoiceRecording(this.bytes, {this.contentType = 'audio/wav'});

  final Uint8List bytes;
  final String contentType;

  @override
  String toString() => 'VoiceRecording[${bytes.length} bytes, REDACTED]';
}
