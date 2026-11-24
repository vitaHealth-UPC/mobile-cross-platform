import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/omission_messaging_host.dart';
import 'package:tata/app/tata_app.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/repositories/session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/features/omission_escalation/application/ports/omission_delivery.dart';
import 'package:tata/features/omission_escalation/application/readmodels/push_destination.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';

class _Delivery implements OmissionDelivery {
  final opened = StreamController<PushDestination>.broadcast();
  final sessions = <bool>[];
  int starts = 0;
  bool disposed = false;
  bool failStart = false;
  @override
  Stream<PushDestination> get destinations => opened.stream;
  @override
  Future<bool> start() async {
    starts++;
    if (failStart) throw Exception('SDK unavailable');
    return true;
  }

  @override
  Future<void> sessionChanged({required bool authenticated}) async =>
      sessions.add(authenticated);
  @override
  Future<void> beforeSignOut() async {}
  @override
  Future<void> dispose() async {
    disposed = true;
    await opened.close();
  }
}

class _Repository implements SessionRepository {
  @override
  Future<AppResult<AccountSession?>> restore() async => AppSuccess(
    AccountSession(
      owner: SessionOwner(
        'adult-a',
        SessionRole.olderAdult,
        careLinkId: 'link-a',
      ),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    _Delivery delivery,
    List<PushDestination> opened,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      TataApp(
        createAccessBloc: () => AccessBloc(
          signIn: SignIn(repository),
          restore: RestoreSession(repository),
          signOut: SignOut(repository),
        ),
        adultBuilder: (_, _, _) =>
            const Scaffold(body: Text('Authenticated home')),
        applicationObserver: (child) => OmissionMessagingHost(
          delivery: delivery,
          onOpen: (destination) async => opened.add(destination),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('root host observes access, opens after a frame and disposes', (
    tester,
  ) async {
    final delivery = _Delivery();
    final opened = <PushDestination>[];
    await mount(tester, delivery, opened);
    expect(delivery.starts, 1);
    expect(delivery.sessions, contains(true));
    final beforeResume = delivery.sessions.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(delivery.sessions.length, greaterThan(beforeResume));
    delivery.opened.add(
      const OlderAdultDoseDestination(
        olderAdultId: 'adult-a',
        intakeId: 'dose-a',
      ),
    );
    await tester.pumpAndSettle();
    expect((opened.single as OlderAdultDoseDestination).intakeId, 'dose-a');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(delivery.disposed, isTrue);
  });

  testWidgets('missing SDK leaves the authenticated root usable', (
    tester,
  ) async {
    final delivery = _Delivery()..failStart = true;
    await mount(tester, delivery, []);
    expect(find.text('Authenticated home'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
