import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'action rail uses quiet paper surfaces in ${brightness.name} mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildHoopTraceTheme(brightness: brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 124,
                  height: 291,
                  child: ScoreSidePanel(
                    side: TeamSide.blue,
                    name: 'BLUE TEAM',
                    score: 23,
                    fouls: 4,
                    onScore: (_) {},
                    onFoul: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        final palette = brightness == Brightness.light
            ? const HoopTraceEditorialTheme.light()
            : const HoopTraceEditorialTheme.dark();
        final expectedRail = brightness == Brightness.dark
            ? palette.surface
            : palette.canvas;
        final expectedButton = brightness == Brightness.dark
            ? Color.alphaBlend(
                palette.ink.withValues(alpha: 0.045),
                palette.surface,
              )
            : palette.surface;
        final rail = tester.widget<Material>(
          find.byKey(const Key('blue-action-rail')),
        );
        expect(rail.color, expectedRail);
        expect(rail.color, isNot(HoopTraceColors.ink));
        final divider = rail.shape! as Border;
        expect(divider.right.color, palette.rule);
        expect(divider.right.width, 1);

        final scoreButton = tester.widget<FilledButton>(
          find.byKey(const Key('blue-score-1')),
        );
        final background = scoreButton.style!.backgroundColor!.resolve({});
        final foreground = scoreButton.style!.foregroundColor!.resolve({});
        final border = scoreButton.style!.side!.resolve({})!;
        expect(background, expectedButton);
        expect(foreground, palette.teamBlue);
        expect(border.color, palette.rule);
        expect(border.width, 1);
        expect(scoreButton.style!.elevation!.resolve({}), 0);
        expect(
          scoreButton.style!.shape!.resolve({}),
          isA<BeveledRectangleBorder>(),
        );
        expect(_contrast(foreground!, background!), greaterThanOrEqualTo(4.5));

        final foulButton = tester.widget<OutlinedButton>(
          find.byKey(const Key('blue-foul')),
        );
        final foulBackground = foulButton.style!.backgroundColor!.resolve({})!;
        final foulForeground = foulButton.style!.foregroundColor!.resolve({})!;
        final foulBorder = foulButton.style!.side!.resolve({})!;
        expect(foulBorder.color, palette.arenaAccent);
        expect(
          _contrast(foulForeground, foulBackground),
          greaterThanOrEqualTo(4.5),
        );

        final identityLines = tester.widgetList<Container>(
          find.byKey(const Key('blue-action-identity-line')),
        );
        expect(identityLines, hasLength(4));
        for (final line in identityLines) {
          expect(line.color, isIn([palette.teamBlue, palette.arenaAccent]));
          expect(line.constraints?.maxWidth, 3);
        }

        // The scoreboard already owns team identity. The rail header only
        // repeats the foul count so the narrow column stays visually quiet.
        expect(find.text('BLUE TEAM'), findsNothing);
        expect(find.text('犯规 4'), findsOneWidget);
        expect(find.text('23'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('four primary actions stay evenly spaced and at least 48dp', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 124,
              height: 291,
              child: ScoreSidePanel(
                side: TeamSide.red,
                name: 'RED TEAM',
                score: 9,
                fouls: 2,
                onScore: (_) {},
                onFoul: () {},
              ),
            ),
          ),
        ),
      ),
    );

    const keys = [
      Key('red-score-1'),
      Key('red-score-2'),
      Key('red-score-3'),
      Key('red-foul'),
    ];
    final rects = [for (final key in keys) tester.getRect(find.byKey(key))];
    for (final rect in rects) {
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    final centerGaps = [
      for (var index = 1; index < rects.length; index++)
        rects[index].center.dy - rects[index - 1].center.dy,
    ];
    expect(centerGaps[1], closeTo(centerGaps[0], 0.01));
    expect(centerGaps[2], closeTo(centerGaps[0], 0.01));
    expect(tester.takeException(), isNull);
  });
}

double _contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}
