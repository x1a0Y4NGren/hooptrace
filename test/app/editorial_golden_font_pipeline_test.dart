import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/design_system/editorial_masthead.dart';

import '../support/golden_fonts.dart';

void main() {
  setUpAll(loadHoopTraceGoldenFonts);

  testWidgets('production theme preserves body and display font roles', (
    tester,
  ) async {
    const bodyKey = Key('body-copy');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(
                'English body 中文正文',
                key: bodyKey,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const EditorialMasthead(title: 'English display 中文标题'),
            ],
          ),
        ),
      ),
    );

    final bodyStyle = tester.widget<Text>(find.byKey(bodyKey)).style!;
    final displayStyle = tester
        .widget<Text>(find.text('English display 中文标题'))
        .style!;
    expect(bodyStyle.fontFamily, isNot('Noto Sans SC'));
    expect(bodyStyle.fontFamilyFallback, contains('Noto Sans SC'));
    expect(displayStyle.fontFamily, HoopTraceTypography.displayFamily);
    expect(displayStyle.fontFamilyFallback, contains('Noto Sans SC'));
  });

  testWidgets('golden font pipeline renders real Material Icons glyphs', (
    tester,
  ) async {
    const materialIcon = Key('material-icon');
    const missingGlyph = Key('missing-material-glyph');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: Row(
          textDirection: TextDirection.ltr,
          children: const [
            RepaintBoundary(
              key: materialIcon,
              child: SizedBox.square(
                dimension: 48,
                child: Icon(Icons.tune, size: 32),
              ),
            ),
            RepaintBoundary(
              key: missingGlyph,
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  IconData(0x10ffff, fontFamily: 'MaterialIcons'),
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await _capturePixels(tester, find.byKey(materialIcon)),
      isNot(equals(await _capturePixels(tester, find.byKey(missingGlyph)))),
      reason: 'Icons.tune must not render as the missing-glyph tofu box.',
    );
  });

  testWidgets('golden font pipeline renders real English body glyphs', (
    tester,
  ) async {
    const bodyGlyph = Key('body-glyph');
    const missingGlyph = Key('missing-body-glyph');
    final bodyStyle = buildHoopTraceTheme().textTheme.bodyMedium!.copyWith(
      fontSize: 32,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: Row(
          textDirection: TextDirection.ltr,
          children: [
            RepaintBoundary(
              key: bodyGlyph,
              child: SizedBox.square(
                dimension: 48,
                child: Text('A', style: bodyStyle),
              ),
            ),
            RepaintBoundary(
              key: missingGlyph,
              child: SizedBox.square(
                dimension: 48,
                child: Text(String.fromCharCode(0x10ffff), style: bodyStyle),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await _capturePixels(tester, find.byKey(bodyGlyph)),
      isNot(equals(await _capturePixels(tester, find.byKey(missingGlyph)))),
      reason: 'English body copy must not render as the Ahem tofu box.',
    );
  });
}

Future<Uint8List> _capturePixels(WidgetTester tester, Finder finder) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return null;
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  });
  if (pixels == null) fail('Could not capture pixels for $finder.');
  return pixels;
}
