import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/entities/medication.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_management/medication_management_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/medication_registration_art.dart';
import '../widgets/treatment_visuals.dart';

/// Orders offered for the catalog. "Recent" follows the order the server
/// registered the medications; stock orders need the host's stock reader.
enum MedicationSort { nameAsc, nameDesc, newest, oldest, stockLow, stockHigh }

/// Medications of one adult: search, sorting, stock at a glance and the
/// edit, retire/reactivate, delete and inventory actions. A single
/// "Crear tratamiento" action opens the treatment wizard, where one or more
/// medications are chosen. Navigation is delegated to the route.
class MedicationManagementScreen extends StatefulWidget {
  const MedicationManagementScreen({
    super.key,
    required this.onRegister,
    required this.onCreateTreatment,
    required this.onSessionInvalidated,
    this.pickingForTreatment = false,
    this.onOpenInventory,
    this.loadStock,
  });

  final VoidCallback onRegister;

  /// Opens the treatment wizard; [preselected] may be empty.
  final void Function(List<Medication> preselected) onCreateTreatment;
  final VoidCallback onSessionInvalidated;

  /// True when opened from the treatment list to start a new treatment.
  final bool pickingForTreatment;

  /// Opens the stock of a medication; owned by the host, absent when not wired.
  final void Function(Medication medication)? onOpenInventory;

  /// Reads remaining units for the stock line and the stock orders.
  final Future<int?> Function(String medicationId)? loadStock;

  @override
  State<MedicationManagementScreen> createState() =>
      _MedicationManagementScreenState();
}

