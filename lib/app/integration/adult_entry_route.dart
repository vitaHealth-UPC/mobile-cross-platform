import 'package:flutter/material.dart';

import '../../features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import '../../features/care_link/presentation/bloc/consent/consent_bloc.dart';
import '../../features/care_link/presentation/navigation/consent_management_route.dart';
import '../../features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import '../../features/identity_subscription/application/readmodels/remembered_adult.dart';
import '../../features/identity_subscription/presentation/bloc/pin/pin_bloc.dart';
import '../../features/identity_subscription/presentation/navigation/pin_route.dart';
import '../../features/intake_execution/application/ports/intake_sync.dart';
import '../../features/intake_execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../../features/intake_execution/presentation/bloc/dose/dose_bloc.dart';
import '../../features/intake_execution/presentation/bloc/home/home_bloc.dart';
import '../../features/intake_execution/presentation/navigation/adult_home_route.dart';
import '../../features/intake_execution/presentation/navigation/agenda_route.dart';
import '../../features/intake_execution/presentation/navigation/dose_route.dart';
import '../../features/omission_escalation/application/services/omission_push_facade.dart';
import '../../features/omission_escalation/presentation/widgets/follow_omission_push.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../l10n/generated/app_localizations.dart';

/// Entry for a validated full adult session, composing three contexts:
/// Identity enrolls the PIN once per device, Intake shows the home and
/// Care Link manages consent from the "More" menu.
class AdultEntryRoute extends StatefulWidget {
  const AdultEntryRoute({
    super.key,
    required this.olderAdultId,
    required this.readRemembered,
    required this.remember,
    required this.forget,
    required this.readAdultName,
    required this.createPinSetupBloc,
    required this.createHomeBloc,
    required this.createAgendaBloc,
    required this.createDoseBloc,
    required this.createConsentBloc,
    required this.onSignOut,
    required this.onSessionChanged,
    this.intakeSync,
    this.treatments,
    this.preferences,
    this.monitoring,
    this.push,
  });

  final String olderAdultId;
  final Future<RememberedAdult?> Function() readRemembered;
  final Future<void> Function(RememberedAdult adult) remember;

  /// Removes the device PIN shortcut; withdrawn consent makes it unusable.
  final Future<void> Function() forget;

  /// Returns the adult's display name, or null when it cannot be read.
  final Future<String?> Function() readAdultName;
  final PinBloc Function() createPinSetupBloc;
  final HomeBloc Function() createHomeBloc;
  final AgendaBloc Function() createAgendaBloc;
  final DoseBloc Function(String intakeId) createDoseBloc;
  final ConsentBloc Function() createConsentBloc;
  final IntakeSync? intakeSync;
  final VoidCallback onSignOut;

  /// Asks Identity to revalidate access after expiry, change or withdrawal.
  final VoidCallback onSessionChanged;

  /// Optional Treatment Management entry: the read-only medication catalog.
  final TreatmentNavigation? treatments;

  /// Optional Accessibility & Preferences entry.
  final PreferencesNavigation? preferences;

  /// Optional Family Monitoring entry: the adult's own notes.
  final FamilyMonitoringNavigation? monitoring;

  /// Optional Omission & Escalation entry: follows this adult's reinforced reminders.
  final OmissionPushFacade? push;

  @override
  State<AdultEntryRoute> createState() => _AdultEntryRouteState();
}

enum _Phase { loading, pinSetup, home }

class _AdultEntryRouteState extends State<AdultEntryRoute> {
  _Phase _phase = _Phase.loading;
  String? _name;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  /// Storage or profile failures fall back to setup without a name; the server
  /// answers PIN_ALREADY_REGISTERED when this adult already enrolled elsewhere.
  Future<void> _resolve() async {
    RememberedAdult? remembered;
    try {
      remembered = await widget.readRemembered();
    } on Exception {
      remembered = null;
    }
    final known = remembered?.id == widget.olderAdultId;
    final name = known && remembered?.name != null
        ? remembered?.name
        : await widget.readAdultName();
    if (!mounted) return;
    setState(() {
      _name = name;
      _phase = known ? _Phase.home : _Phase.pinSetup;
    });
  }

  Future<void> _pinSaved() async {
    try {
      await widget.remember(
        RememberedAdult(id: widget.olderAdultId, name: _name),
      );
    } on Exception {
      // The enrollment succeeded; only the device shortcut is missing.
    }
    if (mounted) setState(() => _phase = _Phase.home);
  }

