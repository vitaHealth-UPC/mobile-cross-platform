import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../widgets/onboarding_illustration.dart';

/// Introduces Tata with responsive native text and actions from Figma 563:5.
/// The operating system supplies status/navigation bars rather than painted mocks.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.onStart,
    required this.onSignIn,
  });
  final VoidCallback onStart;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    TataColors.background,
                    Color(0xFFFCFBFF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 1,
            right: -51,
            child: ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 27, sigmaY: 27),
                child: SvgPicture.asset(
                  'assets/illustrations/onboarding_glow_blue.svg',
                  width: 432.247,
                  height: 439.951,
                ),
              ),
            ),
          ),
          Positioned(
            top: 242,
            left: -148,
            child: ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 29, sigmaY: 29),
                child: SvgPicture.asset(
                  'assets/illustrations/onboarding_glow_warm.svg',
                  width: 376,
                  height: 376,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 56),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tata',
                                    style: TextStyle(
                                      fontFamily: 'DancingScript',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 50,
                                      color: Color(0xFF264087),
                                      height: 1.2,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Transform.rotate(
                                      angle: 20.1 * math.pi / 180,
                                      child: SvgPicture.asset(
                                        'assets/icons/tata_butterfly.svg',
                                        width: 21.9147,
                                        height: 21.9169,
                                        excludeFromSemantics: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const OnboardingIllustration(),
                              const SizedBox(height: 8),
                              Semantics(
                                header: true,
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontFamily: 'DMSerifDisplay',
                                      fontSize: 34,
                                      height: 1.35,
                                      color: TataColors.ink,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${text.onboardingHeadlineStart}\n',
                                      ),
                                      TextSpan(
                                        text:
                                            '${text.onboardingHeadlineAccent}\n',
                                        style: const TextStyle(
                                          color: Color(0xFF9D8BF4),
                                        ),
                                      ),
                                      TextSpan(
                                        text: text.onboardingHeadlineEnd,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 190,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9D8BF4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                text.onboardingDescription,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF637087),
                                  height: 1.2,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: onStart,
                                child: Text(
                                  text.getStarted,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      text.alreadyHaveAccount,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF637087),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: onSignIn,
                                      child: Text(text.signIn),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
