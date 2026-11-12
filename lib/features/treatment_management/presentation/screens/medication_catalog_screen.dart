import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../bloc/my_medications/my_medications_bloc.dart';

/// Figma 563:361: real active/history counts, featured medication and adaptive native cards.
class MedicationCatalogScreen extends StatelessWidget {
  const MedicationCatalogScreen({
    super.key,
    required this.state,
    required this.navigationBar,
    required this.onRefresh,
    required this.onHistory,
    required this.onMedication,
    required this.onDose,
  });
  final MyMedicationsState state;
  final Widget navigationBar;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onHistory;
  final ValueChanged<String> onMedication;
  final ValueChanged<String> onDose;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final items = (state.history ? state.inactive : state.active);
    final featured = state.history
        ? null
        : items
                  .where((item) => item.id == state.nextDose?.medicationId)
                  .firstOrNull ??
              items.firstOrNull;
    final rest = items.where((item) => item != featured).toList();
    final active = state.medications.where((item) => item.active).length;
    return Scaffold(
      bottomNavigationBar: navigationBar,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -100,
              top: 40,
              child: ExcludeSemantics(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: SvgPicture.asset(
                    'assets/illustrations/catalog_glow.svg',
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                key: const PageStorageKey('medication-catalog'),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            text.catalogTitle,
                            style: TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize:
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      18
                                  ? 24
                                  : 29,
                              color: TataColors.ink,
                            ),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: text.catalogManagedByCaregiver,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(
                              side: BorderSide(color: Color(0xFFD4D9E6)),
                            ),
                          ),
                          onPressed: null,
                          icon: const Icon(Icons.add, color: TataColors.muted),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        text.catalogSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TataColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7887B2),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '$active',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (state.status == MyMedicationsStatus.loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: text.homeLoading,
                        ),
                      ),
                    )
                  else if (state.status == MyMedicationsStatus.failure)
                    _Message(
                      title: text.catalogError,
                      body: state.errorCode == 'NETWORK_UNAVAILABLE'
                          ? text.networkUnavailable
                          : text.homeErrorBody,
                      action: text.homeRetry,
                      onAction: onRefresh,
                    )
                  else ...[
                    if (featured != null) ...[
                      _Featured(
                        item: featured,
                        next: state.nextDose?.medicationId == featured.id
                            ? state.nextDose
                            : null,
                        scheduleUnknown:
                            state.scheduleError != null ||
                            (state.nextDose != null &&
                                state.nextDose!.medicationId != featured.id),
                        onTap: () => onMedication(featured.id),
                        onDose: onDose,
                      ),
                      const SizedBox(height: 20),
                    ],
                    Wrap(
                      spacing: 9,
                      children: [
                        ChoiceChip(
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFE8EBF0),
                          label: Text(text.catalogActiveCount(active)),
                          selected: !state.history,
                          onSelected: (_) => onHistory(false),
                          selectedColor: TataColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: state.history
                                ? TataColors.muted
                                : Colors.white,
                          ),
                          showCheckmark: false,
                        ),
                        ChoiceChip(
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFE8EBF0),
                          label: Text(text.catalogHistory),
                          selected: state.history,
                          onSelected: (_) => onHistory(true),
                          selectedColor: TataColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: state.history
                                ? Colors.white
                                : TataColors.muted,
                          ),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      _Message(
                        title: text.catalogEmptyTitle,
                        body: state.history
                            ? text.catalogHistoryEmpty
                            : text.catalogActiveEmpty,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              constraints.maxWidth >= 320 &&
                                  MediaQuery.textScalerOf(context).scale(14) <
                                      18
                              ? 2
                              : 1;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 16,
                            children: [
                              for (final (index, item) in rest.indexed)
                                SizedBox(
                                  width: width,
                                  child: _MedicationCard(
                                    item: item,
                                    index: index,
                                    onTap: () => onMedication(item.id),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({
    required this.item,
    required this.next,
    required this.scheduleUnknown,
    required this.onTap,
    required this.onDose,
  });
  final MyMedication item;
  final MedicationNextDose? next;
  final bool scheduleUnknown;
  final VoidCallback onTap;
  final ValueChanged<String> onDose;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final treatment = item.treatments
        .where((treatment) => treatment.status == TreatmentStatus.active)
        .firstOrNull;
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.catalogFeatured,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5C579E)),
        ),
        const SizedBox(height: 12),
        Text(
          item.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: TataColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          treatment?.dose ?? item.presentation,
          style: const TextStyle(fontSize: 13, color: TataColors.ink),
        ),
        const SizedBox(height: 10),
        Text(
          treatment?.instructions.trim().isNotEmpty == true
              ? treatment!.instructions
              : item.presentation,
          style: const TextStyle(fontSize: 13, color: Color(0xFF5C63B2)),
        ),
      ],
    );
    return _Surface(
      colors: const [Color(0xFFF0EAFF), Color(0xFFE5DCF9)],
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: large
                  ? details
                  : Row(
                      children: [
                        Expanded(child: details),
                        ExcludeSemantics(
                          child: SizedBox.square(
                            dimension: 104,
                            child: OverflowBox(
                              maxHeight: 142,
                              maxWidth: 142,
                              child: Image.asset(
                                'assets/illustrations/home_tablet.png',
                                width: 142,
                                height: 142,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (large)
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/illustrations/home_tablet.png',
                width: 104,
                height: 104,
              ),
            ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: next == null ? null : () => onDose(next!.intakeId),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.homeNextDose,
                            style: const TextStyle(
                              fontSize: 11,
                              color: TataColors.muted,
                            ),
                          ),
                          Text(
                            next == null
                                ? (scheduleUnknown
                                      ? text.catalogScheduleUnavailable
                                      : text.catalogNoNext)
                                : DateFormat(
                                    'h:mm a',
                                    Localizations.localeOf(context)
                                        .toLanguageTag(),
                                  ).format(next!.scheduledAt.toLocal()),
                            style: TextStyle(
                              fontSize: next == null ? 13 : 19,
                              fontWeight: FontWeight.w700,
                              color: TataColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (next != null)
                      const Icon(
                        Icons.chevron_right,
                        color: TataColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.item,
    required this.index,
    required this.onTap,
  });
  final MyMedication item;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final treatment =
        (item.active
                ? item.treatments.where(
                    (treatment) => treatment.status == TreatmentStatus.active,
                  )
                : item.treatments)
            .firstOrNull;
    final hours =
        treatment?.scheduledTimes
            .map((time) => int.parse(time.substring(0, 2)))
            .toList() ??
        [];
    final night =
        hours.isNotEmpty && hours.every((hour) => hour >= 18 || hour < 5);
    const palettes = [
      [Color(0xFFFFF4E2), Color(0xFFFBE7C9)],
      [Color(0xFFF1ECFF), Color(0xFFE7DFF9)],
      [Color(0xFFECF7EF), Color(0xFFE1F0E5)],
      [Color(0xFFECF5FB), Color(0xFFDFECF6)],
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _Surface(
          colors: palettes[index % palettes.length],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                treatment?.dose ?? item.presentation,
                style: const TextStyle(fontSize: 12, color: TataColors.ink),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icons/catalog_${night ? "night" : "morning"}.svg',
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      treatment?.instructions.trim().isNotEmpty == true
                          ? treatment!.instructions
                          : item.presentation,
                      style: TextStyle(
                        fontSize: 12,
                        color: night
                            ? const Color(0xFF5963AD)
                            : const Color(0xFFC48C29),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.colors, required this.child, this.radius = 16});
  final List<Color> colors;
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(colors: colors),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final String title;
  final String body;
  final String? action;
  final Future<void> Function()? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(body),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}
