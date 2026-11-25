import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:tata/features/care_link/application/usecases/accept_care_link.dart';
import 'package:tata/features/care_link/application/usecases/end_care_link.dart';
import 'package:tata/features/care_link/application/usecases/issue_adult_access_code.dart';
import 'package:tata/features/care_link/application/usecases/register_consent.dart';
import 'package:tata/features/care_link/application/usecases/withdraw_consent.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_bloc.dart';
import 'package:tata/features/care_link/presentation/bloc/consent/consent_event.dart';
import 'package:tata/features/inventory_replenishment/application/usecases/correct_latest_receipt.dart';
import 'package:tata/features/inventory_replenishment/application/usecases/register_initial_inventory.dart';
import 'package:tata/features/inventory_replenishment/infrastructure/remote/inventory_api.dart';
import 'package:tata/features/inventory_replenishment/infrastructure/repositories/remote_inventory_repository.dart';
import 'package:tata/features/treatment_management/application/usecases/change_treatment_status.dart';
import 'package:tata/features/treatment_management/application/usecases/configure_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/create_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/get_treatment_detail.dart';
import 'package:tata/features/treatment_management/application/usecases/list_treatments.dart';
import 'package:tata/features/treatment_management/application/usecases/register_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/set_dose_frequency.dart';
import 'package:tata/features/treatment_management/application/usecases/set_reminder_policy.dart';
import 'package:tata/features/treatment_management/application/usecases/set_schedule_instructions.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/infrastructure/remote/treatment_api.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_lifecycle_repository.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_readers.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_repository.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_state.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

