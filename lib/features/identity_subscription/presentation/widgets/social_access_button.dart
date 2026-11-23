import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/presentation/theme/tata_colors.dart';

/// Provider action using its original local SVG and a native outlined button.
class SocialAccessButton extends StatelessWidget {
  const SocialAccessButton({
    super.key,
    required this.label,
    required this.asset,
    required this.iconWidth,
    required this.onPressed,
  });
  final String label;
  final String asset;
  final double iconWidth;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: TataColors.link,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: TataColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: SvgPicture.asset(asset, width: iconWidth, height: 24),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
