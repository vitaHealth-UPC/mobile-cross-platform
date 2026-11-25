import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/motion_aware_routes.dart';
import '../../application/readmodels/medication_registration_result.dart';
import '../../domain/entities/medication.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_management/medication_management_state.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/my_medications/my_medications_bloc.dart';
import '../bloc/treatment_list/treatment_list_bloc.dart';
import '../bloc/treatment_list/treatment_list_event.dart';
import '../bloc/treatment_management/treatment_management_bloc.dart';
import '../bloc/treatment_management/treatment_management_event.dart';
import '../bloc/treatment_setup/treatment_setup_bloc.dart';
import '../bloc/treatment_setup/treatment_setup_state.dart';
import '../screens/medication_management_screen.dart';
import '../screens/medication_registration_screen.dart';
import '../screens/my_medications_screen.dart';
import '../screens/treatment_detail_screen.dart';
import '../screens/treatment_list_screen.dart';
import '../screens/treatment_setup_screen.dart';
import '../widgets/active_medications_card.dart';
import 'medication_stock_hooks.dart';

/// Builders for the blocs of the Treatment Management flows; each route owns and closes
/// the bloc it creates.
final class TreatmentFactories {
  const TreatmentFactories({
    required this.createListBloc,
    required this.createRegistrationBloc,
    required this.createMedicationsBloc,
    required this.createSetupBloc,
    required this.createManagementBloc,
    required this.createMyMedicationsBloc,
  });

  final TreatmentListBloc Function(String olderAdultId) createListBloc;
  final MedicationRegistrationBloc Function(String olderAdultId)
  createRegistrationBloc;
  final MedicationManagementBloc Function(String olderAdultId)
  createMedicationsBloc;
  final TreatmentSetupBloc Function(
    String olderAdultId,
    List<SetupMedication> medications,
  )
  createSetupBloc;
  final TreatmentManagementBloc Function(
    String treatmentId,
    String olderAdultId,
  )
  createManagementBloc;
  final MyMedicationsBloc Function() createMyMedicationsBloc;
}

/// Navigates between the Treatment Management screens. A failure that invalidates the
/// session returns to the root and lets the host decide what to do.
final class TreatmentNavigation {
  const TreatmentNavigation(this._factories);
  final TreatmentFactories _factories;

  VoidCallback _invalidate(BuildContext context, VoidCallback host) => () {
    Navigator.of(context).popUntil((route) => route.isFirst);
    host();
  };

