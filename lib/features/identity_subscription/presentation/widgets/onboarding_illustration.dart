import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';

/// Decorative sample reminders from Figma 563:5, not a patient's live treatment.
/// Only this illustration uses a scaled canvas; screen controls remain responsive.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return MediaQuery.withNoTextScaling(
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: 337 / 250,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 337,
              height: 250,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 10,
                    top: 26,
                    child: Transform.rotate(
                      angle: 8 * math.pi / 180,
                      child: _ReminderCard(
                        time: text.sampleMorning,
                        medicine: 'Losartán 50 mg',
                        dose: text.sampleTablet,
                        colors: const [Color(0xFFFFF4E3), Color(0xFFFFEACF)],
                        sun: true,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 27,
                    child: Transform.rotate(
                      angle: -7 * math.pi / 180,
                      child: _ReminderCard(
                        time: text.sampleEvening,
                        medicine: 'Metformina 850 mg',
                        dose: text.sampleTablet,
                        colors: const [Color(0xFFF0EBFF), Color(0xFFE7DDFE)],
                        completed: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 92,
                    top: 134,
                    child: Transform.rotate(
                      angle: -4 * math.pi / 180,
                      child: _ReminderCard(
                        time: text.sampleNight,
                        medicine: text.sampleVitamin,
                        dose: text.sampleCapsule,
                        colors: const [Colors.white, Color(0xFFF6F6FC)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 26,
                    top: 24,
                    child: Image.asset(
                      'assets/illustrations/onboarding_heart.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  Positioned(
                    right: 28,
                    bottom: 0,
                    child: Image.asset(
                      'assets/illustrations/onboarding_botanical.png',
                      width: 66,
                      height: 78,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flutter text and layout preserve the editable implementation of decorative cards.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.time,
    required this.medicine,
    required this.dose,
    required this.colors,
    this.sun = false,
    this.completed = false,
  });
  final String time;
  final String medicine;
  final String dose;
  final List<Color> colors;
  final bool sun;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      width: 146,
      height: sun || completed ? 108 : 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: colors),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2138),
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  height: 1.1,
                  fontSize: 11,
                  color: Color(0xFF637087),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                medicine,
                maxLines: 1,
                style: TextStyle(
                  height: 1.1,
                  fontSize: completed ? 11 : 14,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dose,
                style: const TextStyle(
                  height: 1.1,
                  fontSize: 12,
                  color: Color(0xFF637087),
                ),
              ),
              if (sun)
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/onboarding_circle.svg',
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      text.sampleToday,
                      style: const TextStyle(
                        height: 1.1,
                        fontSize: 10,
                        color: Color(0xFF637087),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (sun)
            Positioned(
              right: 0,
              bottom: -1,
              child: Image.asset(
                'assets/illustrations/onboarding_sun.png',
                width: 34,
                height: 34,
              ),
            ),
          if (completed)
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.check, size: 17, color: Color(0xFF4F8C66)),
            ),
        ],
      ),
    );
  }
}
