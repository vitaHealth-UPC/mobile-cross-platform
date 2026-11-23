import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_management/medication_management_state.dart';
import '../texts/treatment_texts.dart';

/// "Tratamiento actual" of Figma 563:1121: the active medications of one
/// adult, read for a host screen to place. Owns and closes its bloc.
class ActiveMedicationsCard extends StatefulWidget {
  const ActiveMedicationsCard({
    super.key,
    required this.createBloc,
    required this.onSessionInvalidated,
  });

  final MedicationManagementBloc Function() createBloc;
  final VoidCallback onSessionInvalidated;

  @override
  State<ActiveMedicationsCard> createState() => _ActiveMedicationsCardState();
}

class _ActiveMedicationsCardState extends State<ActiveMedicationsCard> {
  late final MedicationManagementBloc _bloc = widget.createBloc()
    ..add(const MedicationsRequested());

  /// Dot colors of the Figma list, repeated for longer lists.
  static const _dots = [
    Color(0xFFD25C4F),
    Color(0xFF7B6AD8),
    Color(0xFF3F8F5F),
  ];

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MedicationManagementBloc, MedicationManagementState>(
        bloc: _bloc,
        listenWhen: (a, b) => a.errorCode != b.errorCode,
        listener: (_, state) {
          if (isSessionFailure(state.errorCode)) widget.onSessionInvalidated();
        },
        builder: (context, state) {
          final text = AppLocalizations.of(context);
          final active = [
            for (final medication in state.medications)
              if (medication.active) medication,
          ];
          final subtitle = switch (state.status) {
            MedicationManagementStatus.loading => text.lpMedicationsLoading,
            MedicationManagementStatus.failure => text.lpMedicationsError,
            MedicationManagementStatus.ready =>
              active.isEmpty
                  ? text.lpMedicationsNone
                  : text.lpMedicationsActive(active.length),
          };
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14173B70),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    text.lpTreatmentTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TataColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5B6475),
                  ),
                ),
                if (active.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      runSpacing: 10,
                      children: [
                        for (final (index, medication) in active.indexed)
                          SizedBox(
                            width: constraints.maxWidth >= 300
                                ? constraints.maxWidth / 2
                                : constraints.maxWidth,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _dots[index % _dots.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _label(
                                      medication.name,
                                      medication.presentation,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: TataColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );

  /// Name and strength, as Figma lists them ("Losartán 50 mg"); the form
  /// after the comma ("tableta") is left out.
  static String _label(String name, String presentation) {
    final strength = presentation.split(',').first.trim();
    return strength.isEmpty ? name : '$name $strength';
  }
}
