import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/voice_recorder.dart';
import '../../application/readmodels/voice_recording.dart';
import 'pcm16_wav_encoder.dart';

/// Captures PCM16 mono at 16 kHz in memory, never in a file, and stops
/// keeping samples after [maxDuration].
final class MicrophoneVoiceRecorder implements VoiceRecorder {
  MicrophoneVoiceRecorder({
    AudioRecorder Function()? create,
    this.maxDuration = const Duration(seconds: 8),
  }) : _create = create ?? AudioRecorder.new;

  final AudioRecorder Function() _create;
  final Duration maxDuration;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _samples;
  BytesBuilder? _pcm;

  int get _maxBytes =>
      Pcm16WavEncoder.sampleRate * 2 * maxDuration.inMilliseconds ~/ 1000;

  @override
  Future<AppResult<void>> start() async {
    await cancel();
    final recorder = _create();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        return const AppFailure('MICROPHONE_PERMISSION_DENIED');
      }
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: Pcm16WavEncoder.sampleRate,
          numChannels: 1,
        ),
      );
      final pcm = BytesBuilder(copy: false);
      _pcm = pcm;
      _recorder = recorder;
      _samples = stream.listen((chunk) {
        final room = _maxBytes - pcm.length;
        if (room <= 0) return;
        final keep = chunk.length <= room ? chunk.length : room - room % 2;
        pcm.add(keep == chunk.length ? chunk : chunk.sublist(0, keep));
      });
      return const AppSuccess(null);
    } on Exception {
      _recorder = null;
      _pcm = null;
      await _quietly(recorder.dispose);
      return const AppFailure('MICROPHONE_UNAVAILABLE');
    }
  }

  @override
  Future<AppResult<VoiceRecording>> finish() async {
    final recorder = _recorder;
    final pcm = _pcm;
    if (recorder == null || pcm == null) {
      return const AppFailure('INVALID_AUDIO');
    }
    try {
      await recorder.stop();
      await _samples?.cancel();
      final bytes = pcm.takeBytes();
      final whole = bytes.length.isOdd
          ? Uint8List.sublistView(bytes, 0, bytes.length - 1)
          : bytes;
      if (whole.isEmpty) return const AppFailure('INVALID_AUDIO');
      return AppSuccess(VoiceRecording(Pcm16WavEncoder.encode(whole)));
    } on Exception {
      return const AppFailure('INVALID_AUDIO');
    } finally {
      await _release();
    }
  }

  @override
  Future<void> cancel() async {
    final recorder = _recorder;
    if (recorder == null) return;
    await _quietly(recorder.cancel);
    await _release();
  }

  Future<void> _release() async {
    final recorder = _recorder;
    _recorder = null;
    _pcm = null;
    await _samples?.cancel();
    _samples = null;
    if (recorder != null) await _quietly(recorder.dispose);
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // The microphone is already released or was never acquired.
    }
  }
}
