import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';

/// Figma 563:1849: public product information before choosing a plan.
/// The illustrative preview is isolated from authenticated health information.
class LandingValueScreen extends StatelessWidget {
  const LandingValueScreen({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TataColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tata',
                        style: TextStyle(
                          fontFamily: 'DancingScript',
                          fontWeight: FontWeight.w700,
                          fontSize: 50,
                          height: 1.2,
                          color: Color(0xFF264087),
                        ),
                      ),
                      Transform.rotate(
                        angle: 20.1 * math.pi / 180,
                        child: ExcludeSemantics(
                          child: SvgPicture.asset(
                            'assets/icons/tata_butterfly.svg',
                            width: 21.915,
                            height: 21.917,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(text.landingTagline, style: _body(12)),
                  const SizedBox(height: 12),
                  _Hero(onStart: onStart),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      text.landingFeatures,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          MediaQuery.textScalerOf(context).scale(11) > 14;
                      final cards = [
                        _Feature(
                          title: text.landingReminders,
                          body: text.landingReminderBody,
                          color: const Color(0xFFE8F5EB),
                        ),
                        _Feature(
                          title: text.landingFamily,
                          body: text.landingFamilyBody,
                          color: const Color(0xFFFFF3E2),
                        ),
                        _Feature(
                          title: text.landingInsights,
                          body: text.landingInsightsBody,
                          color: const Color(0xFFF1ECFF),
                        ),
                      ];
                      if (stacked) {
                        return Column(
                          children: [
                            for (final card in cards)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 18),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text.landingAudience,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TataColors.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _panel(
                      const Color(0xFFFFF4E2),
                      end: const Color(0xFFFBE9CD),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/illustrations/landing_testimonial.png',
                                fit: BoxFit.cover,
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
                                text.landingQuote,
                                style: _body(12, color: TataColors.ink),
                              ),
                              const SizedBox(height: 12),
                              Text(text.landingQuoteAuthor, style: _body(10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _Fact(
                        title: text.landingSteps,
                        body: text.landingStepsBody,
                      ),
                      _Fact(
                        title: text.landingRoles,
                        body: text.landingRolesBody,
                      ),
                    ],
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

TextStyle _body(double size, {Color color = const Color(0xFF637087)}) =>
    TextStyle(fontSize: size, color: color, height: 1.25, letterSpacing: 0);

BoxDecoration _panel(Color color, {Color? end}) => BoxDecoration(
  color: end == null ? color : null,
  gradient: end == null ? null : LinearGradient(colors: [color, end]),
  borderRadius: BorderRadius.circular(18),
  boxShadow: const [
    BoxShadow(color: Color(0x141A2138), blurRadius: 18, offset: Offset(0, 6)),
  ],
);

class _Hero extends StatelessWidget {
  const _Hero({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.landingHeadline,
          style: const TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 21,
            height: 1.25,
            color: TataColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(text.landingDescription, style: _body(11)),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onStart,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text(text.getStarted),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panel(const Color(0xFFF1ECFF), end: const Color(0xFFECF4FB)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(11) > 14) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _ExamplePreview(),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              const _ExamplePreview(),
            ],
          );
        },
      ),
    );
  }
}

/// Marketing sample from Figma, never a repository-backed patient summary.
class _ExamplePreview extends StatelessWidget {
  const _ExamplePreview();
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Semantics(
      label: text.landingPreviewLabel,
      excludeSemantics: true,
      child: Container(
        width: 118,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: _panel(Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text.landingToday,
                  style: _body(11, color: TataColors.ink),
                ),
                Text('3 / 4', style: _body(13, color: TataColors.deepNavy)),
              ],
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              value: .75,
              minHeight: 5,
              color: Color(0xFF2E734D),
              backgroundColor: Color(0xFFE8EAF1),
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.landingMedication,
                    style: _body(10, color: TataColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(text.landingExampleTime, style: _body(9)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text.landingExampleAdherence,
                style: _body(9, color: TataColors.deepNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.title,
    required this.body,
    required this.color,
  });
  final String title;
  final String body;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 108),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    decoration: _panel(color),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        Text(body, style: _body(9.5)),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width.clamp(0, 440) - 64) / 2,
    constraints: const BoxConstraints(minHeight: 70),
    padding: const EdgeInsets.all(14),
    decoration: _panel(Colors.white),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TataColors.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(body, style: _body(10)),
      ],
    ),
  );
}
