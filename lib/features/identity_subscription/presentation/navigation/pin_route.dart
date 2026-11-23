import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/pin/pin_bloc.dart';
import '../bloc/pin/pin_event.dart';
import '../bloc/pin/pin_state.dart';
import '../screens/pin_screen.dart';

/// Owns one [PinBloc] and reports acknowledged enrollment or access upward.
class PinRoute extends StatelessWidget {
  const PinRoute({
    super.key,
    required this.createBloc,
    required this.adultName,
    required this.onCompleted,
    this.onBack,
    this.onSessionInvalidated,
  });

  final PinBloc Function() createBloc;
  final String? adultName;

  /// Called once the server acknowledged the PIN enrollment or PIN access.
  final VoidCallback onCompleted;
  final VoidCallback? onBack;

  /// Setup only: the adult session expired or changed while enrolling.
  final VoidCallback? onSessionInvalidated;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc(),
    child: BlocConsumer<PinBloc, PinState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (state.status == PinStatus.completed) {
          onCompleted();
        } else if (state.errorCode == 'AUTHENTICATION_REQUIRED' ||
            state.errorCode == 'SESSION_CHANGED' ||
            state.errorCode == 'ACCESS_DENIED') {
          onSessionInvalidated?.call();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final bloc = context.read<PinBloc>();
        final (title, body) = _error(text, state.errorCode);
        return PinScreen(
          mode: bloc.mode,
          adultName: adultName,
          filled: state.length,
          busy:
              state.status == PinStatus.busy ||
              state.status == PinStatus.completed,
          existingPin: state.status == PinStatus.alreadyRegistered,
          locked: state.locked,
          canSubmit:
              state.canSubmit || state.status == PinStatus.alreadyRegistered,
          errorTitle: title,
          errorText: body,
          onDigit: (digit) => bloc.add(PinDigitPressed(digit)),
          onDelete: () => bloc.add(const PinDeletePressed()),
          onSubmit: state.status == PinStatus.alreadyRegistered
              ? onCompleted
              : () => bloc.add(const PinSubmitted()),
          onBack: onBack,
        );
      },
    ),
  );

  (String?, String?) _error(AppLocalizations text, String? code) =>
      switch (code) {
        null => (null, null),
        'INVALID_PIN' ||
        'INVALID_PIN_FORMAT' => (text.pinIncorrectTitle, text.pinIncorrectBody),
        'PIN_ALREADY_REGISTERED' => (
          text.pinExistingTitle,
          text.pinExistingBody,
        ),
        'PIN_LOCKED' => (text.pinLockedTitle, text.pinLockedBody),
        'NETWORK_UNAVAILABLE' => (text.pinErrorTitle, text.networkUnavailable),
        'RATE_LIMITED' => (text.pinErrorTitle, text.rateLimited),
        _ => (text.pinErrorTitle, text.pinLinkErrorBody),
      };
}
