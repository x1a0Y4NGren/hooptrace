import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/features/project/external_link_launcher.dart';
import 'package:hooptrace/features/project/project_details_page.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';

class RecordingLauncher extends ExternalLinkLauncher {
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  testWidgets('project details stays usable across visual matrix', (
    tester,
  ) async {
    const locales = [Locale('zh'), Locale('en')];
    const sizes = [Size(390, 844), Size(731, 411)];
    for (final brightness in Brightness.values) {
      for (final locale in locales) {
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: MaterialApp(
                theme: buildHoopTraceTheme(brightness: brightness),
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: ProjectDetailsPage(launcher: RecordingLauncher()),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(DoodleTitle), findsAtLeastNWidgets(1));
          final l10n = AppLocalizations.of(
            tester.element(find.byType(ProjectDetailsPage)),
          )!;
          await tester.scrollUntilVisible(
            find.text(l10n.projectGitHub),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            tester.getSize(find.byType(ListTile).first).height,
            greaterThanOrEqualTo(48),
          );
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('project links have one semantic action owner', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final launcher = RecordingLauncher();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProjectDetailsPage(launcher: launcher),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('GitHub'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final link = find.byKey(const ValueKey('project-link-GitHub'));
    expect(link, findsOneWidget);
    expect(
      tester
          .getSemantics(link)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    semanticsHandle.dispose();
  });

  testWidgets('project details state open-source and local data principles', (
    tester,
  ) async {
    final launcher = RecordingLauncher();
    await tester.pumpWidget(
      _localizedApp(ProjectDetailsPage(launcher: launcher)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DoodleTitle), findsAtLeastNWidgets(1));
    expect(find.byType(DoodleDivider), findsAtLeastNWidgets(1));
    expect(find.byType(DoodleSurface), findsAtLeastNWidgets(2));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ProjectDetailsPage)),
    )!;

    for (final text in [
      l10n.projectFreeForever,
      l10n.projectOpenSource,
      l10n.projectOffline,
      l10n.projectPrivacy,
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    for (final link in [
      l10n.projectGitHub,
      l10n.projectLicense,
      l10n.projectContribute,
      l10n.projectIssue,
    ]) {
      await tester.scrollUntilVisible(
        find.text(link),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(link), findsOneWidget);
    }

    await tester.tap(find.text(l10n.projectGitHub));
    await tester.pump();
    expect(launcher.opened, [hoopTraceRepositoryUrl]);
  });
}

Widget _localizedApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
