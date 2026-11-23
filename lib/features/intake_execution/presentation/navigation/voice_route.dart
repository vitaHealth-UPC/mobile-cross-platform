import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../../application/ports/voice_confirmation.dart';
import '../bloc/voice/voice_bloc.dart';
import '../bloc/voice/voice_event.dart';
import '../bloc/voice/voice_state.dart';
import '../screens/dose_outcome_screen.dart';
import '../screens/voice_confirmation_screen.dart';

/// Owns one [VoiceBloc]. Listening starts as soon as the dose is shown, since
/// the adult chose voice on the previous screen, and stops when the app goes
/// to the background so the microphone is never left open.
class VoiceRoute extends StatefulWidget {
  const VoiceRoute({
    super.key,
    required this.createBloc,
    required this.onBack,
    required this.onBackHome,
    required this.onSessionInvalidated,
    this.speaker,
    this.clock = DateTime.now,
  });

  final VoiceBloc Function() createBloc;
  final VoidCallback onBack;
  final VoidCallback onBackHome;
  final VoidCallback onSessionInvalidated;
  final PhraseSpeaker? speaker;
  final Clock clock;

  @override
  State<VoiceRoute> createState() => _VoiceRouteState();
}

class _VoiceRouteState extends State<VoiceRoute> {
  late final VoiceBloc _bloc;
  late final AppLifecycleListener _lifecycle;
  var _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const VoiceRequested());
    _lifecycle = AppLifecycleListener(
      onPause: () => _bloc.add(const VoiceCancelled()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    widget.speaker?.stop();
    _bloc.close();
    super.dispose();
  }

  String _language(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en-US' : 'es-419';

  void _start(BuildContext context) {
    widget.speaker?.stop();
    _bloc.add(VoiceStarted(_language(context)));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<VoiceBloc, VoiceState>(
      listener: (context, state) {
        if (const {
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
          'ACCESS_DENIED',
        }.contains(state.errorCode)) {
          widget.onSessionInvalidated();
          return;
        }
        if (!_autoStarted &&
            state.phase == VoicePhase.ready &&
            state.canStart) {
          _autoStarted = true;
          _start(context);
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final intake = state.intake;
        if ((intake, state.outcome) case (final done?, final outcome?)) {
          return DoseOutcomeScreen(
            outcome: outcome,
            intake: done,
            next: state.next,
            now: widget.clock(),
            onBackHome: widget.onBackHome,
          );
        }
        if (state.phase == VoicePhase.failure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text.doseErrorTitle),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _bloc.add(const VoiceRequested()),
                    child: Text(text.homeRetry),
                  ),
                  TextButton(onPressed: widget.onBack, child: Text(text.back)),
                ],
              ),
            ),
          );
        }
        if (intake == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: text.doseLoading,
              ),
            ),
          );
        }
        final phrase = text.voicePhrase(intake.medicationName);
        final speaker = widget.speaker;
        return PopScope(
          canPop: state.phase != VoicePhase.processing,
          child: VoiceConfirmationScreen(
            state: state,
            phrase: phrase,
            onStart: () => _start(context),
            onStop: () => _bloc.add(const VoiceStopped()),
            onCancel: () => _bloc.add(const VoiceCancelled()),
            onBack: () {
              _bloc.add(const VoiceCancelled());
              widget.onBack();
            },
            onListenPhrase:
                speaker == null || state.phase == VoicePhase.recording
                ? null
                : () => speaker.speak(
                    phrase.replaceAll(RegExp('[“”"]'), ''),
                    _language(context) == 'en-US' ? 'en-US' : 'es-US',
                  ),
          ),
        );
      },
    ),
  );
}
