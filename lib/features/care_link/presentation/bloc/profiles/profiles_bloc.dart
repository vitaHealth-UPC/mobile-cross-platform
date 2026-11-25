import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/caregiver_profiles_reader.dart';
import '../../../application/readmodels/caregiver_link_summary.dart';
import '../../../application/readmodels/older_adult_profile.dart';
import '../../../application/usecases/end_care_link.dart';
import '../../../application/usecases/generate_linking_code.dart';
import '../../../application/usecases/join_as_caregiver.dart';
import '../../../application/usecases/register_older_adult.dart';
import '../../../domain/entities/care_link.dart';
import 'profiles_event.dart';
import 'profiles_state.dart';

/// Coordinates the caregiver setup journey without performing adult consent.
/// Each receipt updates only its own state, preserving data when refresh fails.
final class ProfilesBloc extends Bloc<ProfilesEvent, ProfilesState> {
  ProfilesBloc({
    required this._reader,
    required this._register,
    required this._generate,
    this._end,
    this._join,
  }) : super(const ProfilesState()) {
    on<ProfilesEvent>(_handle);
  }
  final CaregiverProfilesReader _reader;
  final RegisterOlderAdult _register;
  final GenerateLinkingCode _generate;
  final EndCareLink? _end;
  final JoinAsCaregiver? _join;

  Future<void> _handle(ProfilesEvent event, Emitter<ProfilesState> emit) async {
    if (state.loading) return;
    final previous = state;
    if (event is LinkingCodeRequested && previous.profile == null) return;
    emit(
      ProfilesState(
        loading: true,
        links: previous.links,
        profile: previous.profile,
        link: previous.link,
      ),
    );
    switch (event) {
      case CaregiverJoinRequested(:final code):
        final join = _join;
        final result = join == null
            ? const AppFailure<void>('UNAVAILABLE')
            : await join(code);
        if (emit.isDone) return;
        emit(
          ProfilesState(
            links: previous.links,
            profile: previous.profile,
            link: previous.link,
            joined: result is AppSuccess<void>,
            errorCode: result is AppFailure<void> ? 'JOIN_FAILED' : null,
          ),
        );
      case CareLinkEndRequested(:final careLinkId):
        final end = _end;
        final result = end == null
            ? const AppFailure<void>('UNAVAILABLE')
            : await end(careLinkId);
        if (emit.isDone) return;
        final ended = result is AppSuccess<void>;
        emit(
          ProfilesState(
            links: ended
                ? [
                    for (final link in previous.links)
                      if (link.id != careLinkId) link,
                  ]
                : previous.links,
            profile: previous.profile,
            link: previous.link,
            ended: ended,
            errorCode: result is AppFailure<void>
                ? 'END_CARE_LINK_FAILED'
                : null,
          ),
        );
      case ProfilesRequested():
        final result = await _reader.readConfirmed();
        if (emit.isDone) return;
        emit(
          ProfilesState(
            links: result is AppSuccess<List<CaregiverLinkSummary>>
                ? result.value
                : previous.links,
            profile: previous.profile,
            link: previous.link,
            errorCode: result is AppFailure<List<CaregiverLinkSummary>>
                ? result.code
                : null,
          ),
        );
      case OlderAdultSubmitted():
        final result = await _register(event.name, event.birthDate);
        if (emit.isDone) return;
        emit(
          ProfilesState(
            links: previous.links,
            profile: result is AppSuccess<OlderAdultProfile>
                ? result.value
                : previous.profile,
            link: result is AppSuccess<OlderAdultProfile>
                ? null
                : previous.link,
            errorCode: result is AppFailure<OlderAdultProfile>
                ? result.code
                : null,
          ),
        );
      case LinkingCodeRequested():
        final result = await _generate(previous.profile!.id);
        if (emit.isDone) return;
        emit(
          ProfilesState(
            links: previous.links,
            profile: previous.profile,
            link: result is AppSuccess<CareLink> ? result.value : previous.link,
            errorCode: result is AppFailure<CareLink> ? result.code : null,
          ),
        );
    }
  }
}
