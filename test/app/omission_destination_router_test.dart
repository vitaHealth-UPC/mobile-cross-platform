import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/omission_destination_router.dart';
import 'package:tata/features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'package:tata/features/omission_escalation/application/readmodels/push_destination.dart';
import 'package:tata/shared/common/result/app_result.dart';

CaregiverLinkSummary _profile(String adult) => CaregiverLinkSummary(
  id: 'link-$adult',
  olderAdultId: adult,
  fullName: 'Rosa Vargas',
  confirmedAt: DateTime.utc(2026, 11, 1),
);

const _caregiver = CaregiverAlertsDestination(
  caregiverId: 'caregiver-a',
  olderAdultId: 'adult-a',
  medicationName: 'Never a person name',
  intakeId: 'dose-a',
);

void main() {
  var generation = 0;
  var allowed = true;
  late List<(String, String?)> opened;
  late List<String> unavailable;
  late Future<AppResult<List<CaregiverLinkSummary>>> Function() read;

  OmissionDestinationRouter router() => OmissionDestinationRouter(
    mayOpen: (_) async => allowed,
    sessionGeneration: () => generation,
    readProfiles: () => read(),
    openCaregiver: (profile, intake) async =>
        opened.add((profile.fullName, intake)),
    openAdultDose: (dose) => opened.add((dose.olderAdultId, dose.intakeId)),
    openAdultHome: () => opened.add(('home', null)),
    onUnavailable: unavailable.add,
  );

  setUp(() {
    generation = 0;
    allowed = true;
    opened = [];
    unavailable = [];
    read = () async => AppSuccess([_profile('adult-a')]);
  });

  test('caregiver uses the confirmed person name and exact intake', () async {
    await router().open(_caregiver);
    expect(opened, [('Rosa Vargas', 'dose-a')]);
  });

  test('a revoked recipient never reads profiles or opens a route', () async {
    allowed = false;
    read = () => throw StateError('must not read');
    await router().open(_caregiver);
    expect(opened, isEmpty);
  });

  test('missing relationship never falls back to another person', () async {
    read = () async => AppSuccess([_profile('adult-b')]);
    await router().open(_caregiver);
    expect(opened, isEmpty);
    expect(unavailable, ['ACCESS_DENIED']);
  });

  test(
    'a profile response after account change cannot open the old recipient',
    () async {
      final receipt = Completer<AppResult<List<CaregiverLinkSummary>>>();
      read = () => receipt.future;
      final opening = router().open(_caregiver);
      await Future<void>.delayed(Duration.zero);
      generation++;
      receipt.complete(AppSuccess([_profile('adult-a')]));
      await opening;
      expect(opened, isEmpty);
    },
  );

  test(
    'a newer adult request supersedes a delayed caregiver profile read',
    () async {
      final receipt = Completer<AppResult<List<CaregiverLinkSummary>>>();
      read = () => receipt.future;
      final target = router();
      final old = target.open(_caregiver);
      await Future<void>.delayed(Duration.zero);
      await target.open(
        const OlderAdultDoseDestination(
          olderAdultId: 'adult-c',
          intakeId: 'dose-c',
        ),
      );
      receipt.complete(AppSuccess([_profile('adult-a')]));
      await old;
      expect(opened, [('adult-c', 'dose-c')]);
    },
  );

  test(
    'transport failure stays explicit without opening cached profile data',
    () async {
      read = () async => const AppFailure('NETWORK_UNAVAILABLE');
      await router().open(_caregiver);
      expect(opened, isEmpty);
      expect(unavailable, ['NETWORK_UNAVAILABLE']);
    },
  );

  test('disposing the router cancels pending navigation', () async {
    final receipt = Completer<AppResult<List<CaregiverLinkSummary>>>();
    read = () => receipt.future;
    final target = router();
    final opening = target.open(_caregiver);
    await Future<void>.delayed(Duration.zero);
    target.dispose();
    receipt.complete(AppSuccess([_profile('adult-a')]));
    await opening;
    expect(opened, isEmpty);
  });
}
