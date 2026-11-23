import 'package:flutter/material.dart';

import 'tata_colors.dart';

/// Text roles matching Tata headings, field labels and supporting copy.
abstract final class TataTypography {
  static const heading = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 29,
    height: 1.25,
    color: TataColors.ink,
  );
  static const subtitle = TextStyle(
    fontSize: 12,
    height: 1.5,
    color: TataColors.muted,
  );
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: TataColors.muted,
  );
}
