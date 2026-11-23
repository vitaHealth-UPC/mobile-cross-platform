import 'package:flutter_tts/flutter_tts.dart';

import '../../application/ports/voice_confirmation.dart';

/// Reads the suggested phrase with the device's own text-to-speech engine.
final class DevicePhraseSpeaker implements PhraseSpeaker {
  DevicePhraseSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String phrase, String languageTag) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(languageTag);
      await _tts.speak(phrase);
    } on Exception {
      // Hearing the phrase is optional; the screen still shows it.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Exception {
      // Nothing is being read.
    }
  }
}
