import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light and dark themes expose visual and motion extensions', () {
    final light = buildHoopTraceTheme();
    final dark = buildHoopTraceTheme(brightness: Brightness.dark);

    final lightVisual = light.extension<HoopTraceVisualTheme>();
    final darkVisual = dark.extension<HoopTraceVisualTheme>();
    final lightMotion = light.extension<HoopTraceMotionTheme>();
    final darkMotion = dark.extension<HoopTraceMotionTheme>();

    expect(lightVisual, isNotNull);
    expect(darkVisual, isNotNull);
    expect(lightMotion, isNotNull);
    expect(darkMotion, isNotNull);
    expect(lightVisual!.paper, HoopTraceColors.offWhite);
    expect(darkVisual!.paper, HoopTraceColors.charcoal);
    expect(lightMotion!.scoreFlight, const Duration(milliseconds: 520));
    expect(lightMotion.impact, const Duration(milliseconds: 240));
    expect(darkMotion!.scoreFlight, lightMotion.scoreFlight);
  });

  testWidgets('doodle surface, title and divider preserve semantic content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: const Scaffold(
          body: DoodleSurface(
            child: Column(
              children: [
                DoodleTitle('Court notes'),
                DoodleDivider(),
                Text('Body copy'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Court notes'), findsOneWidget);
    expect(find.text('Body copy'), findsOneWidget);
    expect(find.byType(DoodleDivider), findsOneWidget);
    expect(tester.getSize(find.byType(DoodleDivider)).height, greaterThan(1));
  });

  testWidgets('doodle press has a 48dp hit target and pressed visual state', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: Scaffold(
          body: DoodlePress(
            label: 'Add point',
            onPressed: () => presses++,
            child: const Text('Add point'),
          ),
        ),
      ),
    );

    final button = find.byType(DoodlePress);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    final before = tester.widget<AnimatedScale>(
      find.descendant(of: button, matching: find.byType(AnimatedScale)),
    );
    expect(before.scale, 1);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    final during = tester.widget<AnimatedScale>(
      find.descendant(of: button, matching: find.byType(AnimatedScale)),
    );
    expect(during.scale, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  test(
    'bundled paint animations parse as Lottie compositions with named fills',
    () async {
      for (final asset in [
        'assets/animations/paint_ball.json',
        'assets/animations/paint_splash.json',
      ]) {
        final bytes = await rootBundle.load(asset);
        final json =
            jsonDecode(utf8.decode(bytes.buffer.asUint8List()))
                as Map<String, dynamic>;
        final layers = (json['layers'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final names = layers.map((layer) => layer['nm']).whereType<String>();
        expect(names, contains('teamFill'));
        expect(names, contains('inkFill'));
        final composition = await LottieComposition.fromByteData(bytes);
        expect(composition, isNotNull);
        expect(composition!.duration, greaterThan(Duration.zero));
      }
    },
  );
}
