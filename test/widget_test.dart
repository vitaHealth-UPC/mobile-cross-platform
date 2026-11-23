import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/tata_app.dart';
import 'package:tata/features/identity_subscription/application/usecases/restore_session.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_out.dart';
import 'package:tata/features/identity_subscription/domain/entities/account_session.dart';
import 'package:tata/features/identity_subscription/domain/repositories/session_repository.dart';
import 'package:tata/features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/common/result/app_result.dart';

void main() {
  testWidgets('root restores, signs in through bloc, and signs out', (
    tester,
  ) async {
    final repository = _SessionRepository();
    await tester.pumpWidget(
      TataApp(
        createAccessBloc: () => AccessBloc(
          signIn: SignIn(repository),
          restore: RestoreSession(repository),
          signOut: SignOut(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.restores, 1);
    expect(find.text('Comenzar'), findsOneWidget);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'USER@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'password');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(repository.email, 'user@example.com');
    expect(find.text('Sesión iniciada'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(repository.signOuts, 1);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('password'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// Root composition test double; transport contracts have separate tests.
final class _SessionRepository implements SessionRepository {
  int restores = 0;
  int signOuts = 0;
  String? email;

  @override
  Future<AppResult<AccountSession?>> restore() async {
    restores++;
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<AccountSession>> signIn(
    String email,
    String password,
  ) async {
    this.email = email;
    return AppSuccess(
      AccountSession(
        owner: SessionOwner('test-owner', SessionRole.caregiver),
        expiresAt: DateTime.utc(2030),
      ),
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    signOuts++;
    return const AppSuccess(null);
  }
}
