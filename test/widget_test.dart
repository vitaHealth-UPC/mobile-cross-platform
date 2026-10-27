import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/tata_app.dart';

void main() {
  testWidgets('Application starts without a counter or an invented session', (
    tester,
  ) async {
    await tester.pumpWidget(const TataApp());

    expect(find.text('Tata'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
