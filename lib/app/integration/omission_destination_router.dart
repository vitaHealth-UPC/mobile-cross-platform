import '../../features/care_link/application/readmodels/caregiver_link_summary.dart';
import '../../features/omission_escalation/application/readmodels/push_destination.dart';
import '../../shared/common/result/app_result.dart';

/// Dispatches authorized notification destinations through the ordinary feature flows.
/// Profile reads cannot complete navigation after account change or a newer request.
final class OmissionDestinationRouter {
  OmissionDestinationRouter({
    required this.mayOpen,
    required this.sessionGeneration,
    required this.readProfiles,
    required this.openCaregiver,
    required this.openAdultDose,
    required this.openAdultHome,
    required this.onUnavailable,
  });

  final Future<bool> Function(PushDestination) mayOpen;
  final int Function() sessionGeneration;
  final Future<AppResult<List<CaregiverLinkSummary>>> Function() readProfiles;
  final Future<void> Function(CaregiverLinkSummary, String?) openCaregiver;
  final void Function(OlderAdultDoseDestination) openAdultDose;
  final void Function() openAdultHome;
  final void Function(String) onUnavailable;
  int _request = 0;
  bool _disposed = false;

  Future<void> open(PushDestination destination) async {
    if (_disposed) return;
    final request = ++_request;
    final generation = sessionGeneration();
    if (!await mayOpen(destination) || !_current(request, generation)) return;
    switch (destination) {
      case CaregiverAlertsDestination():
        final result = await readProfiles();
        if (!_current(request, generation) ||
            !await mayOpen(destination) ||
            !_current(request, generation)) {
          return;
        }
        switch (result) {
          case AppFailure(:final code):
            onUnavailable(code);
          case AppSuccess(:final value):
            final matches = value
                .where(
                  (profile) => profile.olderAdultId == destination.olderAdultId,
                )
                .toList();
            if (matches.length != 1) {
              onUnavailable('ACCESS_DENIED');
              return;
            }
            await openCaregiver(matches.single, destination.intakeId);
        }
      case OlderAdultDoseDestination():
        openAdultDose(destination);
      case OlderAdultHomeDestination():
        openAdultHome();
    }
  }

  bool _current(int request, int generation) =>
      !_disposed && request == _request && generation == sessionGeneration();

  void dispose() {
    _disposed = true;
    _request++;
  }
}
