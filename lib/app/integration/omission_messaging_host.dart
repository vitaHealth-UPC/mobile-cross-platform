import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/access/access_state.dart';
import '../../features/omission_escalation/application/ports/omission_delivery.dart';
import '../../features/omission_escalation/application/readmodels/push_destination.dart';

/// Observes access and app lifecycle without moving messaging or routing rules into screens.
/// Must be mounted below the app's AccessBloc provider.
class OmissionMessagingHost extends StatefulWidget {
  const OmissionMessagingHost({
    super.key,
    required this.delivery,
    required this.onOpen,
    required this.child,
  });

  final OmissionDelivery delivery;
  final Future<void> Function(PushDestination) onOpen;
  final Widget child;

  @override
  State<OmissionMessagingHost> createState() => _OmissionMessagingHostState();
}

class _OmissionMessagingHostState extends State<OmissionMessagingHost>
    with WidgetsBindingObserver {
  AccessBloc? _access;
  StreamSubscription<AccessState>? _sessions;
  StreamSubscription<PushDestination>? _destinations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_access != null) return;
    final access = context.read<AccessBloc>();
    _access = access;
    _sessions = access.stream.listen((state) => unawaited(_observe(state)));
    _destinations = widget.delivery.destinations.listen(
      (destination) => unawaited(_open(destination)),
    );
    unawaited(_start(access));
  }

  Future<void> _start(AccessBloc access) async {
    try {
      await widget.delivery.start();
      if (mounted) await _observe(access.state);
    } on Exception {
      // The ordinary authenticated flows remain available without an SDK provider.
    }
  }

  Future<void> _observe(AccessState state) async {
    if (!mounted) return;
    try {
      await widget.delivery.sessionChanged(
        authenticated: state.status == AccessStatus.authenticated,
      );
    } on Exception {
      // Secure-storage or SDK failures never replace the access authority.
    }
  }

  Future<void> _open(PushDestination destination) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      await widget.onOpen(destination);
    } on Exception {
      // The next normal navigation attempt still uses current server authorization.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final access = _access;
    if (state == AppLifecycleState.resumed && access != null) {
      unawaited(_observe(access.state));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sessions?.cancel());
    unawaited(_destinations?.cancel());
    unawaited(widget.delivery.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
