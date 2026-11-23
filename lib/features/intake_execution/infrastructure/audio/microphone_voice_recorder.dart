import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/voice_recorder.dart';
import '../../application/readmodels/voice_recording.dart';
import 'pcm16_wav_encoder.dart';

/// Bounded PCM16 mono capture in memory. Cancellation also invalidates permission
/// and stream requests that are still pending; a late grant cannot restart recording.
final class MicrophoneVoiceRecorder implements VoiceRecorder {
  MicrophoneVoiceRecorder({
    AudioRecorder Function()? create,
    this.maxDuration = const Duration(seconds: 8),
  }) : _create = create ?? AudioRecorder.new;
  final AudioRecorder Function() _create;
  final Duration maxDuration;
  _Capture? _active;
  int _generation = 0;
  int get _maxBytes =>
      Pcm16WavEncoder.sampleRate * 2 * maxDuration.inMilliseconds ~/ 1000;

  @override
  Future<AppResult<void>> start() async {
    final generation = ++_generation;
    await _dropActive();
    if (generation != _generation) {
      return const AppFailure('VOICE_RECORDING_CANCELLED');
    }
    final recorder = _create();
    var handedOff = false;
    try {
      final permitted = await recorder.hasPermission();
      if (generation != _generation) {
        return const AppFailure('VOICE_RECORDING_CANCELLED');
      }
      if (!permitted) return const AppFailure('MICROPHONE_PERMISSION_DENIED');
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: Pcm16WavEncoder.sampleRate,
          numChannels: 1,
        ),
      );
      if (generation != _generation) {
        await _quietly(recorder.cancel);
        return const AppFailure('VOICE_RECORDING_CANCELLED');
      }
      final pcm = BytesBuilder(copy: false);
      var failed = false;
      final samples = stream.listen(
        (chunk) {
          final room = _maxBytes - pcm.length;
          if (room <= 0) return;
          final keep = chunk.length <= room ? chunk.length : room - room % 2;
          pcm.add(keep == chunk.length ? chunk : chunk.sublist(0, keep));
        },
        onError: (Object _) {
          failed = true;
        },
      );
      _active = _Capture(recorder, samples, pcm, () => failed);
      handedOff = true;
      return const AppSuccess(null);
    } on Exception {
      return const AppFailure('MICROPHONE_UNAVAILABLE');
    } finally {
      if (!handedOff) await _quietly(recorder.dispose);
    }
  }

  @override
  Future<AppResult<VoiceRecording>> finish() async {
    final capture = _active;
    _active = null;
    if (capture == null) return const AppFailure('INVALID_AUDIO');
    try {
      await capture.recorder.stop();
      await capture.samples.cancel();
      if (capture.failed()) return const AppFailure('INVALID_AUDIO');
      final bytes = capture.pcm.takeBytes();
      final whole = bytes.length.isOdd
          ? Uint8List.sublistView(bytes, 0, bytes.length - 1)
          : bytes;
      if (whole.isEmpty) return const AppFailure('INVALID_AUDIO');
      return AppSuccess(VoiceRecording(Pcm16WavEncoder.encode(whole)));
    } on Exception {
      return const AppFailure('INVALID_AUDIO');
    } finally {
      await _quietly(capture.samples.cancel);
      capture.pcm.clear();
      await _quietly(capture.recorder.dispose);
    }
  }

  @override
  Future<void> cancel() async {
    ++_generation;
    await _dropActive();
  }

  /// Detaches before awaiting native cleanup, so an old capture cannot release a new one.
  Future<void> _dropActive() async {
    final capture = _active;
    _active = null;
    if (capture == null) return;
    await _quietly(capture.samples.cancel);
    await _quietly(capture.recorder.cancel);
    capture.pcm.clear();
    await _quietly(capture.recorder.dispose);
  }

  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Exception {
      // Native cancellation may already have released the recording.
    }
  }
}

/// Resources of exactly one capture; cleanup never reads mutable process-wide fields.
final class _Capture {
  const _Capture(this.recorder, this.samples, this.pcm, this.failed);
  final AudioRecorder recorder;
  final StreamSubscription<Uint8List> samples;
  final BytesBuilder pcm;
  final bool Function() failed;
}
