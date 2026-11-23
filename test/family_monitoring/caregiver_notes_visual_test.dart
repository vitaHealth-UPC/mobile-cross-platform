import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/ports/monitored_person_reader.dart';
import 'package:tata/features/family_monitoring/application/readmodels/monitored_person.dart';
import 'package:tata/features/family_monitoring/application/usecases/get_follow_up_notes.dart';
import 'package:tata/features/family_monitoring/application/usecases/register_follow_up_note.dart';
import 'package:tata/features/family_monitoring/domain/entities/notes.dart';
import 'package:tata/features/family_monitoring/domain/repositories/notes_repository.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/note_composer_cubit.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/screens/notes_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';
import 'monitoring_application_test.dart' show FakeNotes, FakePersonReader;

final _now = DateTime(2026, 11, 20, 12);
final _person = MonitoredPerson(
  id: 'adult-1',
  fullName: 'Rosa Vargas',
  birthDate: DateTime(1958, 7, 1),
);
List<FollowUpNote> _notes() => [
  FollowUpNote(
    id: 3,
    text: 'Salida de la tarde\nRosa suele olvidar la toma cuando sale a caminar. Confirmar antes de las 6:00 p. m.',
    recordedAt: DateTime(2026, 11, 20, 10),
    familiarId: 'caregiver-1',
  ),
  FollowUpNote(
    id: 2,
    text: 'Seguimiento\nAyer confirmó la toma con 24 min de retraso.',
    recordedAt: DateTime(2026, 11, 19, 10),
    familiarId: 'caregiver-1',
  ),
  FollowUpNote(
    id: 1,
    text: 'Preferencia\nPrefiere recibir una llamada si no responde al segundo recordatorio.',
    recordedAt: DateTime(2026, 7, 20),
    familiarId: 'caregiver-1',
  ),
];

final class _People implements MonitoredPersonReader {
  Completer<AppResult<MonitoredPerson>>? pending;
  int reads = 0;
  @override
  Future<AppResult<MonitoredPerson>> read(String id) {
    reads++;
    return pending?.future ?? Future.value(AppSuccess(_person));
  }
}

final class _PendingNotes implements NotesRepository {
  final save = Completer<AppResult<FollowUpNote>>();
  @override
  Future<AppResult<List<FollowUpNote>>> notes(String id) async =>
      AppSuccess(_notes());
  @override
  Future<AppResult<FollowUpNote>> register(String id, String text) =>
      save.future;
}

void main() {
  setUpAll(loadTataFonts);
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'caregiver notes render authorized profile and timeline at $scale',
      (tester) async {
        await _show(tester, FakeNotes(list: _notes()), _People(), scale: scale);
        expect(find.text('Rosa Vargas'), findsOneWidget);
        expect(find.text('68 años · vínculo activo'), findsOneWidget);
        expect(find.text('Salida de la tarde'), findsOneWidget);
        expect(find.text('Hoy - Tú'), findsOneWidget);
        await captureWidget(
          tester,
          find.byKey(const Key('caregiver-notes-capture')),
          'caregiver-notes-576-2859-$scale',
        );
        if (scale > 1) {
          await tester.ensureVisible(find.text('Agregar nota'));
          await tester.pumpAndSettle();
          await captureWidget(
            tester,
            find.byKey(const Key('caregiver-notes-capture')),
            'caregiver-notes-576-2859-$scale-bottom',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('refresh waits for both notes and the authorized profile', (
    tester,
  ) async {
    final people = _People();
    final bloc = await _show(tester, FakeNotes(list: _notes()), people);
    people.pending = Completer<AppResult<MonitoredPerson>>();
    var finished = false;
    final completion = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh()
        .then((_) => finished = true);
    await tester.pump();
    await tester.pump();
    expect(people.reads, 2);
    expect(bloc.state.refreshing, isTrue);
    expect(finished, isFalse);
    people.pending!.complete(AppSuccess(_person));
    await tester.pumpAndSettle();
    await completion;
    expect(bloc.state.refreshing, isFalse);
    expect(finished, isTrue);
  });

  testWidgets(
    'revocation clears the open composer and a late save cannot restore notes',
    (tester) async {
      final repository = _PendingNotes();
      final bloc = await _show(tester, repository, _People());
      await tester.tap(find.byTooltip('Agregar nota'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Guardado tardío');
      await tester.tap(find.text('Guardar nota'));
      await tester.pump();
      bloc.add(const NotesAccessLost('ACCESS_DENIED'));
      await tester.pumpAndSettle();
      final late = FollowUpNote(
        id: 99,
        text: 'Guardado tardío',
        recordedAt: _now,
        familiarId: 'caregiver-1',
      );
      repository.save.complete(AppSuccess(late));
      await tester.pumpAndSettle();
      bloc.add(NoteAdded(late));
      await tester.pumpAndSettle();
      expect(bloc.state.notes, isEmpty);
      expect(bloc.state.person, isNull);
      expect(find.text('Rosa Vargas'), findsNothing);
      expect(find.text('Guardado tardío'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  test(
    'profile denial never publishes the previously fetched note text',
    () async {
      final bloc = NotesBloc(
        notes: GetFollowUpNotes(FakeNotes(list: _notes())),
        people: FakePersonReader(const AppFailure('ACCESS_DENIED')),
        olderAdultId: 'adult-1',
      );
      final emitted = <NotesState>[];
      final subscription = bloc.stream.listen(emitted.add);
      bloc.add(const NotesRequested());
      await pumpEventQueue();
      expect(emitted.where((state) => state.notes.isNotEmpty), isEmpty);
      expect(bloc.state.errorCode, 'ACCESS_DENIED');
      await subscription.cancel();
      await bloc.close();
    },
  );
}

Future<NotesBloc> _show(
  WidgetTester tester,
  NotesRepository repository,
  MonitoredPersonReader people, {
  double scale = 1,
}) async {
  tester.view.physicalSize = scale == 1
      ? const Size(393, 883)
      : const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = NotesBloc(
    notes: GetFollowUpNotes(repository),
    people: people,
    olderAdultId: 'adult-1',
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: TataTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const Key('caregiver-notes-capture'),
          child: child!,
        ),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => bloc..add(const NotesRequested())),
          BlocProvider(
            create: (_) => NoteComposerCubit(
              register: RegisterFollowUpNote(repository),
              olderAdultId: 'adult-1',
            ),
          ),
        ],
        child: NotesScreen(clock: () => _now, onTab: (_) {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}
