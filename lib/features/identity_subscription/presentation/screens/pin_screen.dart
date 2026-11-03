import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../domain/value_objects/pin_code.dart';
import '../bloc/pin/pin_state.dart';

/// Figma 563:1338 (access), 563:1970 (setup), 563:2034 (incorrect) and
/// 563:2098 (locked) built from native widgets. Shows dots, never digits.
class PinScreen extends StatelessWidget {
  const PinScreen({
    super.key,
    required this.mode,
    required this.adultName,
    required this.filled,
    required this.busy,
    required this.locked,
    required this.canSubmit,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
    this.errorTitle,
    this.errorText,
    this.onBack,
  });

  final PinMode mode;
  final String? adultName;
  final int filled;
  final bool busy;
  final bool locked;
  final bool canSubmit;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final String? errorTitle;
  final String? errorText;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final setup = mode == PinMode.setup;
    final keysEnabled = !busy && !locked;
    return PopScope(
      canPop: !busy && onBack != null,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      setup ? text.pinSetupTitle : text.pinAccessTitle,
                      style: TataTypography.heading,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      setup ? text.pinSetupSubtitle : text.pinAccessSubtitle,
                      style: TataTypography.subtitle,
                    ),
                    const SizedBox(height: 22),
                    _AdultCard(
                      name: adultName,
                      fallbackName: text.olderAdultBadge,
                      hint: setup ? text.pinSetupHint : text.pinAccessHint,
                      badge: text.olderAdultBadge,
                    ),
                    const SizedBox(height: 24),
                    Text(text.pinLabel, style: TataTypography.label),
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      label: text.pinDigitsEntered(filled),
                      child: ExcludeSemantics(child: _PinDots(filled: filled)),
                    ),
                    const SizedBox(height: 34),
                    _Keypad(
                      enabled: keysEnabled,
                      deleteLabel: text.pinDeleteDigit,
                      onDigit: onDigit,
                      onDelete: onDelete,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: canSubmit ? onSubmit : null,
                      child: Text(
                        busy
                            ? text.pinProcessing
                            : locked
                            ? text.pinTryLater
                            : setup
                            ? text.pinSubmitSetup
                            : text.pinSubmitAccess,
                      ),
                    ),
                    if (errorTitle != null || setup) ...[
                      const SizedBox(height: 10),
                      _Notice(
                        error: errorTitle != null,
                        title: errorTitle ?? text.pinSetupInfoTitle,
                        body: errorText ?? text.pinSetupInfoBody,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(text.pinForgot, style: TataTypography.subtitle),
                    if (onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: busy ? null : onBack,
                          child: Text(text.back),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdultCard extends StatelessWidget {
  const _AdultCard({
    required this.name,
    required this.fallbackName,
    required this.hint,
    required this.badge,
  });

  /// Null when the profile could not be read; the avatar then shows an icon.
  final String? name;
  final String fallbackName;
  final String hint;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5EB), Color(0xFFDDEDE1)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14173B70),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(name: name, size: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The badge shares the name line so the hint keeps the full width.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          name ?? fallbackName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TataColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: TataColors.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(hint, style: TataTypography.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TataColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F173B70),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var index = 0; index < PinCode.length; index++)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TataColors.lavender,
                shape: BoxShape.circle,
                border: Border.all(color: TataColors.softBorder),
              ),
              child: index < filled
                  ? const DecoratedBox(
                      key: ValueKey('pin-dot-filled'),
                      decoration: BoxDecoration(
                        color: TataColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 8),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.deleteLabel,
    required this.onDigit,
    required this.onDelete,
  });

  final bool enabled;
  final String deleteLabel;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final key in row)
                  key.isEmpty
                      ? const SizedBox.square(dimension: 54)
                      : _KeypadButton(
                          label: key,
                          semanticLabel: key == '⌫' ? deleteLabel : key,
                          onPressed: enabled
                              ? () => key == '⌫' ? onDelete() : onDigit(key)
                              : null,
                        ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14173B70),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: label == '⌫'
                  ? Icon(
                      Icons.backspace_outlined,
                      size: 20,
                      color: onPressed == null
                          ? TataColors.muted
                          : TataColors.deepNavy,
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: onPressed == null
                            ? TataColors.muted
                            : TataColors.deepNavy,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.error, required this.title, required this.body});

  final bool error;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: error,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: error ? TataColors.errorSurface : TataColors.infoSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: error ? TataColors.errorText : TataColors.infoText,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: TataTypography.subtitle),
          ],
        ),
      ),
    );
  }
}
