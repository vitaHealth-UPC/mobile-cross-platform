import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/family_summary.dart';

/// Figma 563:727 cards built from authorized monitoring evidence.
/// Empty and unavailable sources retain distinct messages; sample metrics are not used.
class FamilySummaryCards extends StatelessWidget {
  const FamilySummaryCards({
    super.key,
    required this.summary,
    this.onAgenda,
    this.onHistory,
    this.onContact,
    this.onAlerts,
    this.onStock,
    this.onAddMedication,
    this.onLinkAnother,
  });
  final FamilySummary summary;
  final VoidCallback? onAgenda;
  final VoidCallback? onHistory;
  final VoidCallback? onContact;
  final VoidCallback? onAlerts;
  final ValueChanged<StockAttention>? onStock;
  final VoidCallback? onAddMedication;
  final VoidCallback? onLinkAnother;

  static const _muted = Color(0xFF5B6475);

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekly = summary.weekly;
    final today = summary.today;
    final next = summary.nextDose;
    final singleStock =
        summary.inventoryAvailable && summary.stockAttention.length == 1
        ? summary.stockAttention.first
        : null;
    return DefaultTextStyle.merge(
      style: const TextStyle(color: TataColors.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.openAlerts.isNotEmpty) ...[
            _SummaryPanel(
              colors: const [TataColors.errorSurface, TataColors.errorSurface],
              onTap: onAlerts,
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    text.fmPendingSummary(summary.openAlerts.length),
                    style: const TextStyle(
                      color: TataColors.errorText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    text.fmSeeAlerts,
                    style: const TextStyle(color: TataColors.errorText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SummaryPanel(
            colors: const [Color(0xFFE8F5EB), Color(0xFFDDEDE1)],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.fmWeeklyAdherence,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF296345),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (weekly.percentage) {
                          final double value => '${value.round()}%',
                          null => text.fmNoData,
                        },
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weekly.total == 0
                            ? text.fmNoResolved
                            : text.fmWeeklyConfirmed(
                                weekly.confirmed,
                                weekly.total,
                              ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/summary_gauge.svg',
                  width: 112,
                  height: 84,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SummaryPanel(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.fmToday,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.MMMMEEEEd(locale).format(summary.date),
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            text.fmTodayProgress(today.confirmed, today.total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            text.fmDosesCompleted,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 10, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: today.total == 0 ? 0 : today.confirmed / today.total,
                    minHeight: 6,
                    color: const Color(0xFF75A985),
                    backgroundColor: const Color(0xFFE4E5EC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SummaryPanel(
            colors: const [Color(0xFFF1ECFF), Color(0xFFE7DFFC)],
            child: LayoutBuilder(
              builder: (context, constraints) {
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.fmNextDose,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next?.medicationName ?? text.fmNoNextDose,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 4),
                      Text(next.dose, style: const TextStyle(fontSize: 11)),
                    ],
                  ],
                );
                if (next == null) return details;
                final time = Text(
                  DateFormat(
                    'h:mm a',
                    locale,
                  ).format(next.scheduledAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                );
                if (constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(15) > 20) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [details, const SizedBox(height: 10), time],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    time,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          if (singleStock != null)
            _SummaryPanel(
              colors: const [Color(0xFFFFF4DF), Color(0xFFFBE9C8)],
              onTap: onStock == null ? null : () => onStock!(singleStock),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.fmAttention,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF805511),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text.fmLowStock(
                            singleStock.remaining,
                            singleStock.medicationName,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text.fmRestockHint,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  if (onStock != null)
                    const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            )
          else
            _SummaryPanel(
              colors: const [Color(0xFFFFF4DF), Color(0xFFFBE9C8)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.fmAttention,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF805511),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!summary.inventoryAvailable)
                    Text(
                      text.fmInventoryUnavailable,
                      style: const TextStyle(fontSize: 13),
                    )
                  else if (summary.stockAttention.isEmpty)
                    Text(text.fmNoRestock, style: const TextStyle(fontSize: 13))
                  else
                    for (final stock in summary.stockAttention)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          text.fmLowStock(
                            stock.remaining,
                            stock.medicationName,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          text.fmRestockHint,
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                        trailing: onStock == null
                            ? null
                            : const Icon(Icons.chevron_right, size: 20),
                        onTap: onStock == null ? null : () => onStock!(stock),
                      ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            text.fmQuickMonitoring,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryAction(
                  label: text.fmViewAgenda,
                  asset: 'summary_agenda',
                  colors: const [Color(0xFFECF7EF), Color(0xFFE1F0E5)],
                  onTap: onAgenda,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryAction(
                  label: text.fmQuickHistory,
                  asset: 'summary_history',
                  colors: const [Color(0xFFF1ECFF), Color(0xFFE8E1FC)],
                  onTap: onHistory,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryAction(
                  label: text.fmQuickContact,
                  asset: 'summary_contact',
                  colors: const [Color(0xFFECF5FB), Color(0xFFDFECF6)],
                  onTap: onContact,
                ),
              ),
            ],
          ),
          if (onAddMedication != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAddMedication,
              child: Text(text.fmAddMedication),
            ),
          ],
          if (onLinkAnother != null)
            TextButton(
              onPressed: onLinkAnother,
              child: Text(text.fmMoreLinkPerson),
            ),
        ],
      ),
    );
  }
}

/// Native gradient surface, with ink above its decoration when actionable.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.child,
    this.colors = const [Colors.white, Colors.white],
    this.onTap,
  });
  final Widget child;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    ),
  );
}

class _SummaryAction extends StatelessWidget {
  const _SummaryAction({
    required this.label,
    required this.asset,
    required this.colors,
    this.onTap,
  });
  final String label;
  final String asset;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _SummaryPanel(
    colors: colors,
    onTap: onTap,
    child: Column(
      children: [
        SvgPicture.asset(
          'assets/icons/$asset.svg',
          width: 22,
          height: 22,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: onTap == null ? TataColors.muted : TataColors.ink,
          ),
        ),
      ],
    ),
  );
}
