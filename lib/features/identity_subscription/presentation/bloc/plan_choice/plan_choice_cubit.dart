import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/get_public_plans.dart';
import '../../../domain/entities/subscription_plan.dart';

enum PlanChoiceStatus { loading, ready, failure }

/// Public plans shown to a visitor before registration (Figma 563:1913).
final class PlanChoiceState {
  const PlanChoiceState({
    this.status = PlanChoiceStatus.loading,
    this.plans = const [],
    this.errorCode,
  });

  final PlanChoiceStatus status;
  final List<SubscriptionPlan> plans;
  final String? errorCode;
}

final class PlanChoiceCubit extends Cubit<PlanChoiceState> {
  PlanChoiceCubit(this._plans) : super(const PlanChoiceState());

  final GetPublicPlans _plans;
  int _revision = 0;

  Future<void> load() async {
    final revision = ++_revision;
    emit(const PlanChoiceState());
    final result = await _plans();
    if (revision != _revision || isClosed) return;
    emit(switch (result) {
      AppSuccess(:final value) => PlanChoiceState(
        status: PlanChoiceStatus.ready,
        plans: value,
      ),
      AppFailure(:final code) => PlanChoiceState(
        status: PlanChoiceStatus.failure,
        errorCode: code,
      ),
    });
  }
}
