import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';

void main() {
  testWidgets('pre-game page exposes fast start and advanced settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    expect(find.text('赛前设置'), findsOneWidget);
    expect(find.text('球员'), findsOneWidget);
    expect(find.text('红方'), findsWidgets);
    expect(find.text('蓝方'), findsWidgets);
    expect(find.text('规则模板'), findsOneWidget);
    expect(find.text('自由计分'), findsOneWidget);
    expect(find.text('高级设置'), findsOneWidget);
    expect(find.text('计时'), findsOneWidget);
    expect(find.text('开始比赛'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('高级设置'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();

    expect(find.text('目标分'), findsOneWidget);
    expect(find.text('时间限制'), findsNothing);
    expect(find.text('11分'), findsOneWidget);
    expect(find.text('10分钟'), findsNothing);
  });

  testWidgets('pre-game page accepts player names and starts match', (
    tester,
  ) async {
    String? startedRedName;
    String? startedBlueName;

    await tester.pumpWidget(
      MaterialApp(
        home: PregamePage(
          onStartMatch: (setup) {
            startedRedName = setup.redName;
            startedBlueName = setup.blueName;
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), 'Red A');
    await tester.enterText(
      find.byKey(const Key('pregame-blue-name')),
      'Blue B',
    );
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));

    expect(startedRedName, 'Red A');
    expect(startedBlueName, 'Blue B');
  });

  testWidgets('pre-game page hides recording mode and coverage choices', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    expect(find.byKey(const Key('pregame-recording-simple')), findsNothing);
    expect(find.byKey(const Key('pregame-recording-detailed')), findsNothing);
    expect(find.byKey(const Key('pregame-tracking-coverage')), findsNothing);
    expect(find.text('记录模式（必选）'), findsNothing);
    expect(find.text('失误追踪范围'), findsNothing);
  });

  testWidgets('pre-game page exposes Chinese rule template options', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    await tester.tap(find.text('自由计分'));
    await tester.pumpAndSettle();

    expect(find.text('11 分制'), findsOneWidget);
    expect(find.text('21 分制'), findsOneWidget);
  });

  testWidgets('clearing a participant name blocks start with readable error', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (_) => started = true)),
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), '');
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));
    await tester.pump();

    expect(started, isFalse);
    expect(find.text('请输入红方姓名。'), findsOneWidget);
  });

  testWidgets('invalid countdown text never reuses an old value or starts', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (_) => started = true)),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-timer')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-timer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pregame-clock-countdown')));
    await tester.pump();

    final field = find.byKey(const Key('pregame-countdown-minutes'));
    for (final value in ['', '0', '181', 'abc']) {
      await tester.enterText(field, value);
      await tester.pump();
      expect(
        tester.widget<TextField>(field).controller!.text,
        value == 'abc' ? isEmpty : value,
      );
    }
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));
    await tester.pump();

    expect(started, isFalse);
    expect(find.text('请输入 1 到 180 之间的整数分钟。'), findsOneWidget);
  });

  testWidgets('clock selection buttons expose selected semantics', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));
    await tester.tap(find.byKey(const Key('pregame-timer')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-clock-countdown')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final semantics = tester.getSemantics(
      find.byKey(const Key('pregame-clock-countdown')),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isSelected, ui.Tristate.isFalse);

    await tester.tap(find.byKey(const Key('pregame-clock-countdown')));
    await tester.pump();
    final selectedSemantics = tester.getSemantics(
      find.byKey(const Key('pregame-clock-countdown')),
    );
    expect(selectedSemantics.flagsCollection.isButton, isTrue);
    expect(selectedSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);
  });

  testWidgets('wide pre-game layout keeps symmetric doodle participant cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(731, 411);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    expect(find.byKey(const Key('pregame-red-card')), findsOneWidget);
    expect(find.byKey(const Key('pregame-blue-card')), findsOneWidget);
    expect(find.byType(DoodleSurface), findsAtLeastNWidgets(5));
    expect(
      tester.getTopLeft(find.byKey(const Key('pregame-red-card'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('pregame-blue-card'))).dx,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('pregame-red-card'))).width,
      closeTo(
        tester.getSize(find.byKey(const Key('pregame-blue-card'))).width,
        1,
      ),
    );
  });

  testWidgets(
    'narrow pre-game layout stacks participant cards and keeps start reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: PregamePage()));

      final red = tester.getTopLeft(find.byKey(const Key('pregame-red-card')));
      final blue = tester.getTopLeft(
        find.byKey(const Key('pregame-blue-card')),
      );
      expect(blue.dy, greaterThan(red.dy));

      await tester.scrollUntilVisible(
        find.byKey(const Key('pregame-start-match')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('pregame-start-match')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('pregame-start-match'))).height,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets(
    'pre-game groups rule, clock, and advanced controls into playbook sections',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PregamePage()));

      expect(find.byKey(const Key('pregame-rules-section')), findsOneWidget);
      expect(find.byKey(const Key('pregame-clock-section')), findsOneWidget);
      expect(find.byKey(const Key('pregame-advanced-section')), findsOneWidget);
      expect(find.byKey(const Key('pregame-rule-template')), findsOneWidget);
      expect(find.byKey(const Key('pregame-timer')), findsOneWidget);
      expect(find.byKey(const Key('pregame-win-by-two')), findsOneWidget);
    },
  );

  testWidgets(
    'wide and narrow viewports render without exceptions and keep fields reachable',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(731, 411), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(theme: buildHoopTraceTheme(), home: const PregamePage()),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('pregame-red-name')));
        await tester.ensureVisible(find.byKey(const Key('pregame-blue-name')));
        await tester.scrollUntilVisible(
          find.byKey(const Key('pregame-start-match')),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(const Key('pregame-start-match')), findsOneWidget);
        expect(
          tester.getRect(find.byKey(const Key('pregame-start-match'))).bottom,
          lessThanOrEqualTo(size.height),
        );
      }
    },
  );

  testWidgets('narrow pre-game layout remains usable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const PregamePage(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-start-match')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getSize(find.byKey(const Key('pregame-start-match'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.ensureVisible(find.byKey(const Key('pregame-red-name')));
    await tester.ensureVisible(find.byKey(const Key('pregame-blue-name')));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'light and dark pre-game renders retain team cards and grouped sections',
    (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildHoopTraceTheme(brightness: brightness),
            home: const PregamePage(),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('pregame-red-card')), findsOneWidget);
        expect(find.byKey(const Key('pregame-blue-card')), findsOneWidget);
        expect(find.byKey(const Key('pregame-rules-section')), findsOneWidget);
        expect(find.byKey(const Key('pregame-clock-section')), findsOneWidget);
        expect(
          find.byKey(const Key('pregame-advanced-section')),
          findsOneWidget,
        );
      }
    },
  );

  test('playbook themes keep the primary action contrast above WCAG AA', () {
    double contrast(Color foreground, Color background) {
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
          ? foreground.computeLuminance()
          : background.computeLuminance();
      final darker =
          foreground.computeLuminance() > background.computeLuminance()
          ? background.computeLuminance()
          : foreground.computeLuminance();
      return (lighter + 0.05) / (darker + 0.05);
    }

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final scheme = buildHoopTraceTheme(brightness: brightness).colorScheme;
      expect(
        contrast(scheme.primary, scheme.onPrimary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets(
    'localized default names are applied before the first meaningful paint',
    (tester) async {
      Future<void> pumpLocale(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PregamePage(),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await pumpLocale(const Locale('zh'));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('pregame-red-name')))
            .controller!
            .text,
        '红方',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('pregame-blue-name')))
            .controller!
            .text,
        '蓝方',
      );

      await pumpLocale(const Locale('en'));
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('pregame-red-name')))
            .controller!
            .text,
        'Red',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('pregame-blue-name')))
            .controller!
            .text,
        'Blue',
      );
    },
  );

  testWidgets(
    'team groups and start expose accessible semantics and 48dp targets',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildHoopTraceTheme(), home: const PregamePage()),
      );
      await tester.pump();

      for (final key in [
        const Key('pregame-red-card'),
        const Key('pregame-blue-card'),
        const Key('pregame-rules-section'),
        const Key('pregame-clock-section'),
        const Key('pregame-advanced-section'),
      ]) {
        expect(tester.getSemantics(find.byKey(key)).label, isNotEmpty);
      }
      final startSemantics = tester.getSemantics(
        find.byKey(const Key('pregame-start-match')),
      );
      expect(startSemantics.flagsCollection.isButton, isTrue);
      expect(startSemantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(
        tester.getSize(find.byKey(const Key('pregame-start-match'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('pregame-red-profile'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('pregame-blue-profile'))).height,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets(
    'keyboard insets keep the pinned start action above the keyboard and validation reachable',
    (tester) async {
      const size = Size(390, 844);
      const keyboardHeight = 320.0;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              viewInsets: EdgeInsets.only(bottom: keyboardHeight),
            ),
            child: const PregamePage(),
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('pregame-red-name')));
      await tester.enterText(find.byKey(const Key('pregame-red-name')), '');
      await tester.tap(find.byKey(const Key('pregame-start-match')));
      await tester.pump();

      expect(find.byKey(const Key('pregame-validation')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('pregame-start-match'))).bottom,
        lessThanOrEqualTo(size.height - keyboardHeight),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('pregame-validation')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('请输入红方姓名。'), findsOneWidget);
    },
  );
}
