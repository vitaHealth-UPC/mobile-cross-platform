import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/adult_navigation_bar.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../bloc/my_medications/my_medications_bloc.dart';
import '../texts/treatment_texts.dart';
import 'medication_catalog_screen.dart';
import 'medication_details_screen.dart';

/// Adult catalog host: owns detail selection and foreground refresh, while the route owns its bloc.
class MyMedicationsScreen extends StatefulWidget {
  const MyMedicationsScreen({
    super.key,
    required this.onSessionInvalidated,
    this.onHome,
    this.onAgenda,
    this.onMore,
    this.onDose,
  });
  final VoidCallback onSessionInvalidated;
  final VoidCallback? onHome;
  final VoidCallback? onAgenda;
  final VoidCallback? onMore;
  final Future<void> Function(String)? onDose;
  @override
  State<MyMedicationsScreen> createState() => _MyMedicationsScreenState();
}

class _MyMedicationsScreenState extends State<MyMedicationsScreen> {
  String? _selectedId;
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          context.read<MyMedicationsBloc>().add(const MyMedicationsRequested()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<MyMedicationsBloc>();
    final ready = bloc.stream.firstWhere(
      (s) => s.status != MyMedicationsStatus.loading,
    );
    bloc.add(const MyMedicationsRequested());
    await ready;
  }

  Future<void> _dose(String id) async {
    final open = widget.onDose;
    if (open == null) return;
    await open(id);
    if (mounted) {
      context.read<MyMedicationsBloc>().add(const MyMedicationsRequested());
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MyMedicationsBloc, MyMedicationsState>(
        listenWhen: (_, state) =>
            isSessionFailure(state.errorCode) ||
            state.errorCode == 'ACCESS_DENIED',
        listener: (_, _) => widget.onSessionInvalidated(),
        builder: (context, state) {
          final selected = state.status == MyMedicationsStatus.ready
              ? state.medications
                    .where((item) => item.id == _selectedId)
                    .firstOrNull
              : null;
          final bar = AdultNavigationBar(
            selected: AdultDestination.medications,
            onHome: widget.onHome ?? () => Navigator.of(context).pop(),
            onAgenda: widget.onAgenda,
            onMore: widget.onMore,
          );
          MedicationNextDose? nextFor(MyMedication item) =>
              state.nextDose?.medicationId == item.id ? state.nextDose : null;
          return PopScope(
            canPop: selected == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _selectedId = null);
            },
            child: selected == null
                ? MedicationCatalogScreen(
                    state: state,
                    navigationBar: bar,
                    onRefresh: _refresh,
                    onHistory: (history) => context
                        .read<MyMedicationsBloc>()
                        .add(MyMedicationsHistorySelected(history)),
                    onMedication: (id) => setState(() => _selectedId = id),
                    onDose: _dose,
                  )
                : MedicationDetailsScreen(
                    item: selected,
                    next: nextFor(selected),
                    scheduleUnknown:
                        state.scheduleError != null ||
                        (state.nextDose != null && nextFor(selected) == null),
                    navigationBar: bar,
                    onBack: () => setState(() => _selectedId = null),
                    onDose: widget.onDose == null ? null : _dose,
                  ),
          );
        },
      );
}