/// Opt-in probe of the tester's first report against a real local Spring
/// host (`AndroidContractServer`): the same repositories and blocs the app
/// uses, over TCP. Runs only when `TATA_E2E_FIXTURE` names the private
/// fixture file; fixture credentials never appear in the output.
void main() {
  final fixture = Platform.environment['TATA_E2E_FIXTURE'];
  test(
    'tester flows against the local backend',
    () => _probe(fixture!),
    skip: fixture == null ? 'Set TATA_E2E_FIXTURE to run' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _probe(String fixture) async {
  final properties = <String, String>{};
  for (final line in await File(fixture).readAsLines()) {
    if (line.startsWith('#') || !line.contains('=')) continue;
    final separator = line.indexOf('=');
    properties[line.substring(0, separator)] = line
        .substring(separator + 1)
        .replaceAll(r'\:', ':')
        .replaceAll(r'\=', '=');
  }
  final url = Uri.parse(properties['baseUrl'] ?? '');
  if (url.scheme != 'http' || url.host != '127.0.0.1') {
    throw ArgumentError('Only an isolated loopback backend is accepted');
  }
  final adultId = properties['adultId']!;
  final caregiver = MemorySessionStore(
    StoredSession(
      accessToken: properties['caregiverToken']!,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      owner: SessionOwner(properties['caregiverId']!, SessionRole.caregiver),
    ),
  );
  final client = ApiClient(baseUrl: url, client: http.Client());
  try {
    // ---- #3 family list reports whether the adult is signed in.
    final links = RemoteCareLinkRepository(
      api: CareLinkApi(client),
      store: caregiver,
      clock: DateTime.now,
    );
    final family = (await links.readConfirmed() as AppSuccess).value;
    final link = family.singleWhere((item) => item.olderAdultId == adultId);
    _check(link.adultSignedIn == true, 'Signed-in adult not reported');
    stdout.writeln('#3 family list: adult reported as signed in');

    // ---- #2/#4 access code issued by the caregiver, redeemed on a new device.
    final issued = await IssueAdultAccessCode(links)(link.id);
    _check(issued is AppSuccess, 'Access code was not issued: $issued');
    final code = (issued as AppSuccess).value.code as String;
    _check(RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(code), 'Code format');
    final device = MemorySessionStore();
    final consent = RemoteCareLinkConsent(
      api: CareLinkApi(client),
      store: device,
      clock: DateTime.now,
    );
    final bloc = ConsentBloc(
      consent: consent,
      accept: AcceptCareLink(consent),
      decide: RegisterConsent(consent),
      withdraw: WithdrawConsent(consent),
    );
    bloc.add(InvitationSubmitted(code.toLowerCase().replaceAll('-', ' ')));
    final redeemed = await bloc.stream.firstWhere((s) => !s.loading);
    await bloc.close();
    _check(redeemed.redemption?.olderAdultId == adultId, 'Redemption failed');
    _check(
      redeemed.redemption!.pinRegistered || device.current != null,
      'Adult without PIN got no session to create it',
    );
    stdout.writeln(
      '#2/#4 access code: adult identified on a new device '
      '(${redeemed.redemption!.pinRegistered ? 'PIN required' : 'session to create PIN'})',
    );
    final reuse = await RemoteCareLinkConsent(
      api: CareLinkApi(client),
      store: MemorySessionStore(),
      clock: DateTime.now,
    ).redeem(code);
    _check(switch (reuse) {
      AppFailure(:final code) => code == 'LINKING_CODE_EXPIRED_OR_USED',
      AppSuccess() => false,
    }, 'Code could be used twice');
    stdout.writeln('#4 access code: single use enforced');

    // ---- #6b medication registered with its initial stock, then corrected.
    final treatmentApi = TreatmentApi(client);
    final register = RegisterMedication(
      RemoteTreatmentRepository(api: treatmentApi, store: caregiver),
    );
    final metformin =
        (await register(adultId, 'Metformina', '850 mg') as AppSuccess).value;
    final glib =
        (await register(adultId, 'Glibenclamida', '5 mg') as AppSuccess).value;
    final inventory = RemoteInventoryRepository(
      api: InventoryApi(client),
      store: caregiver,
    );
    final stock = await RegisterInitialInventory(inventory)(
      metformin.id,
      quantity: '30',
      threshold: '5',
    );
    _check(stock is AppSuccess, 'Initial stock at registration failed');
    final initial = (stock as AppSuccess).value;
    _check(initial.latestReceiptCorrectable == true, 'Receipt not correctable');
    final corrected = await CorrectLatestReceipt(inventory)(
      metformin.id,
      batchId: initial.newestReceipt.id,
      quantity: '28',
      threshold: '4',
    );
    _check(corrected is AppSuccess, 'Receipt correction failed: $corrected');
    final after = (corrected as AppSuccess).value;
    _check(
      after.remainingStock == 28 &&
          after.replenishmentThreshold == 4 &&
          after.latestReceiptCorrectable == false,
      'Correction did not apply once',
    );
    stdout.writeln('#6b inventory: initial stock corrected once (30 -> 28)');

    // ---- #5/#6 one treatment with two medications and a 6-hour interval.
    final setup = TreatmentSetupBloc(
      create: CreateTreatment(
        RemoteTreatmentRepository(api: treatmentApi, store: caregiver),
      ),
      basics: const SetDoseFrequency(),
      schedule: const SetScheduleInstructions(),
      reminder: const SetReminderPolicy(),
      read: GetTreatmentDetail(
        RemoteTreatmentReader(api: treatmentApi, store: caregiver),
      ),
      configure: ConfigureTreatment(
        RemoteTreatmentLifecycleRepository(api: treatmentApi, store: caregiver),
      ),
      changeStatus: ChangeTreatmentStatus(
        RemoteTreatmentLifecycleRepository(api: treatmentApi, store: caregiver),
      ),
      olderAdultId: adultId,
      medications: [
        SetupMedication(metformin.id, metformin.label),
        SetupMedication(glib.id, glib.label),
      ],
      calendarZone: 'America/Lima',
    );
    setup
      ..add(const TreatmentDraftSubmitted('Diabetes'))
      ..add(
        TreatmentRegimensSubmitted({
          metformin.id: const RegimenInput(
            '1 tableta',
            'Cada 6 horas',
            '02:00,08:00,14:00,20:00',
            'Después del desayuno y la cena',
          ),
          glib.id: const RegimenInput(
            '½ tableta',
            'Una vez al día',
            '07:30',
            'Antes del desayuno',
          ),
        }),
      )
      ..add(const ReminderSubmitted(''));
    await setup.stream.firstWhere((s) => s.step == TreatmentSetupStep.review);
    setup.add(const TreatmentActivationRequested());
    final done = await setup.stream.firstWhere(
      (s) => !s.loading && (s.activated || s.errorCode != null),
    );
    await setup.close();
    _check(
      done.activated,
      'Multi-medication activation failed: ${done.errorCode}',
    );
    final treatments = (await ListTreatments(
      RemoteTreatmentReader(api: treatmentApi, store: caregiver),
    )(adultId) as AppSuccess).value;
    final plan = [
      for (final t in treatments)
        if (t.planId == done.planId) t,
    ];
    _check(
      plan.length == 2 &&
          plan.every((t) => t.status == TreatmentStatus.active) &&
          plan.any((t) => t.scheduledTimes.length == 4),
      'Plan was not stored as one treatment with two active regimens',
    );
    stdout.writeln('#5/#6 treatment: 2 medications, 1 plan, every 6 h active');

    // ---- #1 the caregiver stops caring for the adult.
    final ended = await EndCareLink(links)(link.id);
    _check(ended is AppSuccess, 'Ending the link failed: $ended');
    final remaining = (await links.readConfirmed() as AppSuccess).value;
    _check(
      remaining.every((item) => item.id != link.id),
      'Ended link still listed',
    );
    stdout.writeln('#1 family list: person removed after "Dejar de cuidar"');
    stdout.writeln('All tester flows verified against the local backend.');
  } finally {
    client.close();
  }
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
