import 'package:flutter/material.dart';

import '../theme/tata_colors.dart';

/// Circle with up to two initials; used when no real profile photo exists.
/// Mockup photos are never assigned to real users.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  final String? name;
  final double size;

  /// First letters of the first two words, upper-cased; empty for a blank name.
  static String initialsOf(String? name) => (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TataColors.lavender,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: initials.isEmpty
            ? Icon(
                Icons.person_outline,
                size: size * 0.5,
                color: TataColors.primary,
              )
            : Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w600,
                  color: TataColors.primary,
                ),
              ),
      ),
    );
  }
}
