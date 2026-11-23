import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/profiles/profiles_bloc.dart';
import '../bloc/profiles/profiles_event.dart';
import '../bloc/profiles/profiles_state.dart';
import '../screens/caregiver_profiles_screen.dart';
import '../screens/link_person_screen.dart';

/// Composes caregiver setup and reports invalidated sessions to the application host.
class CaregiverSetupRoute extends StatelessWidget {
  const CaregiverSetupRoute({
    super.key,
    required this.createBloc,
    required this.onSignOut,
    required this.onSessionInvalidated,
  });
  final ProfilesBloc Function() createBloc;
  final VoidCallback onSignOut;
  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()..add(const ProfilesRequested()),
    child: BlocConsumer<ProfilesBloc, ProfilesState>(
      listener: (context, state) {
        if (state.errorCode == 'AUTHENTICATION_REQUIRED' ||
            state.errorCode == 'SESSION_CHANGED') {
          onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        final error = switch (state.errorCode) {
          null => null,
          'INVALID_NAME' => text.invalidAdultName,
          'INVALID_BIRTH_DATE' => text.invalidBirthDate,
          'NETWORK_UNAVAILABLE' => text.networkUnavailable,
          'ACCESS_DENIED' => text.accessDenied,
          'RATE_LIMITED' => text.rateLimited,
          'CARE_LINK_ALREADY_EXISTS' => text.linkAlreadyExists,
          _ => text.genericLinkError,
        };
        final bloc = context.read<ProfilesBloc>();
        final profile = state.profile;
        if (profile != null) {
          return LinkPersonScreen(
            profile: profile,
            link: state.link,
            confirmed: state.confirmed,
            loading: state.loading,
            errorText: error,
            onGenerate: () => bloc.add(const LinkingCodeRequested()),
            onRefresh: () => bloc.add(const ProfilesRequested()),
            onSignOut: onSignOut,
          );
        }
        return CaregiverProfilesScreen(
          links: state.links,
          loading: state.loading,
          errorText: error,
          onRegister: (name, date) => bloc.add(OlderAdultSubmitted(name, date)),
          onRefresh: () => bloc.add(const ProfilesRequested()),
          onSignOut: onSignOut,
        );
      },
    ),
  );
}
