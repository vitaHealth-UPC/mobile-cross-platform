import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/usecases/update_caregiver_profile.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/features/care_link/presentation/bloc/profile_editor/profile_editor_cubit.dart';
import 'package:tata/features/care_link/presentation/navigation/profile_editor_route.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/memory_session_store.dart';
import '../support/visual_capture.dart';

void main() {
  setUpAll(loadTataFonts);
  final now = DateTime(2026, 11, 18);
  final born = DateTime.utc(1958, 5, 12);
  final original = <String, Object>{
    'id': 'adult-A',
    'registeredByCaregiverId': 'caregiver-A',
    'fullName': 'Rosa Vargas',
    'birthDate': '1958-05-12',
  };
  StoredSession session([String id = 'caregiver-A']) => StoredSession(
    accessToken: 'token-$id',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner(id, SessionRole.caregiver),
  );
  RemoteCareLinkRepository repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteCareLinkRepository(
      api: CareLinkApi(client),
      store: store,
      clock: () => now,
    );
  }

  test(
    'update sends only basic fields with the captured caregiver bearer',
    () async {
      final repo = repository(MemorySessionStore(session()), (request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/older-adults/adult-A');
        expect(request.headers['Authorization'], 'Bearer token-caregiver-A');
        expect(jsonDecode(request.body), {
          'fullName': 'Rosa Actualizada',
          'birthDate': '1958-05-12',
        });
        return http.Response(
          jsonEncode({...original, 'fullName': 'Rosa Actualizada'}),
          200,
        );
      });
      final result = await UpdateCaregiverProfile(repo, () => now)(
        'adult-A',
        '  Rosa Actualizada  ',
        born,
      );
      expect(result, isA<AppSuccess>());
    },
  );

  for (final changed in [
    {'id': 'other-adult'},
    {'registeredByCaregiverId': 'other-caregiver'},
    {'fullName': 'Another name'},
    {'birthDate': '1959-05-12'},
  ]) {
    test(
      'refuses a mismatching update receipt: ${changed.keys.single}',
      () async {
        final repo = repository(
          MemorySessionStore(session()),
          (_) async =>
              http.Response(jsonEncode({...original, ...changed}), 200),
        );
        final result = await repo.updateProfile('adult-A', 'Rosa Vargas', born);
        expect((result as AppFailure).code, 'INVALID_RESPONSE');
      },
    );
  }

  test('read refuses a profile registered by a different caregiver', () async {
    final repo = repository(
      MemorySessionStore(session()),
      (_) async => http.Response(
        jsonEncode({...original, 'registeredByCaregiverId': 'other'}),
        200,
      ),
    );
    expect(
      (await repo.readProfile('adult-A') as AppFailure).code,
      'INVALID_RESPONSE',
    );
  });

  test(
    'invalid names and future calendar dates do not reach the API',
    () async {
      var calls = 0;
      final repo = repository(MemorySessionStore(session()), (_) async {
        calls++;
        return http.Response('{}', 500);
      });
      final update = UpdateCaregiverProfile(repo, () => now);
      expect(
        (await update('adult-A', ' ', born) as AppFailure).code,
        'INVALID_NAME',
      );
      expect(
        (await update(
          'adult-A',
          'Rosa',
          DateTime(2026, 11, 19),
        ) as AppFailure).code,
        'INVALID_BIRTH_DATE',
      );
      expect(
        (await update('', 'Rosa', born) as AppFailure).code,
        'INVALID_REFERENCE',
      );
      expect(calls, 0);
    },
  );

  test(
    'an update response after changing account never acknowledges success',
    () async {
      final store = MemorySessionStore(session());
      final response = Completer<http.Response>();
      final repo = repository(store, (_) => response.future);
      final result = repo.updateProfile('adult-A', 'Rosa Vargas', born);
      await Future<void>.delayed(Duration.zero);
      await store.replace(
        session('caregiver-B'),
        expectedGeneration: store.generation,
      );
      response.complete(http.Response(jsonEncode(original), 200));
      expect((await result as AppFailure).code, 'SESSION_CHANGED');
    },
  );

  test(
    'double save produces one write and closing discards its late receipt',
    () async {
      final response = Completer<http.Response>();
      var writes = 0;
      final repo = repository(MemorySessionStore(session()), (request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(original), 200);
        }
        writes++;
        return response.future;
      });
      final cubit = ProfileEditorCubit(
        editor: repo,
        update: UpdateCaregiverProfile(repo, () => now),
        olderAdultId: 'adult-A',
      );
      await cubit.load();
      final first = cubit.save('Rosa Vargas', born);
      await cubit.save('Rosa Vargas', born);
      await Future<void>.delayed(Duration.zero);
      expect(writes, 1);
      await cubit.close();
      response.complete(http.Response(jsonEncode(original), 200));
      await first;
      expect(cubit.state.saved, isFalse);
    },
  );

  Future<void> open(
    WidgetTester tester,
    RemoteCareLinkRepository repo, {
    double scale = 1,
    ValueChanged<String?>? onReturned,
    VoidCallback? onInvalidated,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('profile-editor-capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await openProfileEditor(
                    context,
                    createCubit: () => ProfileEditorCubit(
                      editor: repo,
                      update: UpdateCaregiverProfile(repo, () => now),
                      olderAdultId: 'adult-A',
                    ),
                    onSessionInvalidated: onInvalidated ?? () {},
                  );
                  onReturned?.call(result?.fullName);
                },
                child: const Text('Abrir perfil'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir perfil'));
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'native form preserves entered fields on retry at scale $scale',
      (tester) async {
        var writes = 0;
        String? returned;
        final repo = repository(MemorySessionStore(session()), (request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode(original), 200);
          }
          writes++;
          if (writes == 1) return http.Response('{}', 500);
          return http.Response(
            jsonEncode({...original, 'fullName': 'Rosa Actualizada'}),
            200,
          );
        });
        await open(
          tester,
          repo,
          scale: scale,
          onReturned: (name) => returned = name,
        );
        expect(find.text('Editar perfil'), findsOneWidget);
        await captureWidget(
          tester,
          find.byKey(const Key('profile-editor-capture')),
          'profile_editor_$scale',
        );
        await tester.enterText(find.byType(TextFormField), 'Rosa Actualizada');
        await tester.ensureVisible(find.text('Guardar cambios'));
        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();
        expect(find.text('Rosa Actualizada'), findsOneWidget);
        expect(find.text('Guardar cambios'), findsOneWidget);
        await tester.tap(find.text('Guardar cambios'));
        await tester.pumpAndSettle();
        expect(returned, 'Rosa Actualizada');
        expect(writes, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cancel returns without writing to the server', (tester) async {
    var writes = 0;
    final repo = repository(MemorySessionStore(session()), (request) async {
      if (request.method == 'PUT') writes++;
      return http.Response(jsonEncode(original), 200);
    });
    await open(tester, repo);
    await tester.enterText(find.byType(TextFormField), 'Not saved');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Abrir perfil'), findsOneWidget);
  });

  testWidgets('lost permission closes the form and revalidates the session', (
    tester,
  ) async {
    var invalidations = 0;
    final repo = repository(
      MemorySessionStore(session()),
      (request) async => request.method == 'GET'
          ? http.Response(jsonEncode(original), 200)
          : http.Response('{}', 403),
    );
    await open(tester, repo, onInvalidated: () => invalidations++);
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(invalidations, 1);
    expect(find.byType(TextFormField), findsNothing);
  });
}
