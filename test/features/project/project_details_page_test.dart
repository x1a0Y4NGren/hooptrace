import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/features/project/external_link_launcher.dart';
import 'package:hooptrace/features/project/project_details_page.dart';

class RecordingLauncher extends ExternalLinkLauncher {
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  testWidgets('project details state open-source and local data principles', (
    tester,
  ) async {
    final launcher = RecordingLauncher();
    await tester.pumpWidget(
      _localizedApp(ProjectDetailsPage(launcher: launcher)),
    );
    await tester.pumpAndSettle();
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
