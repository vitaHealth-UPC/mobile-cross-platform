import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/ports/voice_recorder.dart';
import 'package:tata/features/intake_execution/application/readmodels/voice_recording.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake_by_voice.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/audio/microphone_voice_recorder.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_state.dart';
import 'package:tata/shared/common/result/app_result.dart';

import 'voice_confirmation_test.dart' show dose, FakeVoice, wav;

/// Native recorder double with explicit permission and stream completion boundaries.
final class _Device extends Fake implements AudioRecorder {
  Future<bool> permission = Future.value(true);
  Future<Stream<Uint8List>>? opening;
  final samples = StreamController<Uint8List>();
  int starts = 0;
  int cancels = 0;
  int disposals = 0;
  @override
  Future<bool> hasPermission({bool request = true}) => permission;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    starts++;
    return opening ?? samples.stream;
  }

  @override
  Future<String?> stop() async {
    await samples.close();
    return null;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

final class _Recorder implements VoiceRecorder {
  final started = Completer<AppResult<void>>();
  int starts = 0;
  int cancels = 0;
  @override
  Future<AppResult<void>> start() {
    starts++;
    return started.future;
  }

  @override
  Future<AppResult<VoiceRecording>> finish() async => AppSuccess(wav);
  @override
  Future<void> cancel() async {
    cancels++;
  }
}

final class _Reader implements IntakeReader {
  AppResult<Intake?> nextResult = const AppSuccess(null);
  @override
  Future<AppResult<Intake>> detail(String id) async => AppSuccess(dose());
  @override
  Future<AppResult<Intake?>> next() async => nextResult;
  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      const AppSuccess([]);
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('cancellation during permission never opens the microphone after a late grant', () async {
    final grant = Completer<bool>();
    final device = _Device()..permission = grant.future;
    final recorder = MicrophoneVoiceRecorder(create: () => device);
    final start = recorder.start();
    await _settle();
    await recorder.cancel();
    grant.complete(true);
    expect((await start as AppFailure).code, 'VOICE_RECORDING_CANCELLED');
    expect(device.starts, 0);
    expect(device.disposals, 1);
  });
  test(
    'cancellation during native stream opening releases the late stream',
    () async {
      final opening = Completer<Stream<Uint8List>>();
      final device = _Device()..opening = opening.future;
      final recorder = MicrophoneVoiceRecorder(create: () => device);
      final start = recorder.start();
      await _settle();
      expect(device.starts, 1);
      await recorder.cancel();
      opening.complete(device.samples.stream);
      expect((await start as AppFailure).code, 'VOICE_RECORDING_CANCELLED');
      expect(device.cancels, 1);
      expect(device.disposals, 1);
    },
  );
  test(
    'late permission of a previous start cannot release the newer capture',
    () async {
      final grant = Completer<bool>();
      final old = _Device()..permission = grant.future;
      final current = _Device();
      var creates = 0;
      final recorder = MicrophoneVoiceRecorder(
        create: () => creates++ == 0 ? old : current,
      );
      final first = recorder.start();
      await _settle();
      expect(await recorder.start(), isA<AppSuccess<void>>());
      grant.complete(true);
      await first;
      expect(old.disposals, 1);
      expect(current.disposals, 0);
      current.samples.add(Uint8List(32));
      await _settle();
      expect(
        (await recorder.finish() as AppSuccess<VoiceRecording>)
            .value
            .bytes
            .length,
        76,
      );
      expect(current.disposals, 1);
    },
  );
  test(
    'native stream errors are contained and never uploaded as valid audio',
    () async {
      final device = _Device();
      final recorder = MicrophoneVoiceRecorder(create: () => device);
      await recorder.start();
      device.samples.addError(StateError('native recording interrupted'));
      await _settle();
      expect((await recorder.finish() as AppFailure).code, 'INVALID_AUDIO');
      expect(device.disposals, 1);
    },
  );
  VoiceBloc bloc(_Recorder recorder, _Reader reader) => VoiceBloc(
    intakeId: 'intake-1',
    detail: GetIntakeDetail(reader),
    recorder: recorder,
    confirm: ConfirmIntakeByVoice(FakeVoice()),
    next: GetNextIntake(reader),
  );
  test('repeated start taps and cancellation cannot revive a pending microphone request', () async {
    final recorder = _Recorder();
    final subject = bloc(recorder, _Reader());
    addTearDown(subject.close);
    subject.add(const VoiceRequested());
    await _settle();
    subject.add(const VoiceStarted('es-419'));
    subject.add(const VoiceStarted('es-419'));
    await _settle();
    expect(recorder.starts, 1);
    subject.add(const VoiceCancelled());
    await _settle();
    recorder.started.complete(const AppSuccess(null));
    await _settle();
    expect(subject.state.phase, VoicePhase.ready);
    expect(recorder.cancels, greaterThanOrEqualTo(2));
  });
  test(
    'closing while permission is pending never emits recording afterwards',
    () async {
      final recorder = _Recorder();
      final subject = bloc(recorder, _Reader());
      final phases = <VoicePhase>[];
      final subscription = subject.stream.listen(
        (state) => phases.add(state.phase),
      );
      subject.add(const VoiceRequested());
      await _settle();
      subject.add(const VoiceStarted('es-419'));
      await _settle();
      final closed = subject.close();
      recorder.started.complete(const AppSuccess(null));
      await closed;
      await subscription.cancel();
      expect(phases, isNot(contains(VoicePhase.recording)));
    },
  );
  test(
    'lost permissions in the post-confirmation read discard clinical content',
    () async {
      final recorder = _Recorder()..started.complete(const AppSuccess(null));
      final reader = _Reader()..nextResult = const AppFailure('ACCESS_DENIED');
      final subject = bloc(recorder, reader);
      addTearDown(subject.close);
      subject.add(const VoiceRequested());
      await _settle();
      subject.add(const VoiceStarted('es-419'));
      await _settle();
      subject.add(const VoiceStopped());
      await _settle();
      expect(subject.state.phase, VoicePhase.failure);
      expect(subject.state.errorCode, 'ACCESS_DENIED');
      expect(subject.state.intake, isNull);
      expect(subject.state.outcome, isNull);
    },
  );
}
