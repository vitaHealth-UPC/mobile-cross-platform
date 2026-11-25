import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/adult_access_code.dart';

/// Lets the caregiver give the adult a new way in when they changed phones,
/// reinstalled the app or signed out: a short single-use code typed in
/// "Soy adulto mayor". The code is shown large, with copy as the main action.
class AdultAccessCodeCard extends StatefulWidget {
  const AdultAccessCodeCard({
    super.key,
    required this.olderAdultName,
    required this.issue,
    this.signedIn,
    this.title,
    this.buttonLabel,
    this.intro,
    this.explanation,
  });

  /// Overrides for reusing the card for other single-use codes (another
  /// caregiver's invitation); null keeps the adult sign-in texts.
  final String? title;
  final String? buttonLabel;
  final String? intro;
  final String Function(String firstName, String time)? explanation;

  final String olderAdultName;
  final Future<AppResult<AdultAccessCode>> Function() issue;

  /// Whether the adult currently has a session; null when unknown.
  final bool? signedIn;

  @override
  State<AdultAccessCodeCard> createState() => _AdultAccessCodeCardState();
}

class _AdultAccessCodeCardState extends State<AdultAccessCodeCard> {
  AdultAccessCode? _code;
  bool _loading = false;
  bool _failed = false;

  Future<void> _request() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await widget.issue();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case AppSuccess(:final value):
          _code = value;
        case AppFailure():
          _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final first = widget.olderAdultName.trim().split(RegExp(r'\s+')).first;
    final code = _code;
    return Container(
      key: widget.key == null ? const Key('adult-access-card') : null,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2138),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title ?? text.accessCodeTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: TataColors.ink,
            ),
          ),
          if (widget.intro != null || widget.signedIn == false) ...[
            const SizedBox(height: 6),
            Text(
              widget.intro ?? text.adultStatusSignedOutHint,
              style: const TextStyle(fontSize: 13, color: TataColors.muted),
            ),
          ],
          if (code != null) ...[
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: SelectableText(
                code.code,
                key: const Key('adult-access-code'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: TataColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text.accessCodeExplanation(
                first,
                TimeOfDay.fromDateTime(code.expiresAt.toLocal())
                    .format(context),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: TataColors.muted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              key: const Key('copy-access-code'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(text.accessCodeCopied)),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: Text(text.accessCodeCopy),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 14),
          if (_failed) ...[
            Text(
              text.accessCodeFailed,
              style: const TextStyle(fontSize: 13, color: TataColors.errorText),
            ),
            const SizedBox(height: 8),
          ],
          (code == null ? ElevatedButton.new : OutlinedButton.new)(
            key: const Key('new-access-code'),
            onPressed: _loading ? null : _request,
            child: Text(
              _loading
                  ? text.processing
                  : widget.buttonLabel ?? text.accessCodeNew,
            ),
          ),
        ],
      ),
    );
  }
}
