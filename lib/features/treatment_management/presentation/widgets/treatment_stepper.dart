import 'package:flutter/material.dart';

import '../../../../shared/presentation/theme/tata_colors.dart';

/// Four treatment groups; enlarged text uses two columns to preserve whole labels.
/// Dose/frequency and administration times share the regimen group.
class TreatmentStepper extends StatelessWidget {
  const TreatmentStepper({
    super.key,
    required this.labels,
    required this.selected,
  });
  final List<String> labels;
  final int selected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Color(0xFFF1ECFF), Color(0xFFF7EFFF)],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 18;
        if (large) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < labels.length; index++)
                SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: _Step(
                    label: labels[index],
                    index: index,
                    selected: selected,
                    large: true,
                  ),
                ),
            ],
          );
        }
        return Stack(
          children: [
            const Positioned(
              top: 9,
              left: 30,
              right: 30,
              child: SizedBox(
                height: 2,
                child: ColoredBox(color: Color(0xFFDBE0ED)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: _Step(
                      label: labels[index],
                      index: index,
                      selected: selected,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.selected,
    this.large = false,
  });
  final String label;
  final int index;
  final int selected;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: large ? 24 : 18,
      height: large ? 24 : 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index <= selected ? TataColors.primary : const Color(0xFFE5DEFB),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w700,
          color: index <= selected ? Colors.white : TataColors.primary,
        ),
      ),
    );
    final caption = Text(
      label,
      textAlign: large ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: large ? 10 : 8,
        fontWeight: index == selected ? FontWeight.w600 : FontWeight.w400,
        color: index == selected ? TataColors.ink : TataColors.muted,
      ),
    );
    return Semantics(
      selected: index == selected,
      label: '${index + 1}. $label',
      child: ExcludeSemantics(
        child: large
            ? Row(
                children: [
                  dot,
                  const SizedBox(width: 8),
                  Expanded(child: caption),
                ],
              )
            : Column(children: [dot, const SizedBox(height: 4), caption]),
      ),
    );
  }
}
