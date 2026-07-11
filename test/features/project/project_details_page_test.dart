import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      MaterialApp(home: ProjectDetailsPage(launcher: launcher)),
    );

    for (final text in ['永久免费', '永久开源', '本地离线', '不会上传个人数据']) {
      expect(find.text(text), findsOneWidget);
    }
    for (final link in ['GitHub', 'License', '贡献指南', '问题反馈']) {
      await tester.scrollUntilVisible(find.text(link), 200);
      expect(find.text(link), findsOneWidget);
    }

    await tester.tap(find.text('GitHub'));
    await tester.pump();
    expect(launcher.opened, [hoopTraceRepositoryUrl]);
  });
}
