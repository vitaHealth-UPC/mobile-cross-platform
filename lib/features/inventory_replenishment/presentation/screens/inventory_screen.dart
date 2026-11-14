import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/entities/inventory.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../texts/inventory_texts.dart';

const _gold = Color(0xFFDBAD52);
const _success = Color(0xFF3A7B56);
const _softLavenderBorder = Color(0xFFC9BEF2);

/// Inventory of one medication for the caregiver (Figma 563:1632 stock and
/// restock, 563:5213 invalid quantity, 563:5284 stock replenished).
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.medicationLabel,
    required this.onSessionInvalidated,
    this.personName,
    this.navigationBar,
  });

  /// Name and presentation of the medication, as the catalog shows it.
  final String medicationLabel;
  final String? personName;
  final VoidCallback onSessionInvalidated;
  final Widget? navigationBar;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _quantity = TextEditingController();
  final _lot = TextEditingController();
  final _threshold = TextEditingController();
  final _quantityFocus = FocusNode();

  @override
  void dispose() {
    _quantity.dispose();
    _lot.dispose();
    _threshold.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  void _changed(String _) =>
      context.read<InventoryBloc>().add(const InventoryInputChanged());

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<InventoryBloc, InventoryState>(
      listenWhen: (before, after) =>
          before.errorCode != after.errorCode ||
          before.inventory != after.inventory,
      listener: (context, state) {
        if (isInventorySessionFailure(state.errorCode)) {
          widget.onSessionInvalidated();
          return;
        }
        // A saved write empties its form; the initial quantity must not
        // reappear as a restock quantity.
        if (state.replenished ||
            (state.phase == InventoryPhase.ready &&
                _threshold.text.isNotEmpty)) {
          _quantity.clear();
          _lot.clear();
          _threshold.clear();
        }
      },
      builder: (context, state) {
        final bloc = context.read<InventoryBloc>();
        final first = widget.personName?.trim().split(RegExp(r'\s+')).first;
        return Scaffold(
          backgroundColor: TataColors.background,
          bottomNavigationBar: widget.navigationBar,
          body: SafeArea(
            child: switch (state.phase) {
              InventoryPhase.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              InventoryPhase.failure => ErrorRetry(
                message: inventoryErrorText(text, state.errorCode ?? ''),
                retryLabel: text.invRetry,
                onRetry: () => bloc.add(const InventoryRequested()),
              ),
              _ => ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: text.back,
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      text.invTitle,
                      style: const TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 30,
                        height: 1.25,
                        color: TataColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    first == null || first.isEmpty
                        ? text.invSubtitleGeneric
                        : text.invSubtitle(first),
                    style: const TextStyle(
                      fontSize: 13,
                      color: TataColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.phase == InventoryPhase.ready)
                    ..._ready(context, text, state, state.inventory!)
                  else
                    ..._initial(context, text, state),
                ],
              ),
            },
          ),
        );
      },
    );
  }

  List<Widget> _ready(
    BuildContext context,
    AppLocalizations text,
    InventoryState state,
    Inventory inventory,
  ) {
    final bloc = context.read<InventoryBloc>();
    final last = inventory.lastReplenishment;
    return [
      _StockCard(label: widget.medicationLabel, inventory: inventory),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialog) => AlertDialog(
              title: Text(text.invDefineInitial),
              content: Text(text.invInitialInfo),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop(),
                  child: Text(text.invUnderstood),
                ),
              ],
            ),
          ),
          child: Text(
            text.invDefineInitial,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TataColors.link,
            ),
          ),
        ),
      ),
      ElevatedButton(
        onPressed: state.submitting ? null : _quantityFocus.requestFocus,
        child: Text(text.invRegisterReplenishment),
      ),
      const SizedBox(height: 22),
      _Field(
        label: text.invQuantityReceived,
        hint: text.invQuantityHint,
        controller: _quantity,
        focusNode: _quantityFocus,
        enabled: !state.submitting,
        numeric: true,
        error: state.invalidField == InventoryField.quantity
            ? (text.invInvalidQuantity, text.invInvalidQuantityHint)
            : null,
        onChanged: _changed,
      ),
      const SizedBox(height: 12),
      _Field(
        label: text.invLot,
        hint: text.invLotHint,
        controller: _lot,
        enabled: !state.submitting,
        error: state.invalidField == InventoryField.lot
            ? (text.invInvalidLot, null)
            : null,
        onChanged: _changed,
      ),
      const SizedBox(height: 20),
      OutlinedButton(
        key: const Key('save-replenishment'),
        onPressed: state.submitting
            ? null
            : () => bloc.add(
                ReplenishmentSubmitted(
                  quantity: _quantity.text,
                  lot: _lot.text,
                ),
              ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: TataColors.lavender,
          foregroundColor: TataColors.primary,
          side: const BorderSide(color: _softLavenderBorder),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: Text(
          state.submitting ? text.invSaving : text.invSaveReplenishment,
        ),
      ),
      if (state.replenished) ...[
        const SizedBox(height: 12),
        _Notice(
          text.invReplenished,
          background: TataColors.mint,
          ink: _success,
        ),
      ],
      if (state.errorCode case final code?
          when !isInventorySessionFailure(code)) ...[
        const SizedBox(height: 12),
        _Notice(
          inventoryErrorText(text, code),
          background: TataColors.errorSurface,
          ink: TataColors.errorText,
        ),
      ],
      if (last != null) ...[
        const SizedBox(height: 14),
        _LastReplenishment(batch: last),
      ],
    ];
  }

  List<Widget> _initial(
    BuildContext context,
    AppLocalizations text,
    InventoryState state,
  ) {
    final bloc = context.read<InventoryBloc>();
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(const [
          Color(0xFFFEF1E0),
          Color(0xFFFBE8C8),
        ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.medicationLabel,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TataColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text.invNotInitialized,
              style: const TextStyle(fontSize: 14, color: TataColors.ink),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _Field(
        label: text.invInitialQuantity,
        hint: text.invQuantityHint,
        controller: _quantity,
        enabled: !state.submitting,
        numeric: true,
        error: state.invalidField == InventoryField.quantity
            ? (text.invInvalidQuantity, text.invInvalidQuantityHint)
            : null,
        onChanged: _changed,
      ),
      const SizedBox(height: 12),
      _Field(
        label: text.invThreshold,
        hint: text.invThresholdHint,
        help: text.invThresholdHelp,
        controller: _threshold,
        enabled: !state.submitting,
        numeric: true,
        error: state.invalidField == InventoryField.threshold
            ? (text.invInvalidThreshold, null)
            : null,
        onChanged: _changed,
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        key: const Key('save-initial-stock'),
        onPressed: state.submitting
            ? null
            : () => bloc.add(
                InitialStockSubmitted(
                  quantity: _quantity.text,
                  threshold: _threshold.text,
                ),
              ),
        child: Text(state.submitting ? text.invSaving : text.invSaveInitial),
      ),
      if (state.errorCode case final code?
          when !isInventorySessionFailure(code)) ...[
        const SizedBox(height: 12),
        _Notice(
          inventoryErrorText(text, code),
          background: TataColors.errorSurface,
          ink: TataColors.errorText,
        ),
      ],
    ];
  }
}

