import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/adult_access_redemption.dart';
import '../../domain/entities/care_link.dart';
import '../bloc/consent/consent_bloc.dart';
import '../bloc/consent/consent_event.dart';
import '../bloc/consent/consent_state.dart';
import '../screens/consent_screen.dart';
import '../screens/invitation_screen.dart';

/// Separates anonymous invitation collection from the restored consent-only route.
class ConsentRoute extends StatelessWidget {
  const ConsentRoute({
    super.key,
    required this.createBloc,
    this.invitationEntry = false,
    required this.onSessionChanged,
    required this.onSignOut,
    this.onAdultIdentified,
  });
  final ConsentBloc Function() createBloc;
  final bool invitationEntry;
  final VoidCallback onSessionChanged;
  final VoidCallback onSignOut;

  /// The host remembers the adult on this device; the route then closes with
  /// `'pin'` when the PIN must be entered or `true` when a session exists.
  final Future<void> Function(AdultAccessRedemption redemption)?
  onAdultIdentified;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final bloc = createBloc();
      if (!invitationEntry) bloc.add(const ConsentRequested());
      return bloc;
    },
    child: BlocConsumer<ConsentBloc, ConsentState>(
      listener: (context, state) async {
        if (state.redemption case final redemption?) {
          final navigator = Navigator.of(context);
          await onAdultIdentified?.call(redemption);
          navigator.pop(redemption.pinRegistered ? 'pin' : true);
          return;
        }
        if (state.errorCode == 'AUTHENTICATION_REQUIRED' ||
            state.errorCode == 'SESSION_CHANGED') {
          onSessionChanged();
        } else if (state.link != null &&
            !state.loading &&
            state.errorCode == null) {
          if (invitationEntry) {
            Navigator.of(context).pop(true);
          } else if (state.link!.status == CareLinkStatus.confirmed ||
              state.link!.status == CareLinkStatus.revoked) {
            onSessionChanged();
          }
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final error = switch (state.errorCode) {
          null => null,
          'INVALID_LINKING_CODE' => text.invalidInvitation,
          'LINKING_CODE_EXPIRED_OR_USED' => text.expiredInvitation,
          'NETWORK_UNAVAILABLE' => text.networkUnavailable,
          'RATE_LIMITED' => text.rateLimited,
          _ => text.genericLinkError,
        };
        final title = switch (state.errorCode) {
          'INVALID_LINKING_CODE' ||
          'LINKING_CODE_EXPIRED_OR_USED' => text.linkFailedTitle,
          _ => null,
        };
        final bloc = context.read<ConsentBloc>();
        if (invitationEntry) {
          return InvitationScreen(
            loading: state.loading,
            errorText: error,
            errorTitle: title,
            onSubmit: (text) => bloc.add(InvitationSubmitted(text)),
          );
        }
        return ConsentScreen(
          loading: state.loading,
          ready: state.link != null,
          errorText: error,
          errorTitle: title,
          onDecision: (value) => bloc.add(ConsentDecisionSubmitted(value)),
          onRetry: () => bloc.add(const ConsentRequested()),
          onSignOut: onSignOut,
        );
      },
    ),
  );
}
