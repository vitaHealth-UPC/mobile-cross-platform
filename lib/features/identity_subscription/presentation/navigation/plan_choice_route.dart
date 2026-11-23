import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subscription_plan.dart';
import '../bloc/plan_choice/plan_choice_cubit.dart';
import '../screens/plan_choice_screen.dart';

/// What the visitor decided: a plan, or registration without one when the
/// catalog could not be read. Going back pops null instead.
typedef PlanChoice = ({SubscriptionPlan? plan});

/// Lets a visitor compare plans and continue to registration (US-48, US-49).
class PlanChoiceRoute extends StatefulWidget {
  const PlanChoiceRoute({
    super.key,
    required this.createCubit,
    this.contactUri,
    this.openContact,
  });

  final PlanChoiceCubit Function() createCubit;

  /// Configured contact destination; null when the deployment has none.
  final Uri? contactUri;

  /// Opens [contactUri] outside the app; false when nothing could open it.
  final Future<bool> Function(Uri uri)? openContact;

  @override
  State<PlanChoiceRoute> createState() => _PlanChoiceRouteState();
}

class _PlanChoiceRouteState extends State<PlanChoiceRoute> {
  late final PlanChoiceCubit _cubit = widget.createCubit()..load();

  /// Set once the destination failed to open, so it is not offered again
  /// (Figma 563:5425: an unavailable external destination is never followed).
  bool _contactFailed = false;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  VoidCallback? get _contact {
    final uri = widget.contactUri;
    final open = widget.openContact;
    if (uri == null || open == null || _contactFailed) return null;
    return () async {
      final opened = await open(uri);
      if (!opened && mounted) setState(() => _contactFailed = true);
    };
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: BlocBuilder<PlanChoiceCubit, PlanChoiceState>(
      builder: (context, state) => PlanChoiceScreen(
        state: state,
        onChoose: (plan) => Navigator.of(context).pop<PlanChoice>((plan: plan)),
        onContinue: () => Navigator.of(context).pop<PlanChoice>((plan: null)),
        onRetry: _cubit.load,
        onContact: _contact,
      ),
    ),
  );
}
