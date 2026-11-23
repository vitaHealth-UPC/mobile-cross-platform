import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/infrastructure/mappers/adherence_mapper.dart';

Map<String, Object?> summaryJson({Map<String, Object?> overrides = const {}}) =>
    {
      'periodDays': 30,
      'scheduledCount': 120,
      'adherencePercent': 92,
      'adherenceChangePercent': 8,
      'onTimePercent': 86,
      'onTimeChangePercent': null,
      'lateCount': 6,
      'omittedCount': 4,
      'trend': [
        {'date': '2026-09-20', 'adherencePercent': 57},
        {'date': '2026-09-27', 'adherencePercent': 74},
      ],
      'recentIntakes': [
        {
          'scheduledAt': '2026-10-06T13:00:00Z',
          'medicationName': 'Losartán',
          'status': 'CONFIRMED',
          'minutesLate': null,
        },
        {
          'scheduledAt': '2026-10-05T01:00:00Z',
          'medicationName': 'Amlodipino',
          'status': 'LATE',
          'minutesLate': 24,
        },
        {
          'scheduledAt': '2026-10-03T18:00:00-05:00',
          'medicationName': 'Vitamina D3',
          'status': 'OMITTED',
          'minutesLate': null,
        },
      ],
      'pattern': {'timeBand': 'EVENING', 'omittedCount': 4, 'lateCount': 6},
      ...overrides,
    };

