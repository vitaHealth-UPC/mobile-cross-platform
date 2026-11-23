import '../../../application/readmodels/daily_progress.dart';
import '../../../domain/entities/intake.dart';

/// Observable phases of the adult home.
enum HomeStatus { loading, ready, failure }

/// Ready with a null [next] means no pending intake, not an error.
final class HomeState {
  const HomeState({
    this.status = HomeStatus.loading,
    this.next,
    this.progress,
    this.errorCode,
  });

  final HomeStatus status;
  final Intake? next;

  /// Null when today's agenda could not be read; the next intake still shows.
  final DailyProgress? progress;
  final String? errorCode;
}