BoxDecoration _cardDecoration(List<Color> colors) => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: LinearGradient(colors: colors),
  boxShadow: const [
    BoxShadow(color: Color(0x14173B70), blurRadius: 16, offset: Offset(0, 6)),
  ],
);

class _StockCard extends StatelessWidget {
  const _StockCard({required this.label, required this.inventory});

  final String label;
  final Inventory inventory;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final days = inventory.daysRemaining;
    final low = inventory.lowStock;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: _cardDecoration(const [Color(0xFFFEF1E0), Color(0xFFFBE8C8)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text.invUnitsRemaining(inventory.remainingStock),
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days == null
                      ? text.invNoEstimate
                      : text.invDaysEstimate(days),
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                low ? text.invStatusLow : text.invStatusAvailable,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: low ? TataColors.errorText : _success,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: days == null
                    ? text.invNoEstimate
                    : text.invDaysSemantics(days),
                excludeSemantics: true,
                child: _DaysRing(days: days),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaysRing extends StatelessWidget {
  const _DaysRing({required this.days});
  final int? days;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold, width: 9),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days?.toString() ?? '–',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: TataColors.deepNavy,
                  ),
                ),
                if (days case final value?)
                  Text(
                    text.invDaysShort(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: TataColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.focusNode,
    this.numeric = false,
    this.help,
    this.error,
  });

  final String label;
  final String hint;
  final String? help;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool numeric;

  /// Text shown inside the field and, optionally, the explanation below it.
  final (String, String?)? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: TataColors.muted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : [LengthLimitingTextInputFormatter(240)],
          style: const TextStyle(fontSize: 16, color: TataColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: failed ? error!.$1 : hint,
            hintStyle: TextStyle(
              color: failed ? TataColors.errorText : TataColors.muted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            enabledBorder: border(
              failed ? TataColors.errorText : TataColors.softBorder,
              failed ? 1.5 : 1,
            ),
            disabledBorder: border(TataColors.softBorder),
            focusedBorder: border(
              failed ? TataColors.errorText : TataColors.primary,
              1.5,
            ),
          ),
        ),
        if (error case (_, final String explanation)) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: TataColors.errorText),
            ),
          ),
        ] else if (error case (final String message, null)) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: TataColors.errorText),
            ),
          ),
        ] else if (help case final value?) ...[
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: TataColors.muted),
          ),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.message, {required this.background, required this.ink});
  final String message;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      ),
    ),
  );
}

class _LastReplenishment extends StatelessWidget {
  const _LastReplenishment({required this.batch});
  final InventoryBatch batch;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final units = text.invBatchUnits(batch.quantity);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
      decoration: _cardDecoration(const [Color(0xFFECF5FC), Color(0xFFE0EDF7)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.invLastReplenishment,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat(
                    'dd MMM y',
                    locale,
                  ).format(batch.registeredAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  batch.lot == null
                      ? units
                      : text.invBatchWithLot(units, batch.lot!),
                  style: const TextStyle(fontSize: 12, color: TataColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TataColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  text.invRegistered,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _success,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const ExcludeSemantics(
                child: Icon(
                  Icons.medication_outlined,
                  size: 22,
                  color: TataColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
