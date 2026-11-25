import '../../../application/readmodels/caregiver_link_summary.dart';
import '../../../application/readmodels/older_adult_profile.dart';
import '../../../domain/entities/care_link.dart';

/// Immutable caregiver setup progress; no bearer credential enters this state.
final class ProfilesState {
  const ProfilesState({
    this.loading = false,
    this.links = const [],
    this.profile,
    this.link,
    this.errorCode,
    this.ended = false,
    this.joined = false,
  });
  final bool loading;
  final List<CaregiverLinkSummary> links;
  final OlderAdultProfile? profile;
  final CareLink? link;
  final String? errorCode;

  /// The last request removed a person from the list.
  final bool ended;

  /// The last request asked to care for another caregiver's relative.
  final bool joined;

  /// Whether the server's refreshed consented list includes the current profile.
  bool get confirmed =>
      profile != null && links.any((item) => item.olderAdultId == profile!.id);
}