  /// Treatments of [olderAdultId], with detail, creation and medication management.
  Future<void> openTreatments(
    BuildContext context,
    String olderAdultId,
    VoidCallback onSessionInvalidated, {
    String? personName,
    Widget Function(VoidCallback onInvalidated)? personBadgeBuilder,
    Widget Function(String treatmentId, VoidCallback onInvalidated)?
    adherenceBuilder,
    Widget Function(BuildContext context)? navigationBuilder,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _factories.createListBloc(olderAdultId)
              ..add(const TreatmentListRequested()),
        child: Builder(
          builder: (listContext) => TreatmentListScreen(
            onSessionInvalidated: _invalidate(
              listContext,
              onSessionInvalidated,
            ),
            onOpen: (treatment) async {
              final list = listContext.read<TreatmentListBloc>();
              await Navigator.of(listContext).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => _factories.createManagementBloc(
                      treatment.id,
                      olderAdultId,
                    )..add(const TreatmentManagementRequested()),
                    child: Builder(
                      builder: (detailContext) => TreatmentDetailScreen(
                        personName: personName,
                        onReturnToPerson: () {
                          final personRoute = ModalRoute.of(context);
                          Navigator.of(detailContext).popUntil(
                            (route) => route == personRoute || route.isFirst,
                          );
                        },
                        personAdherenceBadge: personBadgeBuilder?.call(
                          _invalidate(detailContext, onSessionInvalidated),
                        ),
                        adherence: adherenceBuilder?.call(
                          treatment.id,
                          _invalidate(detailContext, onSessionInvalidated),
                        ),
                        navigationBar: navigationBuilder?.call(detailContext),
                        onSessionInvalidated: _invalidate(
                          detailContext,
                          onSessionInvalidated,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              if (listContext.mounted) list.add(const TreatmentListRequested());
            },
            onNew: () async {
              final list = listContext.read<TreatmentListBloc>();
              final activated = await _openMedicationManagement(
                listContext,
                olderAdultId,
                onSessionInvalidated,
                picking: true,
                personName: personName,
              );
              if (listContext.mounted) {
                list.add(TreatmentListRequested(activated: activated == true));
              }
            },
          ),
        ),
      ),
    ),
  );

  /// Active medications of [olderAdultId] for a host screen (Figma 563:1121).
  Widget activeMedicationsCard(
    String olderAdultId,
    VoidCallback onSessionInvalidated,
  ) => ActiveMedicationsCard(
    createBloc: () => _factories.createMedicationsBloc(olderAdultId),
    onSessionInvalidated: onSessionInvalidated,
  );

  /// Medication catalog of [olderAdultId] with registration, editing and treatments.
  /// [onOpenInventory] lets the host open the stock of a medication.
  Future<void> openMedications(
    BuildContext context,
    String olderAdultId,
    VoidCallback onSessionInvalidated, {
    String? personName,
    void Function(BuildContext context, Medication medication)? onOpenInventory,
    MedicationStockHooks? stock,
  }) async {
    await _openMedicationManagement(
      context,
      olderAdultId,
      onSessionInvalidated,
      picking: false,
      onOpenInventory: onOpenInventory,
      personName: personName,
      stock: stock,
    );
  }

  Future<bool?> _openMedicationManagement(
    BuildContext context,
    String olderAdultId,
    VoidCallback onSessionInvalidated, {
    required bool picking,
    String? personName,
    void Function(BuildContext context, Medication medication)? onOpenInventory,
    MedicationStockHooks? stock,
  }) => Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _factories.createMedicationsBloc(olderAdultId)
              ..add(const MedicationsRequested()),
        child: Builder(
          builder: (medicationsContext) => MedicationManagementScreen(
            pickingForTreatment: picking,
            loadStock: stock?.remaining,
            onOpenInventory: onOpenInventory == null
                ? null
                : (medication) =>
                      onOpenInventory(medicationsContext, medication),
            onSessionInvalidated: _invalidate(
              medicationsContext,
              onSessionInvalidated,
            ),
            onRegister: () async {
              final medications = medicationsContext
                  .read<MedicationManagementBloc>();
              final result = await Navigator.of(medicationsContext)
                  .push<MedicationRegistrationResult>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            _factories.createRegistrationBloc(olderAdultId),
                        child: Builder(
                          builder: (registrationContext) =>
                              MedicationRegistrationScreen(
                                personName: personName,
                                registerInitialStock: stock?.registerInitial,
                                onRegistered: (result) =>
                                    Navigator.of(registrationContext)
                                        .pop(result),
                                onSessionInvalidated: _invalidate(
                                  registrationContext,
                                  onSessionInvalidated,
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
              if (!medicationsContext.mounted) return;
              medications.add(
                MedicationsRequested(
                  notice: switch (result) {
                    null => null,
                    MedicationRegistrationResult(initialStockSaved: false) =>
                      MedicationNotice.registeredWithoutStock,
                    _ => MedicationNotice.registered,
                  },
                ),
              );
              if (result != null && picking) {
                await _createTreatment(
                  medicationsContext,
                  olderAdultId,
                  [result.medication],
                  onSessionInvalidated,
                  picking: picking,
                  initial: result,
                );
              }
            },
            onCreateTreatment: (preselected) => _createTreatment(
              medicationsContext,
              olderAdultId,
              preselected,
              onSessionInvalidated,
              picking: picking,
            ),
          ),
        ),
      ),
    ),
  );

  /// Opens the treatment wizard with [preselected] medications; the caregiver
  /// can add any other active medication of the catalog in its first step.
  Future<void> _createTreatment(
    BuildContext context,
    String olderAdultId,
    List<Medication> preselected,
    VoidCallback onSessionInvalidated, {
    required bool picking,
    MedicationRegistrationResult? initial,
  }) async {
    SetupMedication setup(Medication medication) =>
        SetupMedication(medication.id, medication.label);
    final available = [
      for (final medication
          in context.read<MedicationManagementBloc>().state.medications)
        if (medication.active) setup(medication),
    ];
    final activated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => _factories.createSetupBloc(olderAdultId, [
            for (final medication in preselected) setup(medication),
          ]),
          child: Builder(
            builder: (setupContext) => TreatmentSetupScreen(
              availableMedications: available,
              initialFrequency: initial?.frequency ?? '',
              initialInstructions: initial?.instructions ?? '',
              onFinished: () => Navigator.of(setupContext).pop(true),
              onSessionInvalidated: _invalidate(
                setupContext,
                onSessionInvalidated,
              ),
            ),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (picking && activated == true) {
      Navigator.of(context).pop(true);
    } else {
      context.read<MedicationManagementBloc>().add(
        MedicationsRequested(
          notice: activated == true
              ? MedicationNotice.treatmentActivated
              : null,
        ),
      );
    }
  }

  /// Read-only medication catalog for the signed-in older adult.
  Future<void> openMyMedications(
    BuildContext context,
    VoidCallback onSessionInvalidated, {
    VoidCallback? onHome,
    VoidCallback? onAgenda,
    VoidCallback? onMore,
    Future<void> Function(String)? onDose,
    bool asTab = false,
  }) {
    Widget page(BuildContext _) => BlocProvider(
      create: (_) =>
          _factories.createMyMedicationsBloc()
            ..add(const MyMedicationsRequested()),
      child: Builder(
        builder: (innerContext) => MyMedicationsScreen(
          onHome: onHome,
          onAgenda: onAgenda,
          onMore: onMore,
          onDose: onDose,
          onSessionInvalidated: _invalidate(innerContext, onSessionInvalidated),
        ),
      ),
    );
    // From a bottom-bar destination it replaces the previous tab.
    return asTab
        ? TabPageRoute.replaceTab<void>(context, page)
        : Navigator.of(context).push<void>(MaterialPageRoute(builder: page));
  }
}
