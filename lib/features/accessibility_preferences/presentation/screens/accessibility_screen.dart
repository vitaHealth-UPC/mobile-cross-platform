import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../bloc/accessibility/accessibility_bloc.dart';
import '../bloc/accessibility/accessibility_event.dart';
import '../bloc/accessibility/accessibility_state.dart';

/// Accessibility and language settings. Changes apply immediately on this device and sync
/// to the account when a connection is available.
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocBuilder<AccessibilityBloc, AccessibilityState>(
      builder: (context, state) {
        final bloc = context.read<AccessibilityBloc>();
        final prefs = state.accessibility;
        void change(AccessibilityChange value) =>
            bloc.add(AccessibilityChanged(value));
        return Scaffold(
          appBar: AppBar(
            title: Text(text.pfAccessibilityTitle),
            actions: [
              IconButton(
                tooltip: text.pfHelp,
                icon: const Icon(Icons.help_outline),
                onPressed: () => _help(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                text.pfTextSize,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TextSizeLevel>(
                showSelectedIcon: false,
                segments: [
                  for (final level in TextSizeLevel.values)
                    ButtonSegment(
                      value: level,
                      label: Text(
                        _sizeLabel(text, level),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {prefs.textSize},
                onSelectionChanged: (value) =>
                    change(TextSizeChange(value.first)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(text.pfHighContrast),
                value: prefs.highContrast,
                onChanged: (value) => change(HighContrastChange(value)),
              ),
              SwitchListTile(
                title: Text(text.pfDarkTheme),
                value: prefs.darkTheme,
                onChanged: (value) => change(DarkThemeChange(value)),
              ),
              SwitchListTile(
                title: Text(text.pfReducedMotion),
                value: prefs.reducedMotion,
                onChanged: (value) => change(ReducedMotionChange(value)),
              ),
              SwitchListTile(
                title: Text(text.pfReadingAssistance),
                subtitle: Text(text.pfReadingAssistanceHint),
                value: prefs.readingAssistance,
                onChanged: (value) => change(ReadingAssistanceChange(value)),
              ),
              SwitchListTile(
                title: Text(text.pfVoiceConfirmation),
                value: prefs.voiceConfirmation,
                onChanged: (value) => change(VoiceConfirmationChange(value)),
              ),
              ListTile(
                title: Text(text.pfLanguage),
                subtitle: Text(state.language.displayName),
                trailing: const Icon(Icons.translate),
                onTap: () => bloc.add(const LanguageToggled()),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(switch (state.sync) {
                  AccessibilitySyncStatus.unknown => '',
                  AccessibilitySyncStatus.synced => text.pfSyncSynced,
                  AccessibilitySyncStatus.pending => text.pfSyncPending,
                }),
              ),
              if (state.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      text.pfErrGeneric,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
