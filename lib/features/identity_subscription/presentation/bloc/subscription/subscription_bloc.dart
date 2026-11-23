import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/subscription_usecases.dart';

import 'subscription_event.dart';
import 'subscription_state.dart';

/// Plan and subscription of the caregiver's account (US-44, US-45). A plan is
/// chosen first and changed only after an explicit confirmation.
final class SubscriptionBloc
    extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({required this._overview, required this._change})
    : super(const SubscriptionState()) {
    on<SubscriptionRequested>(_load);
    on<SubscriptionPlanSelected>(_select);
    on<SubscriptionChangeConfirmed>(_confirm);
  }

  final GetSubscriptionOverview _overview;
  final ChangeSubscriptionPlan _change;

  Future<void> _load(
    SubscriptionRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state.changing) return;
    emit(const SubscriptionState());
    final result = await _overview();
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess(value: (final subscription, final plans)) => SubscriptionState(
        phase: SubscriptionPhase.ready,
        subscription: subscription,
        plans: plans,
      ),
      AppFailure(:final code) => SubscriptionState(
        phase: SubscriptionPhase.failure,
        errorCode: code,
      ),
    });
  }

  void _select(
    SubscriptionPlanSelected event,
    Emitter<SubscriptionState> emit,
  ) {
    final subscription = state.subscription;
    if (state.phase != SubscriptionPhase.ready ||
        state.changing ||
        subscription == null) {
      return;
    }
    final plan = state.plans.where((plan) => plan.code == event.code);
    if (plan.isEmpty || subscription.isOn(plan.first)) return;
    // Choosing the selected plan again clears the choice.
    emit(
      state.copyWith(
        selectedCode: state.selectedCode == event.code ? null : event.code,
        clearSelection: state.selectedCode == event.code,
      ),
    );
  }

  Future<void> _confirm(
    SubscriptionChangeConfirmed event,
    Emitter<SubscriptionState> emit,
  ) async {
    final target = state.selected;
    if (target == null || state.changing) return;
    emit(state.copyWith(changing: true));
    final result = await _change(target.code);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          SubscriptionState(
            phase: SubscriptionPhase.ready,
            subscription: value,
            plans: state.plans,
            updated: true,
          ),
        );
      case AppFailure(:final code):
        emit(state.copyWith(changing: false, errorCode: code));
    }
  }
}
