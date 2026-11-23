import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/application/usecases/create_personal_note.dart';
import 'package:tata/features/family_monitoring/application/usecases/get_personal_notes.dart';
import 'package:tata/features/family_monitoring/domain/entities/notes.dart';
import 'package:tata/features/family_monitoring/domain/repositories/personal_notes_repository.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/note_values.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/personal_notes/personal_notes_bloc.dart';
import 'package:tata/features/family_monitoring/presentation/screens/personal_notes_screen.dart';
import 'package:tata/features/family_monitoring/presentation/widgets/monitoring_widgets.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/visual_capture.dart';
import 'monitoring_application_test.dart' show FakePersonalNotes;

/// Leaves a refresh outstanding while the initial list and creation use ordinary fixtures.
final class _DelayedNotes implements PersonalNotesRepository {
  _DelayedNotes(this.delegate);
  final FakePersonalNotes delegate;
  Completer<AppResult<List<PersonalNote>>>? nextRead;

  @override
  Future<AppResult<List<PersonalNote>>> list() =>
      nextRead?.future ?? delegate.list();

  @override
  Future<AppResult<PersonalNote>> create(
    String title,
    String text,
    PersonalNoteCategory category,
  ) => delegate.create(title, text, category);
}

void main() {
  setUpAll(loadTataFonts);
  final now = DateTime(2026, 7, 22, 10);
  PersonalNote note(
    int id,
    String title,
    String body,
    DateTime at, {
    PersonalNoteCategory category = PersonalNoteCategory.routine,
  }) => PersonalNote(
    id: id,
    title: title,
    text: body,
    category: category,
    recordedAt: at.toUtc(),
  );
  List<PersonalNote> examples() => [
    note(
      1,
      'Antes de salir',
      'Revisar las próximas tomas si voy a estar fuera de casa.',
      DateTime(2026, 7, 21, 17, 40),
    ),
    note(
      3,
      'Tomar con agua',
      'Losartán 50 mg. Mantener el mismo horario y preparar un vaso de agua antes de la toma.',
      DateTime(2026, 7, 22, 8, 5),
      category: PersonalNoteCategory.medication,
    ),
    note(
      2,
      'Rutina de la noche',
      'Dejar el medicamento junto al vaso de agua.',
      DateTime(2026, 7, 20, 21, 10),
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    PersonalNotesRepository repository, {
    double scale = 1,
    bool pushed = false,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
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
          builder: (context) {
            final content = RepaintBoundary(
              key: const Key('personal-notes-capture'),
              child: BlocProvider(
                create: (_) => PersonalNotesBloc(
                  list: GetPersonalNotes(repository),
                  create: CreatePersonalNote(repository),
                )..add(const PersonalNotesRequested()),
                child: PersonalNotesScreen(clock: () => now),
              ),
            );
            return pushed
                ? Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => content)),
                      child: const Text('Abrir notas'),
                    ),
                  )
                : content;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (pushed) {
      await tester.tap(find.text('Abrir notas'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> write(WidgetTester tester, String title) async {
    await tester.tap(find.byTooltip('Agregar nota'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), title);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nota'),
      'Texto de la nota',
    );
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('personal notes match their calendar groups at scale $scale', (
      tester,
    ) async {
      final repository = FakePersonalNotes()
        ..listResult = AppSuccess(examples());
      await pump(tester, repository, scale: scale);
      expect(find.textContaining('Hoy - 8:05'), findsOneWidget);
      expect(find.textContaining('Ayer - 5:40'), findsOneWidget);
      expect(find.text('Notas recientes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await captureWidget(
        tester,
        find.byKey(const Key('personal-notes-capture')),
        'personal_notes_$scale',
      );
      await tester.ensureVisible(find.text('Consejo'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('system back dismisses only the composer and it can open again', (
    tester,
  ) async {
    await pump(
      tester,
      FakePersonalNotes()..listResult = AppSuccess(examples()),
      pushed: true,
    );
    await tester.tap(find.byTooltip('Agregar nota'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(PersonalNotesScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Agregar nota'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalNotesScreen), findsOneWidget);
  });

  testWidgets(
    'a successful creation resets the filter and acknowledges the actual receipt',
    (tester) async {
      final repository = FakePersonalNotes()
        ..listResult = AppSuccess(examples())
        ..createResult = AppSuccess(
          note(4, 'Nueva rutina', 'Texto de la nota', now),
        );
      await pump(tester, repository);
      await tester.tap(
        find.widgetWithText(MonitoringFilterChip, 'Medicamentos'),
      );
      await tester.pump();
      expect(find.text('Antes de salir'), findsNothing);
      await write(tester, 'Nueva rutina');
      expect(find.text('Nueva rutina'), findsOneWidget);
      expect(find.text('Antes de salir'), findsOneWidget);
      expect(find.text('Nota guardada'), findsOneWidget);
    },
  );

  testWidgets(
    'a known creation receipt remains visible beside an incomplete list warning',
    (tester) async {
      final repository = FakePersonalNotes()
        ..listResult = const AppFailure('NETWORK_UNAVAILABLE')
        ..createResult = AppSuccess(
          note(4, 'Recuerdo', 'Texto de la nota', now),
        );
      await pump(tester, repository);
      await write(tester, 'Recuerdo');
      expect(find.text('Recuerdo'), findsOneWidget);
      expect(find.text('No pudimos cargar tus notas.'), findsOneWidget);
      expect(find.text('Nota guardada'), findsOneWidget);
    },
  );

  testWidgets(
    'pull-to-refresh completes after the protected read, not after dispatch',
    (tester) async {
      final repository = _DelayedNotes(
        FakePersonalNotes()..listResult = const AppSuccess([]),
      );
      await pump(tester, repository);
      repository.nextRead = Completer<AppResult<List<PersonalNote>>>();
      var completed = false;
      final refreshed = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh()
          .then((_) => completed = true);
      await tester.pump();
      expect(completed, isFalse);
      repository.nextRead!.complete(AppSuccess(examples()));
      await refreshed;
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(find.text('Tomar con agua'), findsOneWidget);
    },
  );
}
