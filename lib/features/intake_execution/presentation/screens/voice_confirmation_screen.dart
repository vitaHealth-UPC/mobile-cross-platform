import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../bloc/voice/voice_state.dart';

/// Figma 563:242 (listening) and 563:2707 (not recognized). The orb also
/// works as the stop button, so a slow speaker never depends on the timer.
class VoiceConfirmationScreen extends StatelessWidget {
  const VoiceConfirmationScreen({
    super.key,
    required this.state,
    required this.phrase,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
    required this.onBack,
    this.onListenPhrase,
  });

  final VoiceState state;
  final String phrase;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final VoidCallback onBack;
  final VoidCallback? onListenPhrase;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final phase = state.phase;
    final recording = phase == VoicePhase.recording;
    final (status, statusColor) = switch (phase) {
      VoicePhase.recording => (text.voiceListening, TataColors.primary),
      VoicePhase.processing => (text.voiceProcessing, TataColors.primary),
      VoicePhase.notRecognized => (
        text.voiceNotRecognized,
        TataColors.errorText,
      ),
      VoicePhase.permissionDenied => (
        text.voicePermissionOff,
        TataColors.errorText,
      ),
      VoicePhase.unavailable ||
      VoicePhase.disabled ||
      VoicePhase.offline => (text.voiceUnavailable, TataColors.errorText),
      _ => (text.voiceReady, TataColors.primary),
    };
    final hint = switch (phase) {
      VoicePhase.notRecognized => text.voiceRetryHint,
      VoicePhase.permissionDenied => text.voicePermissionHint,
      VoicePhase.unavailable => text.voiceUnavailableHint,
      VoicePhase.disabled => text.voiceDisabledHint,
      VoicePhase.offline => text.voiceOfflineHint,
      _ => null,
    };
    return Scaffold(
      backgroundColor: TataColors.background,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 16),
          child: recording
              ? OutlinedButton.icon(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.white,
                    foregroundColor: TataColors.ink,
                    side: const BorderSide(color: TataColors.border),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.close, size: 20),
                  label: Text(
                    text.voiceCancel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: state.canStart ? onStart : null,
                  child: Text(
                    phase == VoicePhase.processing
                        ? text.voiceProcessing
                        : phase == VoicePhase.ready
                        ? text.voiceStart
                        : text.voiceRetry,
                  ),
                ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 22, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                tooltip: text.back,
                icon: const Icon(Icons.chevron_left),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                text.voiceTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 30,
                  color: TataColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text.voiceSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: TataColors.muted),
            ),
            const SizedBox(height: 28),
            Center(
              child: _Orb(
                active: recording,
                busy: phase == VoicePhase.processing,
                semantics: recording ? text.voiceStopSemantics : null,
                onTap: recording ? onStop : null,
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: TataColors.lavender,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status,
                        style: TextStyle(fontSize: 14, color: statusColor),
                      ),
                      const SizedBox(width: 10),
                      const ExcludeSemantics(child: _Bars()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _PhraseCard(
              label: text.voiceSuggested,
              phrase: phrase,
              listenLabel: text.voiceListen,
              onListen: onListenPhrase,
            ),
            if (hint case final message?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TataColors.errorSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.voiceNotSaved,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TataColors.errorText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TataColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.active,
    required this.busy,
    this.semantics,
    this.onTap,
  });

  final bool active;
  final bool busy;
  final String? semantics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semantics,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 244,
          height: 244,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFFEDE7FD) : const Color(0xFFF2EEFD),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 186,
            height: 186,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6DFFB),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 134,
              height: 134,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22173B70),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: busy
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(
                      Icons.mic_none_rounded,
                      size: 58,
                      color: TataColors.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final height in const [10.0, 18.0, 26.0, 18.0, 10.0])
        Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF8C7BE0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    ],
  );
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.label,
    required this.phrase,
    required this.listenLabel,
    this.onListen,
  });

  final String label;
  final String phrase;
  final String listenLabel;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E8), Color(0xFFFCEBD9)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14173B70),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
              ),
              if (onListen != null)
                IconButton(
                  onPressed: onListen,
                  tooltip: listenLabel,
                  style: IconButton.styleFrom(
                    backgroundColor: TataColors.lavender,
                  ),
                  icon: const Icon(
                    Icons.volume_up_outlined,
                    size: 20,
                    color: TataColors.primary,
                  ),
                ),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  margin: const EdgeInsets.only(right: 12),
                  color: const Color(0xFFC9BEF2),
                ),
                Expanded(
                  child: Text(
                    phrase,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: TataColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
