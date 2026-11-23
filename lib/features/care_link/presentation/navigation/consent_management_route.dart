import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/consent/consent_bloc.dart';
import '../bloc/consent/consent_event.dart';
import '../bloc/consent/consent_state.dart';
import '../screens/consent_management_screen.dart';

/// Presents management only after Identity has validated full adult access.
class ConsentManagementRoute extends StatelessWidget {
  const ConsentManagementRoute({
    super.key,
    required this.createBloc,
    required this.onSessionChanged,
    required this.onSignOut,
    this.onWithdrawn,
  });
  final ConsentBloc Function() createBloc;
  final VoidCallback onSessionChanged;
  final VoidCallback onSignOut;

  /// Runs before [onSessionChanged] only after the server confirmed withdrawal.
  final VoidCallback? onWithdrawn;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc(),
    child: BlocConsumer<ConsentBloc, ConsentState>(
      listener: (context, state) {
        if (state.withdrawn) onWithdrawn?.call();
        if (state.withdrawn ||
            state.errorCode == 'AUTHENTICATION_REQUIRED' ||
            state.errorCode == 'SESSION_CHANGED') {
          onSessionChanged();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final error = switch (state.errorCode) {
          null => null,
          'NETWORK_UNAVAILABLE' => text.networkUnavailable,
          'RATE_LIMITED' => text.rateLimited,
          'ACCESS_DENIED' => text.accessDenied,
          _ => text.genericLinkError,
        };
        return ConsentManagementScreen(
          loading: state.loading,
          errorText: error,
          onSignOut: onSignOut,
          onWithdraw: () => context.read<ConsentBloc>().add(
            const ConsentWithdrawalRequested(),
          ),
        );
      },
    ),
  );
}
