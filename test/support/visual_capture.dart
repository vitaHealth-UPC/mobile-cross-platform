import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the licensed production fonts for widget captures instead of test glyphs.
Future<void> loadTataFonts() async {
  final inter = FontLoader('Inter');
  for (final weight in ['regular', 'medium', 'semibold', 'bold']) {
    inter.addFont(rootBundle.load('assets/fonts/inter_$weight.ttf'));
  }
  await inter.load();
  final serif = FontLoader('DMSerifDisplay')
    ..addFont(rootBundle.load('assets/fonts/dm_serif_display.ttf'));
  await serif.load();
  final script = FontLoader('DancingScript')
    ..addFont(rootBundle.load('assets/fonts/dancing_script_bold.ttf'));
  await script.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Saves an explicitly requested local render without changing ordinary CI runs.
/// [boundary] must identify a painted RepaintBoundary, not a screenshot asset.
Future<void> captureWidget(
  WidgetTester tester,
  Finder boundary,
  String name,
) async {
  final directory = Platform.environment['TATA_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final render = tester.renderObject<RenderRepaintBoundary>(boundary);
    final image = await render.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File('$directory/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
