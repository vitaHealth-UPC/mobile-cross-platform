import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Original bottle with the Figma glow rendered natively at the device resolution.
/// The 250 px circle and 26 px blur are clipped to the source's 354 px effect bounds.
class MedicationRegistrationArt extends StatelessWidget {
  const MedicationRegistrationArt({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: OverflowBox(
            minWidth: 354,
            maxWidth: 354,
            minHeight: 354,
            maxHeight: 354,
            child: ClipRect(
              child: Center(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 26,
                    sigmaY: 26,
                    tileMode: ui.TileMode.decal,
                  ),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x21DEE8FF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Image.asset(
          'assets/illustrations/registration_bottle.png',
          width: 145,
          height: 160,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ],
    ),
  );
}
