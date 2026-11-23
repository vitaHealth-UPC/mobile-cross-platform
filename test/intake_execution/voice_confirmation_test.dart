import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:record/record.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/ports/voice_confirmation.dart';
import 'package:tata/features/intake_execution/application/ports/voice_recorder.dart';
import 'package:tata/features/intake_execution/application/readmodels/voice_confirmation_result.dart';
import 'package:tata/features/intake_execution/application/readmodels/voice_recording.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake_by_voice.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/audio/microphone_voice_recorder.dart';
import 'package:tata/features/intake_execution/infrastructure/audio/pcm16_wav_encoder.dart';
import 'package:tata/features/intake_execution/infrastructure/remote/intake_api.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_voice_confirmation.dart';
import 'package:tata/features/intake_execution/presentation/bloc/dose/dose_state.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_bloc.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_event.dart';
import 'package:tata/features/intake_execution/presentation/bloc/voice/voice_state.dart';
import 'package:tata/features/intake_execution/presentation/screens/voice_confirmation_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/memory_session_store.dart';

final scheduled = DateTime.utc(2026, 11, 13, 13);

Intake dose({IntakeStatus status = IntakeStatus.pending}) => Intake(
  id: 'intake-1',
  olderAdultId: 'adult-A',
  medicationName: 'Losartán',
  dose: '1 tableta',
  scheduledAt: scheduled,
  status: status,
  confirmedAt: status == IntakeStatus.confirmed || status == IntakeStatus.late
      ? scheduled
      : null,
);

final wav = VoiceRecording(Uint8List.fromList(List.filled(64, 1)));

final class FakeRecorder implements VoiceRecorder {
  AppResult<void> startResult = const AppSuccess(null);
  AppResult<VoiceRecording> finishResult = AppSuccess(wav);
  int cancels = 0;
  int finishes = 0;

  @override
  Future<AppResult<void>> start() async => startResult;
  @override
  Future<AppResult<VoiceRecording>> finish() async {
    finishes++;
    return finishResult;
  }

  @override
  Future<void> cancel() async => cancels++;
}

final class FakeVoice implements VoiceConfirmation {
  AppResult<VoiceConfirmationResult> result = AppSuccess(
    VoiceConfirmationResult(
      VoiceRecognition.confirmed,
      intake: dose(status: IntakeStatus.confirmed),
    ),
  );
  final languages = <String>[];

  @override
  Future<AppResult<VoiceConfirmationResult>> confirmByVoice(
    String intakeId,
    VoiceRecording recording,
    String language,
  ) async {
    languages.add(language);
    return result;
  }
}

final class FakeReader implements IntakeReader {
  List<AppResult<Intake>> details = [AppSuccess(dose())];
  @override
  Future<AppResult<Intake>> detail(String intakeId) async =>
      details.length > 1 ? details.removeAt(0) : details.single;
  @override
  Future<AppResult<Intake?>> next() async => const AppSuccess(null);
  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      const AppSuccess([]);
}