  void _openMore(BuildContext context) {
    final text = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.treatments != null)
              ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(text.tmMyMedicationsTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openMedications(this.context);
                },
              ),
            if (widget.monitoring != null)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(text.adultTabNotes),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openNotes(this.context);
                },
              ),
            if (widget.preferences != null)
              ListTile(
                leading: const Icon(Icons.accessibility_new),
                title: Text(text.pfAccessibilityTitle),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  widget.preferences!.openAccessibility(
                    context,
                    widget.olderAdultId,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(text.homeCareLink),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openConsent(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(text.homeSwitchAccount),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Leaves any intake screen for the home before Identity revalidates access.
  void _leaveForRevalidation(BuildContext routeContext) {
    Navigator.of(routeContext).popUntil((route) => route.isFirst);
    widget.onSessionChanged();
  }

  Future<void> _openMedications(BuildContext context) async {
    final treatments = widget.treatments;
    if (treatments == null) return;
    final navigator = Navigator.of(context);
    void home() => navigator.popUntil((route) => route.isFirst);
    await treatments.openMyMedications(
      context,
      widget.onSessionChanged,
      onHome: home,
      onAgenda: () {
        home();
        _openAgenda(this.context);
      },
      onMore: () {
        home();
        _openMore(this.context);
      },
      onDose: (id) => _openDose(this.context, id),
    );
  }

  Future<void> _openDose(BuildContext context, String intakeId) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => DoseRoute(
            createBloc: () => widget.createDoseBloc(intakeId),
            onMedications: widget.treatments == null
                ? null
                : () {
                    Navigator.of(routeContext)
                        .popUntil((route) => route.isFirst);
                    _openMedications(this.context);
                  },
            onAgenda: () {
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
              _openAgenda(this.context);
            },
            onBack: () => Navigator.of(routeContext).pop(),
            onBackHome: () =>
                Navigator.of(routeContext).popUntil((route) => route.isFirst),
            onSessionInvalidated: () => _leaveForRevalidation(routeContext),
            onMore: () {
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
              _openMore(this.context);
            },
          ),
        ),
      );

  /// The adult's own notes; their bar returns to the home or to the other destinations.
  Future<void> _openNotes(BuildContext context) {
    final monitoring = widget.monitoring;
    if (monitoring == null) return Future<void>.value();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) {
          void home() =>
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
          return monitoring.personalNotes(
            onHome: home,
            onMedications: widget.treatments == null
                ? null
                : () {
                    home();
                    _openMedications(this.context);
                  },
            onAgenda: () {
              home();
              _openAgenda(this.context);
            },
            onMore: () {
              home();
              _openMore(this.context);
            },
            onSignIn: () => _leaveForRevalidation(routeContext),
          );
        },
      ),
    );
  }

  Future<void> _openAgenda(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => AgendaRoute(
            createBloc: widget.createAgendaBloc,
            onMedications: widget.treatments == null
                ? null
                : () {
                    Navigator.of(routeContext)
                        .popUntil((route) => route.isFirst);
                    _openMedications(this.context);
                  },
            onOpenDose: (intakeId) => _openDose(routeContext, intakeId),
            onBack: () => Navigator.of(routeContext).pop(),
            onSessionInvalidated: () => _leaveForRevalidation(routeContext),
            onMore: () {
              Navigator.of(routeContext).popUntil((route) => route.isFirst);
              _openMore(this.context);
            },
          ),
        ),
      );

  /// Forgets the shortcut only when it belongs to this adult.
  Future<void> _forgetShortcut() async {
    try {
      final remembered = await widget.readRemembered();
      if (remembered?.id == widget.olderAdultId) await widget.forget();
    } on Exception {
      // PIN access will be rejected by the server; only the shortcut lingers.
    }
  }

  void _openConsent(BuildContext context) {
    var withdrawn = false;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => ConsentManagementRoute(
          createBloc: widget.createConsentBloc,
          onWithdrawn: () => withdrawn = true,
          onSessionChanged: () async {
            Navigator.of(routeContext).pop();
            // Forget first: revalidation shows the login, which rereads the shortcut.
            if (withdrawn) await _forgetShortcut();
            widget.onSessionChanged();
          },
          onSignOut: () {
            Navigator.of(routeContext).pop();
            widget.onSignOut();
          },
        ),
      ),
    );
  }

  /// Follows this adult's reminders while the home is shown, when push is configured.
  Widget _following(Widget child) {
    final push = widget.push;
    if (push == null) return child;
    return FollowOmissionPush(
      followKey: widget.olderAdultId,
      follow: () => push.followAdultReminders(widget.olderAdultId, _name ?? ''),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
    _Phase.loading => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    _Phase.pinSetup => PinRoute(
      createBloc: widget.createPinSetupBloc,
      adultName: _name,
      onCompleted: _pinSaved,
      onSessionInvalidated: widget.onSessionChanged,
    ),
    _Phase.home => _following(
      AdultHomeRoute(
        createBloc: widget.createHomeBloc,
        adultName: _name,
        sync: widget.intakeSync,
        onOpenMore: () => _openMore(context),
        onOpenAgenda: () => _openAgenda(context),
        onOpenMedications: widget.treatments == null
            ? null
            : () => _openMedications(context),
        onOpenDose: (intakeId) => _openDose(context, intakeId),
        onSessionInvalidated: widget.onSessionChanged,
      ),
    ),
  };
}
