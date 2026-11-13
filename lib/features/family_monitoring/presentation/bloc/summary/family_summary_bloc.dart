import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/application/time/clock.dart';
import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/monitoring_ports.dart';
import '../../../application/readmodels/monitoring_readmodels.dart';
import '../../../application/usecases/summary_usecases.dart';
import '../../texts/monitoring_texts.dart';

/// Intents of the family summary.
sealed class FamilySummaryEvent {
  const FamilySummaryEvent();
}

/// Load or reload the summary of the adult.
final class FamilySummaryRequested extends FamilySummaryEvent {
  const FamilySummaryRequested();
}

/// Open the contact dialog; the channel is read when it is asked for.
final class FamilyContactRequested extends FamilySummaryEvent {
  const FamilyContactRequested();
}

final class FamilyContactDismissed extends FamilySummaryEvent {
  const FamilyContactDismissed();
}

enum FamilySummaryStatus { loading, ready, failure }

/// Content and loading state of the contact dialog.
final class FamilyContactDialog {
  const FamilyContactDialog({this.option, this.errorCode});
  final ContactOption? option;
  final String? errorCode;

  bool get loading => option == null && errorCode == null;
}

/// Observable family summary and its currently open contact dialog.
final class FamilySummaryState {
  const FamilySummaryState({
    this.status = FamilySummaryStatus.loading,
    this.summary,
    this.errorCode,
    this.contact,
  });

  final FamilySummaryStatus status;
  final FamilySummary? summary;
  final String? errorCode;
  final FamilyContactDialog? contact;
}

/// Coordinates summary refreshes and the protected contact action. Only the latest request
/// of each kind may emit, and a lost access removes every protected value.
final class FamilySummaryBloc
    extends Bloc<FamilySummaryEvent, FamilySummaryState> {
  FamilySummaryBloc({
    required this._summary,
    required this._contact,
    required this.olderAdultId,
    required this.olderAdultName,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const FamilySummaryState()) {
    on<FamilySummaryRequested>(_load);
    on<FamilyContactRequested>(_openContact);
    on<FamilyContactDismissed>((event, emit) {
      _contactRevision++;
      emit(
        FamilySummaryState(
          status: state.status,
          summary: state.summary,
          errorCode: state.errorCode,
        ),
      );
    });
  }

  final GetFamilySummary _summary;
  final ContactOptionReader _contact;
  final String olderAdultId;
  final String olderAdultName;
  final Clock _clock;
  int _revision = 0;
  int _contactRevision = 0;

  Future<void> _load(
    FamilySummaryRequested event,
    Emitter<FamilySummaryState> emit,
  ) async {
    final revision = ++_revision;
    final previous = state.summary;
    emit(
      FamilySummaryState(
        status: FamilySummaryStatus.loading,
        summary: previous,
        contact: state.contact,
      ),
    );
    final now = _clock();
    final result = await _summary(
      olderAdultId,
      olderAdultName,
      DateTime(now.year, now.month, now.day),
    );
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          FamilySummaryState(
            status: FamilySummaryStatus.ready,
            summary: value,
            contact: state.contact,
          ),
        );
      case AppFailure(:final code):
        _contactRevision++;
        emit(
          FamilySummaryState(
            status: FamilySummaryStatus.failure,
            errorCode: code,
          ),
        );
    }
  }

  Future<void> _openContact(
    FamilyContactRequested event,
    Emitter<FamilySummaryState> emit,
  ) async {
    final revision = ++_contactRevision;
    emit(
      FamilySummaryState(
        status: state.status,
        summary: state.summary,
        errorCode: state.errorCode,
        contact: const FamilyContactDialog(),
      ),
    );
    final result = await _contact(olderAdultId);
    if (revision != _contactRevision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          FamilySummaryState(
            status: state.status,
            summary: state.summary,
            errorCode: state.errorCode,
            contact: FamilyContactDialog(option: value),
          ),
        );
      case AppFailure(:final code) when isAccessFailure(code):
        // Access was lost: nothing protected stays on screen.
        _revision++;
        emit(
          FamilySummaryState(
            status: FamilySummaryStatus.failure,
            errorCode: code,
          ),
        );
      case AppFailure(:final code):
        emit(
          FamilySummaryState(
            status: state.status,
            summary: state.summary,
            errorCode: state.errorCode,
            contact: FamilyContactDialog(errorCode: code),
          ),
        );
    }
  }
}