final class FakeAudioRecorder extends Fake implements AudioRecorder {
  FakeAudioRecorder({this.permitted = true});
  final bool permitted;
  final samples = StreamController<Uint8List>();
  var disposed = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => permitted;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    expect(config.encoder, AudioEncoder.pcm16bits);
    expect(config.sampleRate, 16000);
    expect(config.numChannels, 1);
    return samples.stream;
  }

  @override
  Future<String?> stop() async {
    await samples.close();
    return null;
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  test('WAV header matches what the server validates', () {
    final pcm = Uint8List.fromList(List.generate(320, (i) => i % 256));
    final out = Pcm16WavEncoder.encode(pcm);
    final header = ByteData.sublistView(out);

    expect(ascii.decode(out.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(out.sublist(8, 16)), 'WAVEfmt ');
    expect(ascii.decode(out.sublist(36, 40)), 'data');
    expect(header.getUint32(4, Endian.little), out.length - 8);
    expect(header.getUint16(20, Endian.little), 1);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), 16000);
    expect(header.getUint32(28, Endian.little), 32000);
    expect(header.getUint16(34, Endian.little), 16);
    expect(header.getUint32(40, Endian.little), 320);
    expect(out.sublist(44), pcm);
  });

  group('microphone', () {
    test('keeps at most the time limit and only whole samples', () async {
      final device = FakeAudioRecorder();
      final recorder = MicrophoneVoiceRecorder(
        create: () => device,
        maxDuration: const Duration(milliseconds: 1),
      );

      expect(await recorder.start(), isA<AppSuccess<void>>());
      device.samples.add(Uint8List(40));
      await Future<void>.delayed(Duration.zero);
      final result = await recorder.finish();

      final bytes = (result as AppSuccess<VoiceRecording>).value.bytes;
      expect(bytes.length, 44 + 32);
      expect(device.disposed, isTrue);
    });

    test('a refused permission never opens the microphone', () async {
      final device = FakeAudioRecorder(permitted: false);
      final recorder = MicrophoneVoiceRecorder(create: () => device);

      final result = await recorder.start();

      expect((result as AppFailure).code, 'MICROPHONE_PERMISSION_DENIED');
      expect(device.disposed, isTrue);
    });

    test('silence is not sent', () async {
      final device = FakeAudioRecorder();
      final recorder = MicrophoneVoiceRecorder(create: () => device);
      await recorder.start();

      final result = await recorder.finish();

      expect((result as AppFailure).code, 'INVALID_AUDIO');
    });
  });

  group('server', () {
    final store = MemorySessionStore(
      StoredSession(
        accessToken: 'adult-token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner(
          'adult-A',
          SessionRole.olderAdult,
          careLinkId: 'link-A',
        ),
      ),
    );

    RemoteVoiceConfirmation repo(
      Future<http.Response> Function(http.BaseRequest) handler,
    ) {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient.streaming((request, body) async {
          final response = await handler(request);
          return http.StreamedResponse(
            Stream.value(response.bodyBytes),
            response.statusCode,
            headers: response.headers,
          );
        }),
      );
      addTearDown(client.close);
      return RemoteVoiceConfirmation(api: IntakeApi(client), store: store);
    }

    Map<String, Object?> evidence(String status) => {
      'id': 'intake-1',
      'medicationId': 'medication-1',
      'treatmentId': 'treatment-1',
      'olderAdultId': 'adult-A',
      'medicationName': 'Losartán',
      'dose': '1 tableta',
      'scheduledAt': '2026-11-13T13:00:00Z',
      'status': status,
      'confirmedAt': status == 'PENDING' ? null : '2026-11-13T12:58:00Z',
    };

    http.Response json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

    test('uploads the WAV as the audio part with the adult token', () async {
      final result = await repo((request) async {
        final multipart = request as http.MultipartRequest;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/intakes/intake-1/voice-confirmation');
        expect(request.url.queryParameters, {'language': 'es-419'});
        expect(request.headers['Authorization'], 'Bearer adult-token');
        expect(multipart.files.single.field, 'audio');
        expect(multipart.files.single.filename, 'confirmation.wav');
        expect(multipart.files.single.contentType.mimeType, 'audio/wav');
        return json({
          'status': 'CONFIRMED',
          'transcript': 'confirmo que tomé losartán',
          'confidence': 0.9,
          'intake': evidence('CONFIRMED'),
        });
      }).confirmByVoice('intake-1', wav, 'es-419');

      final value = (result as AppSuccess<VoiceConfirmationResult>).value;
      expect(value.recognition, VoiceRecognition.confirmed);
      expect(value.intake!.taken, isTrue);
    });

    test('an unrecognized phrase is an answer, not a failure', () async {
      final result = await repo(
        (_) async => json({'status': 'NOT_RECOGNIZED', 'confidence': 0}),
      ).confirmByVoice('intake-1', wav, 'es-419');

      expect(
        (result as AppSuccess<VoiceConfirmationResult>).value.recognition,
        VoiceRecognition.notRecognized,
      );
    });

    test('a recorded outcome without matching evidence is rejected', () async {
      final result = await repo(
        (_) async =>
            json({'status': 'CONFIRMED', 'intake': evidence('PENDING')}),
      ).confirmByVoice('intake-1', wav, 'es-419');

      expect(result, isA<AppFailure<VoiceConfirmationResult>>());
    });

    test('voice turned off keeps its stable code', () async {
      final result = await repo(
        (_) async => json({'title': 'VOICE_CONFIRMATION_DISABLED'}, 409),
      ).confirmByVoice('intake-1', wav, 'es-419');

      expect((result as AppFailure).code, 'VOICE_CONFIRMATION_DISABLED');
    });

    test('use case refuses empty audio and unknown locales', () async {
      final voice = FakeVoice();
      final confirm = ConfirmIntakeByVoice(voice);

      final empty = await confirm(
        'intake-1',
        VoiceRecording(Uint8List(0)),
        'es-419',
      );
      final locale = await confirm('intake-1', wav, 'fr-FR');

      expect((empty as AppFailure).code, 'INVALID_AUDIO');
      expect((locale as AppFailure).code, 'INVALID_AUDIO');
      expect(voice.languages, isEmpty);
    });
  });

  group('voice bloc', () {
    late FakeRecorder recorder;
    late FakeVoice voice;
    late FakeReader reader;
    late VoiceBloc bloc;

    setUp(() async {
      recorder = FakeRecorder();
      voice = FakeVoice();
      reader = FakeReader();
      bloc = VoiceBloc(
        intakeId: 'intake-1',
        detail: GetIntakeDetail(reader),
        recorder: recorder,
        confirm: ConfirmIntakeByVoice(voice),
        next: GetNextIntake(reader),
        maxListening: const Duration(milliseconds: 20),
      )..add(const VoiceRequested());
      await bloc.stream.firstWhere((s) => s.phase == VoicePhase.ready);
    });

    tearDown(() => bloc.close());

    Future<VoiceState> speak() async {
      bloc.add(const VoiceStarted('es-419'));
      await bloc.stream.firstWhere((s) => s.phase == VoicePhase.recording);
      bloc.add(const VoiceStopped());
      return bloc.stream.firstWhere(
        (s) =>
            s.phase != VoicePhase.processing && s.phase != VoicePhase.recording,
      );
    }

    test('a recognized phrase ends with the recorded outcome', () async {
      final state = await speak();

      expect(state.outcome, ConfirmationOutcome.confirmed);
      expect(voice.languages, ['es-419']);
    });

    test('the server decides a late dose', () async {
      voice.result = AppSuccess(
        VoiceConfirmationResult(
          VoiceRecognition.confirmed,
          intake: dose(status: IntakeStatus.late),
        ),
      );

      expect((await speak()).outcome, ConfirmationOutcome.late);
    });

    test('an already taken dose is not recorded twice', () async {
      voice.result = AppSuccess(
        VoiceConfirmationResult(
          VoiceRecognition.alreadyConfirmed,
          intake: dose(status: IntakeStatus.confirmed),
        ),
      );

      expect((await speak()).outcome, ConfirmationOutcome.alreadyConfirmed);
    });

    for (final (recognition, phase) in [
      (VoiceRecognition.notRecognized, VoicePhase.notRecognized),
      (VoiceRecognition.notValidated, VoicePhase.notRecognized),
      (VoiceRecognition.providerUnavailable, VoicePhase.unavailable),
    ]) {
      test('$recognition shows ${phase.name} and allows a retry', () async {
        voice.result = AppSuccess(VoiceConfirmationResult(recognition));

        final state = await speak();

        expect(state.phase, phase);
        expect(state.outcome, isNull);
        expect(state.canStart, isTrue);
      });
    }

    for (final (code, phase) in [
      ('VOICE_CONFIRMATION_DISABLED', VoicePhase.disabled),
      ('NETWORK_UNAVAILABLE', VoicePhase.offline),
    ]) {
      test('$code shows ${phase.name}', () async {
        voice.result = AppFailure(code);

        expect((await speak()).phase, phase);
      });
    }

    test('a dose omitted meanwhile is shown as preserved', () async {
      voice.result = const AppFailure('INTAKE_NOT_CONFIRMABLE');
      reader.details = [AppSuccess(dose(status: IntakeStatus.omitted))];

      expect((await speak()).outcome, ConfirmationOutcome.omissionPreserved);
    });

    test('a refused microphone explains how to continue', () async {
      recorder.startResult = const AppFailure('MICROPHONE_PERMISSION_DENIED');

      bloc.add(const VoiceStarted('es-419'));
      final state = await bloc.stream.first;

      expect(state.phase, VoicePhase.permissionDenied);
    });

    test('listening stops by itself and sends the audio', () async {
      bloc.add(const VoiceStarted('es-419'));
      final state = await bloc.stream.firstWhere((s) => s.outcome != null);

      expect(recorder.finishes, 1);
      expect(state.outcome, ConfirmationOutcome.confirmed);
    });

    test('cancelling discards the audio and sends nothing', () async {
      bloc.add(const VoiceStarted('es-419'));
      await bloc.stream.firstWhere((s) => s.phase == VoicePhase.recording);
      bloc.add(const VoiceCancelled());
      await bloc.stream.firstWhere((s) => s.phase == VoicePhase.ready);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(recorder.cancels, 1);
      expect(recorder.finishes, 0);
      expect(voice.languages, isEmpty);
    });

    test('closing the screen releases the microphone', () async {
      await bloc.close();

      expect(recorder.cancels, greaterThan(0));
    });
  });

  group('screen', () {
    Widget screen(VoiceState state, {VoidCallback? onStop}) => MaterialApp(
      theme: TataTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VoiceConfirmationScreen(
        state: state,
        phrase: '“Confirmo que tomé Losartán.”',
        onStart: () {},
        onStop: onStop ?? () {},
        onCancel: () {},
        onBack: () {},
      ),
    );

    testWidgets('while listening offers cancel and stop on the orb', (
      tester,
    ) async {
      var stopped = false;
      await tester.pumpWidget(
        screen(
          VoiceState(phase: VoicePhase.recording, intake: dose()),
          onStop: () => stopped = true,
        ),
      );

      expect(find.text('Escuchando...'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Terminar y enviar'));
      expect(stopped, isTrue);
    });

    testWidgets('a failed attempt says nothing was recorded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        screen(VoiceState(phase: VoicePhase.notRecognized, intake: dose())),
      );

      expect(find.text('No reconocida'), findsOneWidget);
      expect(find.text('Confirmación no registrada'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
