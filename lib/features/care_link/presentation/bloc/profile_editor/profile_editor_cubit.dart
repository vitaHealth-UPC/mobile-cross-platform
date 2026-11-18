import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/caregiver_profile_editor.dart';
import '../../../application/readmodels/older_adult_profile.dart';
import '../../../application/usecases/update_caregiver_profile.dart';

/// Profile and operation phase of the caregiver's basic-data form.
final class ProfileEditorState {
  const ProfileEditorState({
    this.profile,
    this.loading = false,
    this.saving = false,
    this.saved = false,
    this.errorCode,
  });
  final OlderAdultProfile? profile;
  final bool loading;
  final bool saving;
  final bool saved;
  final String? errorCode;
}

/// Owns one edit operation; only a validated server receipt closes the form.
/// Closing the route makes late responses inert, and concurrent saves are ignored.
final class ProfileEditorCubit extends Cubit<ProfileEditorState> {
  ProfileEditorCubit({
    required this._editor,
    required this._update,
    required this.olderAdultId,
  }) : super(const ProfileEditorState());

  final CaregiverProfileEditor _editor;
  final UpdateCaregiverProfile _update;
  final String olderAdultId;

  Future<void> load() async {
    if (state.loading || state.saving || isClosed) return;
    emit(const ProfileEditorState(loading: true));
    final result = await _editor.readProfile(olderAdultId);
    if (isClosed) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(ProfileEditorState(profile: value));
      case AppFailure(:final code):
        emit(ProfileEditorState(errorCode: code));
    }
  }

  Future<void> save(String fullName, DateTime birthDate) async {
    final profile = state.profile;
    if (profile == null || state.saving || state.saved || isClosed) return;
    emit(ProfileEditorState(profile: profile, saving: true));
    final result = await _update(olderAdultId, fullName, birthDate);
    if (isClosed) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(ProfileEditorState(profile: value, saved: true));
      case AppFailure(:final code):
        final lostAccess = const {
          'AUTHENTICATION_REQUIRED',
          'ACCESS_DENIED',
          'SESSION_CHANGED',
          'INVALID_RESPONSE',
        }.contains(code);
        emit(
          ProfileEditorState(
            profile: lostAccess ? null : profile,
            errorCode: code,
          ),
        );
    }
  }
}