class _MedicationManagementScreenState
    extends State<MedicationManagementScreen> {
  final _search = TextEditingController();
  MedicationSort _sort = MedicationSort.nameAsc;

  /// Remaining units by medication id; null while unknown or without stock.
  final _stock = <String, int?>{};
  final _requested = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _loadStock(List<Medication> medications, {bool refresh = false}) {
    final load = widget.loadStock;
    if (load == null) return;
    for (final medication in medications) {
      if (!refresh && !_requested.add(medication.id)) continue;
      _requested.add(medication.id);
      load(medication.id).then((units) {
        if (mounted) setState(() => _stock[medication.id] = units);
      });
    }
  }

  List<Medication> _visible(List<Medication> all) {
    final query = _search.text.trim().toLowerCase();
    final order = {for (final (i, m) in all.indexed) m.id: i};
    final filtered = [
      for (final medication in all)
        if (query.isEmpty ||
            medication.name.toLowerCase().contains(query) ||
            medication.presentation.toLowerCase().contains(query))
          medication,
    ];
    int byName(Medication a, Medication b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    // Unknown stock goes last in both stock orders.
    int byStock(Medication a, Medication b, int sign) {
      final x = _stock[a.id];
      final y = _stock[b.id];
      if (x == null && y == null) return byName(a, b);
      if (x == null) return 1;
      if (y == null) return -1;
      return sign * x.compareTo(y);
    }

    return filtered..sort(
      (a, b) => switch (_sort) {
        MedicationSort.nameAsc => byName(a, b),
        MedicationSort.nameDesc => byName(b, a),
        MedicationSort.newest => order[b.id]!.compareTo(order[a.id]!),
        MedicationSort.oldest => order[a.id]!.compareTo(order[b.id]!),
        MedicationSort.stockLow => byStock(a, b, 1),
        MedicationSort.stockHigh => byStock(a, b, -1),
      },
    );
  }

  String _sortLabel(AppLocalizations text, MedicationSort sort) =>
      switch (sort) {
        MedicationSort.nameAsc => text.tmSortNameAsc,
        MedicationSort.nameDesc => text.tmSortNameDesc,
        MedicationSort.newest => text.tmSortNewest,
        MedicationSort.oldest => text.tmSortOldest,
        MedicationSort.stockLow => text.tmSortStockLow,
        MedicationSort.stockHigh => text.tmSortStockHigh,
      };

  Future<void> _edit(Medication medication) async {
    final bloc = context.read<MedicationManagementBloc>();
    // The dialog owns its controllers so they outlive the closing animation;
    // disposing them here while the route is still fading out triggered the
    // `_dependents.isEmpty` assertion reported on iOS after "Cancelar".
    final edited = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => Theme(
        data: treatmentDialogTheme(dialogContext),
        child: _MedicationEditDialog(medication: medication),
      ),
    );
    if (edited case (final name, final presentation)) {
      bloc.add(MedicationEdited(medication.id, name, presentation));
    }
  }

  Future<void> _deactivate(Medication medication) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<MedicationManagementBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: treatmentDialogTheme(dialogContext),
        child: AlertDialog(
          title: Text(text.tmRemoveMedicationTitle),
          content: Text(text.tmRemoveMedicationBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(text.tmCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(text.tmRemoveMedication),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) bloc.add(MedicationDeactivated(medication.id));
  }

  Future<void> _delete(Medication medication) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<MedicationManagementBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: treatmentDialogTheme(dialogContext),
        child: AlertDialog(
          title: Text(text.tmDeleteMedicationTitle),
          content: Text('${medication.name}\n\n${text.tmDeleteMedicationBody}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(text.tmCancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(text.tmDeleteMedication),
            ),
          ],
        ),
      ),
    );
    if (mounted && confirmed == true) {
      bloc.add(MedicationDeleted(medication.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<MedicationManagementBloc, MedicationManagementState>(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          widget.onSessionInvalidated();
          return;
        }
        // Stock may change after Inventory or a registration with stock.
        if (state.status == MedicationManagementStatus.ready) {
          _loadStock(state.medications, refresh: state.notice != null);
        }
      },
      builder: (context, state) {
        final bloc = context.read<MedicationManagementBloc>();
        final all = widget.pickingForTreatment
            ? state.medications.where((item) => item.active).toList()
            : state.medications;
        if (state.status == MedicationManagementStatus.ready) {
          _loadStock(all);
        }
        final visible = _visible(all);
        final active = visible.where((m) => m.active).toList();
        final retired = visible.where((m) => !m.active).toList();
        final sorts = [
          MedicationSort.nameAsc,
          MedicationSort.nameDesc,
          MedicationSort.newest,
          MedicationSort.oldest,
          if (widget.loadStock != null) ...[
            MedicationSort.stockLow,
            MedicationSort.stockHigh,
          ],
        ];
        return Scaffold(
          bottomNavigationBar: all.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (all.any((m) => m.active))
                          ElevatedButton.icon(
                            key: const Key('create-treatment'),
                            onPressed: state.busy
                                ? null
                                : () => widget.onCreateTreatment(const []),
                            icon: const Icon(Icons.playlist_add),
                            label: Text(text.tmCreateTreatment),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('register-medication'),
                          style: treatmentSecondaryStyle(context),
                          onPressed: state.busy ? null : widget.onRegister,
                          icon: const Icon(Icons.add),
                          label: Text(text.tmRegisterMedication),
                        ),
                      ],
                    ),
                  ),
                ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TreatmentHeader(
                    title: widget.pickingForTreatment
                        ? text.tmNewTreatment
                        : text.tmMedicationsTitle,
                    backLabel: text.back,
                    onBack: state.busy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: switch (state.status) {
                      MedicationManagementStatus.loading
                          when state.medications.isEmpty =>
                        const Center(child: CircularProgressIndicator()),
                      MedicationManagementStatus.failure
                          when state.medications.isEmpty =>
                        ErrorRetry(
                          message: treatmentErrorText(text, state.errorCode)!,
                          retryLabel: text.tmRetry,
                          onRetry: () => bloc.add(const MedicationsRequested()),
                        ),
                      _ => ListView(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                        children: [
                          if (state.notice case final notice?) ...[
                            TreatmentNotice(
                              key: const Key('medication-operation-receipt'),
                              message: switch (notice) {
                                MedicationNotice.registered ||
                                MedicationNotice.registeredWithoutStock =>
                                  text.tmMedicationRegistered,
                                MedicationNotice.updated =>
                                  text.tmMedicationUpdated,
                                MedicationNotice.deactivated =>
                                  text.tmMedicationDeactivated,
                                MedicationNotice.deleted =>
                                  text.tmMedicationDeleted,
                                MedicationNotice.reactivated =>
                                  text.tmMedicationReactivated,
                                MedicationNotice.treatmentActivated =>
                                  text.tmActivated,
                              },
                              warning:
                                  notice == MedicationNotice.deactivated ||
                                  notice == MedicationNotice.deleted ||
                                  notice ==
                                      MedicationNotice.registeredWithoutStock,
                              body: switch (notice) {
                                MedicationNotice.deactivated =>
                                  text.tmDeactivationReceipt,
                                MedicationNotice.reactivated =>
                                  text.tmReactivationReceipt,
                                MedicationNotice.registeredWithoutStock =>
                                  text.tmStockNotSaved,
                                _ => null,
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (widget.pickingForTreatment)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(text.tmChooseMedicationsHint),
                            ),
                          if (all.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  const MedicationRegistrationArt(),
                                  const SizedBox(height: 12),
                                  Text(
                                    text.tmEmptyMedicationTitle,
                                    textAlign: TextAlign.center,
                                    style: treatmentSectionStyle(context),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    text.tmEmptyMedicationBody,
                                    textAlign: TextAlign.center,
                                    style: treatmentSupportingStyle(context),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: state.busy
                                        ? null
                                        : widget.onRegister,
                                    icon: const Icon(Icons.add),
                                    label: Text(text.tmRegisterMedication),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            _Toolbar(
                              search: _search,
                              sortLabel: _sortLabel(text, _sort),
                              sorts: [
                                for (final sort in sorts)
                                  (sort, _sortLabel(text, sort)),
                              ],
                              selected: _sort,
                              onSearch: () => setState(() {}),
                              onSort: (sort) => setState(() => _sort = sort),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (all.isNotEmpty && visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                text.tmNoSearchResults,
                                textAlign: TextAlign.center,
                                style: treatmentSupportingStyle(context),
                              ),
                            ),
                          if (!widget.pickingForTreatment && active.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                text.tmActiveMedicationsSection,
                                style: treatmentSectionStyle(context),
                              ),
                            ),
                          for (final medication in active)
                            _card(context, text, state, medication),
                          if (retired.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                              child: Text(
                                text.tmArchivedMedications,
                                style: treatmentSectionStyle(context),
                              ),
                            ),
                          for (final medication in retired)
                            _card(context, text, state, medication),
                          if (state.errorCode != null &&
                              !isSessionFailure(state.errorCode))
                            InlineError(
                              treatmentErrorText(text, state.errorCode)!,
                            ),
                        ],
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    AppLocalizations text,
    MedicationManagementState state,
    Medication medication,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<MedicationManagementBloc>();
    final known = _stock.containsKey(medication.id);
    final units = _stock[medication.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TreatmentSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(
                      'assets/icons/treatment_medication.svg',
                      colorFilter: ColorFilter.mode(
                        scheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: treatmentSectionStyle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medication.presentation,
                        style: treatmentSupportingStyle(context),
                      ),
                      if (widget.loadStock != null &&
                          known &&
                          medication.active) ...[
                        const SizedBox(height: 6),
                        Text(
                          units == null
                              ? text.tmNoStock
                              : text.tmStockUnits(units),
                          key: Key('stock-${medication.id}'),
                          style: treatmentSupportingStyle(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: units == null
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                        ),
                      ],
                      if (!medication.active) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            text.tmInactive,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.pickingForTreatment)
                  Theme(
                    data: treatmentDialogTheme(context),
                    child: PopupMenuButton<String>(
                      key: Key('medication-actions-${medication.id}'),
                      tooltip: text.tmMoreActions,
                      enabled: !state.busy,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) => switch (action) {
                        'edit' => _edit(medication),
                        'retire' => _deactivate(medication),
                        'reactivate' => bloc.add(
                          MedicationReactivated(medication.id),
                        ),
                        _ => _delete(medication),
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(text.tmEdit)),
                        if (medication.active)
                          PopupMenuItem(
                            value: 'retire',
                            child: Text(text.tmRemoveMedication),
                          )
                        else
                          PopupMenuItem(
                            value: 'reactivate',
                            child: Text(text.tmReactivate),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            text.tmDeleteMedication,
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (medication.active &&
                (widget.pickingForTreatment ||
                    widget.onOpenInventory != null)) ...[
              const SizedBox(height: 14),
              if (widget.pickingForTreatment)
                OutlinedButton(
                  style: treatmentSecondaryStyle(context),
                  onPressed: state.busy
                      ? null
                      : () => widget.onCreateTreatment([medication]),
                  child: Text(text.tmCreateTreatment),
                )
              else
                OutlinedButton.icon(
                  key: Key('inventory-${medication.id}'),
                  style: treatmentSecondaryStyle(context),
                  onPressed: state.busy
                      ? null
                      : () => widget.onOpenInventory!(medication),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(text.invTitle),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search box and sort menu above the catalog.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.sortLabel,
    required this.sorts,
    required this.selected,
    required this.onSearch,
    required this.onSort,
  });

  final TextEditingController search;
  final String sortLabel;
  final List<(MedicationSort, String)> sorts;
  final MedicationSort selected;
  final VoidCallback onSearch;
  final ValueChanged<MedicationSort> onSort;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('medication-search'),
          controller: search,
          onChanged: (_) => onSearch(),
          style: treatmentFieldStyle(context),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: text.tmSearchMedications,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Theme(
            data: treatmentDialogTheme(context),
            child: PopupMenuButton<MedicationSort>(
              key: const Key('medication-sort'),
              tooltip: text.tmSortLabel,
              initialValue: selected,
              onSelected: onSort,
              itemBuilder: (_) => [
                for (final (sort, label) in sorts)
                  CheckedPopupMenuItem(
                    value: sort,
                    checked: sort == selected,
                    child: Text(label),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, size: 20),
                    const SizedBox(width: 6),
                    // Wraps at large text sizes instead of overflowing.
                    Flexible(
                      child: Text(
                        '${text.tmSortLabel}: $sortLabel',
                        style: treatmentSupportingStyle(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Edits name and presentation; pops `(name, presentation)` or null on cancel.
class _MedicationEditDialog extends StatefulWidget {
  const _MedicationEditDialog({required this.medication});

  final Medication medication;

  @override
  State<_MedicationEditDialog> createState() => _MedicationEditDialogState();
}

class _MedicationEditDialogState extends State<_MedicationEditDialog> {
  late final _name = TextEditingController(text: widget.medication.name);
  late final _presentation = TextEditingController(
    text: widget.medication.presentation,
  );
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _presentation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? text.tmRequiredField : null;
    return AlertDialog(
      title: Text(text.tmEdit),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('edit-medication-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: text.tmMedicationName),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('edit-medication-presentation'),
                controller: _presentation,
                decoration: InputDecoration(
                  labelText: text.tmMedicationPresentationShort,
                ),
                validator: required,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.tmCancel),
        ),
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_name.text, _presentation.text));
            }
          },
          child: Text(text.tmSave),
        ),
      ],
    );
  }
}