Map<String, Object?> insightJson({Map<String, Object?> overrides = const {}}) =>
    {
      'periodDays': 30,
      'pattern': {
        'type': 'OMISSION',
        'timeBand': 'EVENING',
        'omittedCount': 4,
        'lateCount': 2,
        'fromHour': 18,
        'toHour': 21,
      },
      'concentration': [
        [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
        [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
        [0.8, 0.8, 0.8, 0.2, 0.2, 0.2, 0.2],
      ],
      'recommendations': [
        'ADJUST_REMINDER',
        'REVIEW_SCHEDULE',
        'FOLLOW_UP_ONE_WEEK',
      ],
      ...overrides,
    };

void main() {
  group('summary', () {
    test('keeps the figures, the absent change and the pattern', () {
      final summary = AdherenceMapper.summary(summaryJson(), periodDays: 30);

      expect(summary.adherencePercent, 92);
      expect(summary.adherenceChangePercent, 8);
      expect(summary.onTimePercent, 86);
      expect(summary.onTimeChangePercent, isNull);
      expect(summary.lateCount, 6);
      expect(summary.omittedCount, 4);
      expect(summary.pattern?.timeBand, AdherenceTimeBand.evening);
      expect(summary.pattern?.omittedCount, 4);
    });

    test('maps trend dates to calendar dates and intakes to local time', () {
      final summary = AdherenceMapper.summary(summaryJson(), periodDays: 30);

      expect(summary.trend.first.date, DateTime(2026, 9, 20));
      expect(summary.trend.last.adherencePercent, 74);
      expect(summary.recentIntakes.map((i) => i.outcome), [
        IntakeOutcome.onTime,
        IntakeOutcome.late,
        IntakeOutcome.omitted,
      ]);
      expect(summary.recentIntakes[1].minutesLate, 24);
      expect(
        summary.recentIntakes[0].scheduledAt.toUtc(),
        DateTime.utc(2026, 10, 6, 13),
      );
      expect(
        summary.recentIntakes[2].scheduledAt.toUtc(),
        DateTime.utc(2026, 10, 3, 23),
      );
    });

    test('accepts missing optional lists and a null pattern', () {
      final summary = AdherenceMapper.summary(
        summaryJson(
          overrides: {'trend': null, 'recentIntakes': null, 'pattern': null},
        ),
        periodDays: 30,
      );

      expect(summary.trend, isEmpty);
      expect(summary.recentIntakes, isEmpty);
      expect(summary.pattern, isNull);
    });

    test('rejects bodies that do not describe the requested period', () {
      expect(
        () => AdherenceMapper.summary(summaryJson(), periodDays: 7),
        throwsFormatException,
      );
    });

    test('rejects out-of-range figures and negative counts', () {
      for (final overrides in <Map<String, Object?>>[
        {'adherencePercent': 101},
        {'onTimePercent': -1},
        {'lateCount': -2},
        {'omittedCount': -1},
        {'scheduledCount': -1},
        {
          'trend': [
            {'date': '2026-09-20', 'adherencePercent': 140},
          ],
        },
      ]) {
        expect(
          () => AdherenceMapper.summary(
            summaryJson(overrides: overrides),
            periodDays: 30,
          ),
          throwsFormatException,
          reason: '$overrides',
        );
      }
    });

    test('rejects missing fields, wrong types and non-object bodies', () {
      final missing = summaryJson()..remove('onTimePercent');

      for (final body in <Object?>[
        missing,
        summaryJson(overrides: {'adherencePercent': '92'}),
        summaryJson(overrides: {'trend': 'none'}),
        <Object?>[],
        null,
      ]) {
        expect(
          () => AdherenceMapper.summary(body, periodDays: 30),
          throwsFormatException,
        );
      }
    });

    test('rejects unknown statuses, bands and invalid dates', () {
      for (final overrides in <Map<String, Object?>>[
        {
          'recentIntakes': [
            {
              'scheduledAt': '2026-10-06T13:00:00Z',
              'medicationName': 'X',
              'status': '???',
            },
          ],
        },
        {
          'pattern': {'timeBand': 'NOON', 'omittedCount': 1, 'lateCount': 1},
        },
        {
          'trend': [
            {'date': '2026-02-31', 'adherencePercent': 50},
          ],
        },
        {
          'trend': [
            {'date': '20/09/2026', 'adherencePercent': 50},
          ],
        },
      ]) {
        expect(
          () => AdherenceMapper.summary(
            summaryJson(overrides: overrides),
            periodDays: 30,
          ),
          throwsFormatException,
          reason: '$overrides',
        );
      }
    });

    test('rejects local timestamps and minutes late on a non-late intake', () {
      for (final intake in <Map<String, Object?>>[
        {
          'scheduledAt': '2026-10-06T13:00:00',
          'medicationName': 'X',
          'status': 'CONFIRMED',
        },
        {
          'scheduledAt': '2026-10-06T13:00:00Z',
          'medicationName': 'X',
          'status': 'CONFIRMED',
          'minutesLate': 5,
        },
      ]) {
        expect(
          () => AdherenceMapper.summary(
            summaryJson(
              overrides: {
                'recentIntakes': [intake],
              },
            ),
            periodDays: 30,
          ),
          throwsFormatException,
        );
      }
    });
  });

  group('insight', () {
    test('maps the pattern, the concentration and the actions', () {
      final insight = AdherenceMapper.insight(insightJson(), periodDays: 30);

      expect(insight.pattern.type, AdherencePatternType.omission);
      expect(insight.pattern.timeBand, AdherenceTimeBand.evening);
      expect(insight.pattern.fromHour, 18);
      expect(insight.pattern.toHour, 21);
      expect(insight.concentration, hasLength(3));
      expect(insight.concentration[2].first, 0.8);
      expect(insight.recommendations, [
        AdherenceRecommendation.adjustReminder,
        AdherenceRecommendation.reviewSchedule,
        AdherenceRecommendation.followUpOneWeek,
      ]);
    });

    test('accepts whole-number intensities and the lateness type', () {
      final insight = AdherenceMapper.insight(
        insightJson(
          overrides: {
            'pattern': {
              'type': 'LATENESS',
              'timeBand': 'NIGHT',
              'omittedCount': 0,
              'lateCount': 3,
              'fromHour': 23,
              'toHour': 3,
            },
            'concentration': [
              [0, 0, 0, 0, 0, 0, 0],
              [0, 0, 0, 0, 0, 0, 1],
              [0, 0, 0, 0, 0, 0, 0],
            ],
          },
        ),
        periodDays: 30,
      );

      expect(insight.pattern.type, AdherencePatternType.lateness);
      expect(insight.pattern.toHour, 3);
      expect(insight.concentration[1].last, 1.0);
    });

    test('drops recommendation codes it does not know', () {
      final insight = AdherenceMapper.insight(
        insightJson(
          overrides: {
            'recommendations': ['ADJUST_REMINDER', 'SOMETHING_NEW'],
          },
        ),
        periodDays: 30,
      );

      expect(insight.recommendations, [AdherenceRecommendation.adjustReminder]);
    });

    test('rejects a different period, unknown types and bad hours', () {
      final pattern = insightJson()['pattern']! as Map<String, Object?>;

      for (final body in <Map<String, Object?>>[
        insightJson(overrides: {'periodDays': 7}),
        insightJson(
          overrides: {
            'pattern': {...pattern, 'type': 'OTHER'},
          },
        ),
        insightJson(
          overrides: {
            'pattern': {...pattern, 'fromHour': 24},
          },
        ),
        insightJson(
          overrides: {
            'pattern': {...pattern, 'toHour': 25},
          },
        ),
        insightJson(
          overrides: {
            'pattern': {...pattern, 'toHour': -1},
          },
        ),
      ]) {
        expect(
          () => AdherenceMapper.insight(body, periodDays: 30),
          throwsFormatException,
        );
      }
    });

    test('rejects a concentration that is not three rows by seven days', () {
      for (final concentration in <Object?>[
        [
          [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
        ],
        [
          [0.2, 0.2, 0.2],
          [0.2, 0.2, 0.2],
          [0.2, 0.2, 0.2],
        ],
        [
          [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 1.4],
          [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
          [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
        ],
        'none',
      ]) {
        expect(
          () => AdherenceMapper.insight(
            insightJson(overrides: {'concentration': concentration}),
            periodDays: 30,
          ),
          throwsFormatException,
          reason: '$concentration',
        );
      }
    });
  });
}
