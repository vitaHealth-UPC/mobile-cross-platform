import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/care_link_consent.dart';
import '../../../application/usecases/accept_care_link.dart';
import '../../../application/usecases/register_consent.dart';
import '../../../application/usecases/withdraw_consent.dart';
import '../../../domain/entities/care_link.dart';
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
    final AppResult<CareLink> result = switch (event) {
      ConsentRequested() => await _consent.pending(),
      InvitationSubmitted() => await _accept(event.text),
      ConsentDecisionSubmitted() => await _decide(event.accepted),
      ConsentWithdrawalRequested() => throw StateError(
        'Withdrawal handled above',
      ),
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
