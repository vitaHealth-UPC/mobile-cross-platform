import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/care_link/presentation/screens/invitation_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';
import 'package:tata/shared/presentation/widgets/status_notice.dart';

void main() {
  Future<void> pump(WidgetTester tester, {String? title, String? body}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: TataTheme.light,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InvitationScreen(
            loading: false,
            onSubmit: (_) {},
            errorTitle: title,
            errorText: body,
          ),
        ),
      );

  testWidgets('a used invitation is named as a failed link (Figma 563:2254)', (
    tester,
  ) async {
    await pump(
      tester,
      title: 'No se pudo vincular',
      body: 'Esta invitación venció o ya fue utilizada. Solicita una nueva.',
    );
    expect(find.byType(StatusNotice), findsOneWidget);
    expect(find.text('No se pudo vincular'), findsOneWidget);
    expect(
      find.text(
        'Esta invitación venció o ya fue utilizada. Solicita una nueva.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('other failures keep their message without a title', (
    tester,
  ) async {
    await pump(tester, body: 'Sin conexión.');
    expect(find.byType(StatusNotice), findsOneWidget);
    expect(find.text('No se pudo vincular'), findsNothing);
    expect(find.text('Sin conexión.'), findsOneWidget);
  });

  testWidgets('no failure, no notice', (tester) async {
    await pump(tester);
    expect(find.byType(StatusNotice), findsNothing);
  });
}
