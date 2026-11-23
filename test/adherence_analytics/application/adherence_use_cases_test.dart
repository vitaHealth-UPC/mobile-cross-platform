import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/ports/recommendations_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_recommendations.dart';
import 'package:tata/shared/common/result/app_result.dart';

/// Records the request and answers with a fixed result.
final class _SummaryReader implements AdherenceReader {
  _SummaryReader(this.result);

  final AppResult<AdherenceSummary?> result;
  final requests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays,
  ) async {
    requests.add((olderAdultId, periodDays));
    return result;
  }
}

final class _InsightReader implements RecommendationsReader {
  _InsightReader(this.result);

  final AppResult<AdherenceInsight?> result;
  final requests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceInsight?>> insight(
    String olderAdultId,
    int periodDays,
  ) async {
    requests.add((olderAdultId, periodDays));
    return result;
  }
}

void main() {
  group('GetAdherenceSummary', () {
    test('trims the adult and delegates the supported period', () async {
      final reader = _SummaryReader(const AppSuccess(null));

      final result = await GetAdherenceSummary(reader)(' adult-A ', 30);

      expect(result, isA<AppSuccess<AdherenceSummary?>>());
      expect(reader.requests, [('adult-A', 30)]);
    });

    test('keeps an empty period as a null success, not an error', () async {
      final result = await GetAdherenceSummary(
        _SummaryReader(const AppSuccess(null)),
      )('adult-A', 7);

      expect((result as AppSuccess<AdherenceSummary?>).value, isNull);
    });

    test('rejects a blank adult before reading', () async {
      final reader = _SummaryReader(const AppSuccess(null));

      final result = await GetAdherenceSummary(reader)('  ', 30);

      expect((result as AppFailure).code, 'INVALID_OLDER_ADULT_REFERENCE');
      expect(reader.requests, isEmpty);
    });

    test('rejects periods outside one to thirty-one days', () async {
      final reader = _SummaryReader(const AppSuccess(null));

      for (final days in [0, -1, 32, 365]) {
        final result = await GetAdherenceSummary(reader)('adult-A', days);
        expect((result as AppFailure).code, 'INVALID_PERIOD');
      }
      expect(reader.requests, isEmpty);
    });

    test('accepts the period boundaries', () async {
      final reader = _SummaryReader(const AppSuccess(null));

      await GetAdherenceSummary(reader)('adult-A', 1);
      await GetAdherenceSummary(reader)('adult-A', 31);

      expect(reader.requests, [('adult-A', 1), ('adult-A', 31)]);
    });

    test('passes a reader failure through without translating it', () async {
      final result = await GetAdherenceSummary(
        _SummaryReader(const AppFailure('ACCESS_DENIED')),
      )('adult-A', 30);

      expect((result as AppFailure).code, 'ACCESS_DENIED');
    });
  });

  group('GetRecommendations', () {
    test('trims the adult and delegates the supported period', () async {
      final reader = _InsightReader(const AppSuccess(null));

      await GetRecommendations(reader)(' adult-A ', 30);

      expect(reader.requests, [('adult-A', 30)]);
    });

    test('rejects a blank adult and unsupported periods', () async {
      final reader = _InsightReader(const AppSuccess(null));

      final blank = await GetRecommendations(reader)('', 30);
      final tooLong = await GetRecommendations(reader)('adult-A', 40);

      expect((blank as AppFailure).code, 'INVALID_OLDER_ADULT_REFERENCE');
      expect((tooLong as AppFailure).code, 'INVALID_PERIOD');
      expect(reader.requests, isEmpty);
    });

    test('keeps insufficient evidence as a null success', () async {
      final result = await GetRecommendations(
        _InsightReader(const AppSuccess(null)),
      )('adult-A', 30);

      expect((result as AppSuccess<AdherenceInsight?>).value, isNull);
    });
  });
}
