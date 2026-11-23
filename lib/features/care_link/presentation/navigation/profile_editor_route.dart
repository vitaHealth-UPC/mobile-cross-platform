import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/readmodels/older_adult_profile.dart';
import '../bloc/profile_editor/profile_editor_cubit.dart';
import '../screens/profile_editor_screen.dart';

/// Owns the form state and returns only the server-acknowledged profile.
Future<OlderAdultProfile?> openProfileEditor(
  BuildContext context, {
  required ProfileEditorCubit Function() createCubit,
  required VoidCallback onSessionInvalidated,
}) => Navigator.of(context).push<OlderAdultProfile>(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => createCubit()..load(),
      child: BlocConsumer<ProfileEditorCubit, ProfileEditorState>(
        listener: (context, state) {
          if (state.saved) {
            Navigator.of(context).pop(state.profile);
          } else if (const {
            'AUTHENTICATION_REQUIRED',
            'SESSION_CHANGED',
            'ACCESS_DENIED',
          }.contains(state.errorCode)) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            onSessionInvalidated();
          }
        },
        builder: (_, state) => ProfileEditorScreen(state: state),
      ),
    ),
  ),
);
