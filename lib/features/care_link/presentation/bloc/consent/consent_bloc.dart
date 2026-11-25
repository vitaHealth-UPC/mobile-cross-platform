import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/care_link_consent.dart';
import '../../../application/usecases/accept_care_link.dart';
import '../../../application/usecases/register_consent.dart';
import '../../../application/usecases/withdraw_consent.dart';
import '../../../domain/entities/care_link.dart';
import '../../../domain/value_objects/access_code_text.dart';
import 'consent_event.dart';
import 'consent_state.dart';

/// Coordinates invitation exchange and explicit decisions through application ports.
final class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc({
    required this._consent,
    required this._accept,
    required this._decide,
    required this._withdraw,
  }) : super(const ConsentState()) {
    on<ConsentEvent>(_handle);
  }
  final CareLinkConsent _consent;
  final AcceptCareLink _accept;
  final RegisterConsent _decide;
  final WithdrawConsent _withdraw;

  Future<void> _handle(ConsentEvent event, Emitter<ConsentState> emit) async {
    if (state.loading) return;
    final previous = state.link;
    emit(ConsentState(loading: true, link: previous));
    if (event is CaregiverRequestsRequested) {
      final result = await _consent.caregiverRequests();
      if (emit.isDone) return;
      emit(
        ConsentState(
          link: previous,
          requests: switch (result) {
            AppSuccess(:final value) => value,
            AppFailure() => const [],
          },
        ),
      );
      return;
    }
    if (event is CaregiverRequestDecided) {
      final result = await _consent.decideCaregiverRequest(
        event.careLinkId,
        event.accepted,
      );
      if (emit.isDone) return;
      final refreshed = await _consent.caregiverRequests();
      if (emit.isDone) return;
      emit(
        ConsentState(
          link: previous,
          requests: switch (refreshed) {
            AppSuccess(:final value) => value,
            AppFailure() => const [],
          },
          decided: result is AppSuccess<void> ? event.accepted : null,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
      return;
    }
    if (event is AccountRemovalRequested) {
      final result = await _consent.removeAccount();
      if (emit.isDone) return;
      emit(
        ConsentState(
          link: previous,
          withdrawn: result is AppSuccess<void>,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
      return;
    }
    if (event is ConsentWithdrawalRequested) {
      final result = await _withdraw();
      if (emit.isDone) return;
      emit(
        ConsentState(
          link: previous,
          withdrawn: result is AppSuccess<void>,
          errorCode: result is AppFailure<void> ? result.code : null,
        ),
      );
      return;
    }
    if (event case InvitationSubmitted(:final text)) {
      if (AccessCodeText.tryParse(text) case final code?) {
        final redeemed = await _consent.redeem(code);
        if (emit.isDone) return;
        emit(switch (redeemed) {
          AppSuccess(:final value) => ConsentState(redemption: value),
          AppFailure(:final code) => ConsentState(errorCode: code),
        });
        return;
      }
    }
    final AppResult<CareLink> result = switch (event) {
      ConsentRequested() => await _consent.pending(),
      InvitationSubmitted() => await _accept(event.text),
      ConsentDecisionSubmitted() => await _decide(event.accepted),
      ConsentWithdrawalRequested() ||
      CaregiverRequestsRequested() ||
      CaregiverRequestDecided() ||
      AccountRemovalRequested() => throw StateError('Handled above'),
    };
    if (emit.isDone) return;
    emit(
      ConsentState(
        link: result is AppSuccess<CareLink> ? result.value : previous,
        errorCode: result is AppFailure<CareLink> ? result.code : null,
      ),
    );
  }
}
