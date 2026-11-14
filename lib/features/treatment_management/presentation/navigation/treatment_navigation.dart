import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/medication.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/my_medications/my_medications_bloc.dart';
import '../bloc/treatment_list/treatment_list_bloc.dart';
import '../bloc/treatment_list/treatment_list_event.dart';
import '../bloc/treatment_management/treatment_management_bloc.dart';
import '../bloc/treatment_management/treatment_management_event.dart';
import '../bloc/treatment_setup/treatment_setup_bloc.dart';
import '../screens/medication_management_screen.dart';
import '../screens/medication_registration_screen.dart';
import '../screens/my_medications_screen.dart';
import '../screens/treatment_detail_screen.dart';
import '../screens/treatment_list_screen.dart';
import '../screens/treatment_setup_screen.dart';

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
  final TreatmentSetupBloc Function(String olderAdultId, String medicationId)
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
              list.add(const TreatmentListRequested());
            },
            onNew: () async {
              final list = listContext.read<TreatmentListBloc>();
              await _openMedicationManagement(
                listContext,
                olderAdultId,
                onSessionInvalidated,
                picking: true,
              );
              list.add(const TreatmentListRequested());
            },
          ),
        ),
      ),
    ),
  );

  /// Medication catalog of [olderAdultId] with registration, edition and treatments.
  /// [onOpenInventory] lets the host open the stock of a medication.
  Future<void> openMedications(
    BuildContext context,
    String olderAdultId,
    VoidCallback onSessionInvalidated, {
    void Function(BuildContext context, Medication medication)? onOpenInventory,
  }) => _openMedicationManagement(
    context,
    olderAdultId,
    onSessionInvalidated,
    picking: false,
    onOpenInventory: onOpenInventory,
  );

  Future<void> _openMedicationManagement(
    BuildContext context,
    String olderAdultId,
    VoidCallback onSessionInvalidated, {
    required bool picking,
    void Function(BuildContext context, Medication medication)? onOpenInventory,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _factories.createMedicationsBloc(olderAdultId)
              ..add(const MedicationsRequested()),
        child: Builder(
          builder: (medicationsContext) => MedicationManagementScreen(
            pickingForTreatment: picking,
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
              await Navigator.of(medicationsContext).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        _factories.createRegistrationBloc(olderAdultId),
                    child: Builder(
                      builder: (registrationContext) =>
                          MedicationRegistrationScreen(
                            onRegistered: () =>
                                Navigator.of(registrationContext).pop(),
                            onSessionInvalidated: _invalidate(
                              registrationContext,
                              onSessionInvalidated,
                            ),
                          ),
                    ),
                  ),
                ),
              );
              medications.add(const MedicationsRequested());
            },
            onCreateTreatment: (medication) async {
              final medications = medicationsContext
                  .read<MedicationManagementBloc>();
              await Navigator.of(medicationsContext).push<void>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        _factories.createSetupBloc(olderAdultId, medication.id),
                    child: Builder(
                      builder: (setupContext) => TreatmentSetupScreen(
                        medicationLabel: medication.label,
                        onFinished: () => Navigator.of(setupContext).pop(),
                        onSessionInvalidated: _invalidate(
                          setupContext,
                          onSessionInvalidated,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              medications.add(const MedicationsRequested());
              // A treatment created from the picker returns to the list that opened it.
              if (picking && medicationsContext.mounted) {
                Navigator.of(medicationsContext).pop();
              }
            },
          ),
        ),
      ),
    ),
  );

  /// Read-only medication catalog for the signed-in older adult.
  Future<void> openMyMedications(
    BuildContext context,
    VoidCallback onSessionInvalidated, {
    VoidCallback? onHome,
    VoidCallback? onAgenda,
    VoidCallback? onMore,
    Future<void> Function(String)? onDose,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _factories.createMyMedicationsBloc()
              ..add(const MyMedicationsRequested()),
        child: Builder(
          builder: (innerContext) => MyMedicationsScreen(
            onHome: onHome,
            onAgenda: onAgenda,
            onMore: onMore,
            onDose: onDose,
            onSessionInvalidated: _invalidate(
              innerContext,
              onSessionInvalidated,
            ),
          ),
        ),
      ),
    ),
  );
}
