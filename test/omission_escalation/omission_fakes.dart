import 'package:tata/features/omission_escalation/application/ports/omission_ports.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';

/// In-memory followed targets.
final class MemoryPushTargets implements PushTargetStore {
  final Map<String, String> caregivers = {};
  final Map<String, String> adults = {};

  @override
  Future<void> rememberCaregiver(
    String olderAdultId,
    String caregiverId,
  ) async => caregivers[olderAdultId] = caregiverId;

  @override
  Future<void> rememberOlderAdult(
    String olderAdultId,
    String olderAdultName,
  ) async => adults[olderAdultId] = olderAdultName;

  @override
  Future<String?> caregiverFor(String olderAdultId) async =>
      caregivers[olderAdultId];

  @override
  Future<String?> olderAdultName(String olderAdultId) async =>
      adults[olderAdultId];
}

/// Records what a notifier was asked to show or clear.
final class RecordingNotifier implements OmissionNotifier {
  final List<OmissionPush> shown = [];
  int cleared = 0;

  @override
  Future<void> show(OmissionPush push) async => shown.add(push);

  @override
  Future<void> clearDisplayed() async => cleared++;
}

/// Token source that answers from a queue, or never answers.
final class ScriptedTokenSource implements DevicePushTokenSource {
  ScriptedTokenSource(this.answers, {this.hangs = false});
  final List<AppResult<String?>> answers;
  final bool hangs;
  int calls = 0;

  @override
  Future<AppResult<String?>> currentToken() {
    calls++;
    if (hangs) {
      return Future<AppResult<String?>>.delayed(
        const Duration(days: 1),
        () => const AppSuccess(null),
      );
    }
    final index = calls - 1 < answers.length ? calls - 1 : answers.length - 1;
    return Future.value(answers[index]);
  }
}

/// Registry that records calls and answers from a queue.
class RecordingRegistry implements DeviceTokenRegistry {
  RecordingRegistry([List<AppResult<void>>? answers])
    : answers = answers ?? [const AppSuccess(null)];
  final List<AppResult<void>> answers;
  final List<({String token, StoredSession? session})> registered = [];
  final List<StoredSession?> unregistered = [];

  @override
  Future<AppResult<void>> register(
    String token, {
    StoredSession? expectedSession,
  }) async {
    registered.add((token: token, session: expectedSession));
    final index = registered.length - 1 < answers.length
        ? registered.length - 1
        : answers.length - 1;
    return answers[index];
  }

  @override
  Future<AppResult<void>> unregister({StoredSession? expectedSession}) async {
    unregistered.add(expectedSession);
    return const AppSuccess(null);
  }
}
