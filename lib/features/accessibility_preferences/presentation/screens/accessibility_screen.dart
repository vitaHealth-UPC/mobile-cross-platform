import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../bloc/accessibility/accessibility_bloc.dart';
import '../bloc/accessibility/accessibility_event.dart';
import '../bloc/accessibility/accessibility_state.dart';
import '../widgets/accessibility_save_receipt.dart';

/// Figma accessibility groups with native controls, four text sizes and account sync.
/// Colors follow the selected theme; artwork never replaces a toggle or selector.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key, this.navigationBar});
  final Widget? navigationBar;

  String _sizeLabel(AppLocalizations text, TextSizeLevel level) =>
      switch (level) {
        TextSizeLevel.small => text.pfTextSmall,
        TextSizeLevel.medium => text.pfTextMedium,
        TextSizeLevel.large => text.pfTextLarge,
        TextSizeLevel.extraLarge => text.pfTextExtraLarge,
      };

  void _help(BuildContext context) {
    final text = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.pfHelp),
        content: Text(text.pfHelpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(text.pfClose),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseSize(BuildContext context, TextSizeLevel current) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<AccessibilityBloc>();
    final selected = await showModalBottomSheet<TextSizeLevel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => RadioGroup<TextSizeLevel>(
        groupValue: current,
        onChanged: (value) => Navigator.of(sheetContext).pop(value),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  text.pfTextSize,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final size in TextSizeLevel.values)
                RadioListTile<TextSizeLevel>(
                  title: Text(_sizeLabel(text, size)),
                  value: size,
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      bloc.add(AccessibilityChanged(TextSizeChange(selected)));
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AccessibilityBloc, AccessibilityState>(
    builder: (context, state) {
      final text = AppLocalizations.of(context);
      final bloc = context.read<AccessibilityBloc>();
      final prefs = state.accessibility;
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final dark = theme.brightness == Brightness.dark;
      final normal = !dark && !prefs.highContrast;
      void change(AccessibilityChange value) =>
          bloc.add(AccessibilityChanged(value));
      final titleStyle = theme.textTheme.bodyMedium!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      );
      final hintStyle = theme.textTheme.bodySmall!.copyWith(
        fontSize: 11,
        color: colors.onSurfaceVariant,
      );
      Widget icon(String asset, Color background) => CircleAvatar(
        radius: 17,
        backgroundColor: normal ? background : colors.surfaceContainerHighest,
        child: SvgPicture.asset(
          'assets/icons/accessibility_$asset.svg',
          colorFilter: normal
              ? null
              : ColorFilter.mode(colors.onSurface, BlendMode.srcIn),
        ),
      );
      Widget toggle({
        required String title,
        required String hint,
        required Widget leading,
        required bool value,
        required ValueChanged<bool> onChanged,
      }) => SwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        secondary: ExcludeSemantics(child: leading),
        title: Text(title, style: titleStyle),
        subtitle: Text(hint, style: hintStyle),
        value: value,
        onChanged: onChanged,
        activeTrackColor: colors.primary,
        trackOutlineColor: normal
            ? const WidgetStatePropertyAll(Colors.transparent)
            : null,
        inactiveTrackColor: normal
            ? const Color(0xFFE8EAF1)
            : colors.surfaceContainerHighest,
        inactiveThumbColor: normal ? Colors.white : colors.onSurfaceVariant,
      );
      Widget heading(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 12),
        child: Semantics(
          header: true,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return Scaffold(
        bottomNavigationBar: state.receipt == null
            ? navigationBar
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AccessibilitySaveReceipt(field: state.receipt!),
                  ?navigationBar,
                ],
              ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: normal
                ? const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFF8F8FE),
                      Color(0xFFFCFBFF),
                    ],
                  )
                : null,
            color: normal ? null : theme.scaffoldBackgroundColor,
          ),
          child: SafeArea(
            bottom: navigationBar == null,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              children: [
                const _AccessibilityHeader(),
                heading(text.pfViewGroup),
                _Group(
                  children: [
                    ListTile(
                      key: const Key('accessibility-text-size'),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      leading: ExcludeSemantics(
                        child: icon('text_size', const Color(0xFFF0EBFF)),
                      ),
                      title: Text(text.pfLargeTextTitle, style: titleStyle),
                      subtitle: Text(text.pfLargeTextHint, style: hintStyle),
                      onTap: () => _chooseSize(context, prefs.textSize),
                      trailing: Switch(
                        value: prefs.largeTextEnabled,
                        activeTrackColor: colors.primary,
                        inactiveThumbColor: normal
                            ? Colors.white
                            : colors.onSurfaceVariant,
                        trackOutlineColor: normal
                            ? const WidgetStatePropertyAll(Colors.transparent)
                            : null,
                        onChanged: (value) => change(
                          TextSizeChange(
                            value ? TextSizeLevel.large : TextSizeLevel.medium,
                          ),
                        ),
                      ),
                    ),
                    toggle(
                      title: text.pfHighContrast,
                      hint: text.pfContrastHint,
                      leading: icon('contrast', const Color(0xFFEDF5FF)),
                      value: prefs.highContrast,
                      onChanged: (value) => change(HighContrastChange(value)),
                    ),
                    toggle(
                      title: text.pfDarkTheme,
                      hint: text.pfDarkThemeHint,
                      leading: icon('dark_mode', const Color(0xFFF0EBFF)),
                      value: prefs.darkTheme,
                      onChanged: (value) => change(DarkThemeChange(value)),
                    ),
                  ],
                ),
                heading(text.pfInteractionGroup),
                _Group(
                  children: [
                    toggle(
                      title: text.pfReducedMotion,
                      hint: text.pfReducedMotionHint,
                      leading: icon('reduce_motion', const Color(0xFFE7F6F0)),
                      value: prefs.reducedMotion,
                      onChanged: (value) => change(ReducedMotionChange(value)),
                    ),
                    toggle(
                      title: text.pfVoiceConfirmation,
                      hint: text.pfVoiceHint,
                      leading: icon('voice', const Color(0xFFF0EBFF)),
                      value: prefs.voiceConfirmation,
                      onChanged: (value) =>
                          change(VoiceConfirmationChange(value)),
                    ),
                  ],
                ),
                heading(text.pfHelp),
                _Group(
                  children: [
                    toggle(
                      title: text.pfReadingAssistance,
                      hint: text.pfReadingAssistanceHint,
                      leading: icon('reading', const Color(0xFFE7F6F0)),
                      value: prefs.readingAssistance,
                      onChanged: (value) =>
                          change(ReadingAssistanceChange(value)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Material(
                  color: normal
                      ? const Color(0xFFEEF1FF)
                      : colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _help(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text.pfNeedHelp,
                                  style: titleStyle.copyWith(
                                    fontSize: 13,
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(text.pfHelpSummary, style: hintStyle),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _Group(
                  children: [
                    ListTile(
                      title: Text(text.pfLanguage, style: titleStyle),
                      subtitle: Text(
                        state.language.displayName,
                        style: hintStyle,
                      ),
                      trailing: Icon(Icons.translate, color: colors.primary),
                      onTap: () => bloc.add(const LanguageToggled()),
                    ),
                  ],
                ),
                if (state.sync != AccessibilitySyncStatus.unknown) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      state.sync == AccessibilitySyncStatus.synced
                          ? text.pfSyncSynced
                          : text.pfSyncPending,
                      style: hintStyle,
                    ),
                  ),
                ],
                if (state.errorCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        text.pfErrGeneric,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    elevation: 3,
    shadowColor: const Color(0x141A2138),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          children[index],
        ],
      ],
    ),
  );
}

/// A wide title gets the whole line when system and app text scaling combine.
class _AccessibilityHeader extends StatelessWidget {
  const _AccessibilityHeader();
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final back = IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: text.back,
      icon: Icon(Icons.chevron_left, color: colors.primary),
    );
    final caption = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.pfAccessibilityTitle,
          style: TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 25,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text.pfAccessibilitySubtitle,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(25) > 42) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [back, caption],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        back,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: caption,
          ),
        ),
      ],
    );
  }
}
