import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../application/readmodels/older_adult_profile.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/care_link_invitation.dart';

/// Caregiver view of Figma 563:1440 using real profile and challenge receipts.
/// Consent is read-only here; a caregiver cannot approve it for the adult.
class LinkPersonScreen extends StatelessWidget {
  const LinkPersonScreen({
    super.key,
    required this.profile,
    required this.link,
    required this.confirmed,
    required this.loading,
    required this.onGenerate,
    required this.onRefresh,
    required this.onSignOut,
    this.errorText,
  });
  final OlderAdultProfile profile;
  final CareLink? link;
  final bool confirmed;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final code = link?.code;
    final today = DateTime.now();
    final birthday = profile.birthDate;
    final birthdayPending =
        today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day);
    final age = today.year - birthday.year - (birthdayPending ? 1 : 0);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.linkTitle, style: TataTypography.heading),
                  const SizedBox(height: 4),
                  Text(text.linkSubtitle, style: TataTypography.subtitle),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 18,
                    ),
                    decoration: _panel(Colors.white),
                    child: Row(
                      children: [
                        _step('1', text.linkCodeStep, true),
                        const Expanded(
                          child: Divider(color: TataColors.border),
                        ),
                        _step('2', text.linkRequestStep, code != null),
                        const Expanded(
                          child: Divider(color: TataColors.border),
                        ),
                        _step('3', text.linkConsentStep, confirmed),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(text.temporaryCode, style: TataTypography.label),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: _panel(Colors.white),
                    child: SelectableText(
                      code?.value ?? text.codeNotIssued,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _panel(Colors.white),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: const Color(0xFFF1ECFF),
                          child: Text(
                            String.fromCharCode(profile.fullName.runes.first)
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.adultNameAndAge(profile.fullName, age),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                confirmed
                                    ? text.linkConfirmed
                                    : text.linkPending,
                                style: TataTypography.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (!confirmed)
                    ElevatedButton(
                      onPressed: loading ? null : onGenerate,
                      child: Text(
                        loading
                            ? text.processing
                            : code == null
                            ? text.generateCode
                            : text.renewCode,
                      ),
                    ),
                  if (code != null && !confirmed)
                    TextButton.icon(
                      onPressed: loading
                          ? null
                          : () async {
                              final invitation = CareLinkInvitation(
                                caregiverId: link!.caregiverId,
                                code: code.value,
                              );
                              await Clipboard.setData(
                                ClipboardData(text: invitation.encode()),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(text.invitationCopied),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.copy),
                      label: Text(text.copyInvitation),
                    ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF1ECFF), Color(0xFFE7DFFC)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.adultConsentTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          confirmed
                              ? text.consentConfirmed
                              : text.caregiverConsentExplanation,
                          style: TataTypography.subtitle,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: loading ? null : onRefresh,
                          child: Text(text.checkConsent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: _panel(const Color(0xFFEEF6FC)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.safeLinkTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.safeLinkExplanation,
                          style: TataTypography.subtitle,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: loading ? null : onSignOut,
                    child: Text(text.signOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _panel(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(color: Color(0x141A2138), offset: Offset(0, 6), blurRadius: 18),
    ],
  );

  Widget _step(String number, String label, bool active) => Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/link_step_${active ? 'active' : 'inactive'}.svg',
            width: 18,
            height: 18,
          ),
          Text(
            number,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : TataColors.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 9, color: TataColors.primary),
      ),
    ],
  );
}
