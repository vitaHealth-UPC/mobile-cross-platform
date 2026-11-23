import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/ports/intake_sync.dart';
import '../../application/readmodels/intake_sync_status.dart';
import '../bloc/home/home_bloc.dart';
import '../bloc/home/home_event.dart';
import '../bloc/home/home_state.dart';
import '../screens/adult_home_screen.dart';

/// Owns the [HomeBloc], reloads when the app returns to the foreground and
/// reports lost access so Identity can revalidate the session.
class AdultHomeRoute extends StatefulWidget {
  const AdultHomeRoute({
    super.key,
    required this.createBloc,
    required this.adultName,
    required this.onOpenMore,
    required this.onSessionInvalidated,
    this.clock = DateTime.now,
    this.onOpenVoice,
    this.onOpenAgenda,
    this.onOpenMedications,
    this.onOpenDose,
    this.sync,
  });

  final HomeBloc Function() createBloc;
  final String? adultName;
  final VoidCallback onOpenMore;
  final VoidCallback onSessionInvalidated;

  /// Local wall-clock time used for the date header and time remaining.
  final DateTime Function() clock;
  final ValueChanged<String>? onOpenVoice;

  /// Open the agenda or one dose; both complete when the user returns, and
  /// the home reloads because a confirmation may have changed it.
  final Future<void> Function()? onOpenAgenda;
  final Future<void> Function()? onOpenMedications;
  final Future<void> Function(String intakeId)? onOpenDose;

  /// Sends confirmations saved offline while this screen is open.
  final IntakeSync? sync;

  @override
  State<AdultHomeRoute> createState() => _AdultHomeRouteState();
}

class _AdultHomeRouteState extends State<AdultHomeRoute> {
  late final HomeBloc _bloc;
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<IntakeSyncStatus>? _syncChanges;
  IntakeSyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const HomeRequested());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _bloc.add(const HomeRequested());
        unawaited(widget.sync?.request());
      },
      onPause: () => widget.sync?.suspend(),
    );
    if (widget.sync case final sync?) {
      _syncStatus = sync.status;
      _syncChanges = sync.changes.listen(_syncChanged);
      unawaited(sync.request());
    }
  }

  /// A server answer to a queued confirmation changes what the home shows.
  void _syncChanged(IntakeSyncStatus status) {
    final answered = status.resolved > (_syncStatus?.resolved ?? 0);
    setState(() => _syncStatus = status);
    if (answered) _bloc.add(const HomeRequested());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _syncChanges?.cancel();
    _bloc.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    _bloc.add(const HomeRequested());
    await _bloc.stream.firstWhere(
      (state) => state.status != HomeStatus.loading,
    );
  }

  Future<void> _returnFrom(Future<void> navigation) async {
    await navigation;
    if (mounted) _bloc.add(const HomeRequested());
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (const {
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
          'ACCESS_DENIED',
        }.contains(state.errorCode)) {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        return AdultHomeScreen(
          state: state,
          adultName: widget.adultName,
          syncStatus: _syncStatus,
          clock: widget.clock,
          errorText: switch (state.errorCode) {
            null => null,
            'NETWORK_UNAVAILABLE' => text.networkUnavailable,
            'RATE_LIMITED' => text.rateLimited,
            _ => text.homeErrorBody,
          },
          onRefresh: _refresh,
          onOpenMore: widget.onOpenMore,
          onOpenVoice: widget.onOpenVoice,
          onOpenMedications: switch (widget.onOpenMedications) {
            final open? => () => _returnFrom(open()),
            null => null,
          },
          onOpenAgenda: switch (widget.onOpenAgenda) {
            final open? => () => _returnFrom(open()),
            null => null,
          },
          onOpenDose: switch (widget.onOpenDose) {
            final open? => (id) => _returnFrom(open(id)),
            null => null,
          },
        );
      },
    ),
  );
}
