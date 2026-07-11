import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

void main() {
  testWidgets('settings exposes all planned groups without fake exports',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage()),
    );

    for (final section in [
      '默认值',
      '外观',
      '统计',
      '备份与导出',
      '隐私',
      '实验功能',
      '开发诊断',
      '项目详情',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 200);
      expect(find.text(section), findsOneWidget);
    }
    expect(find.text('后续提供'), findsWidgets);
    final exportTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, '导出比赛数据'),
    );
    expect(exportTile.enabled, isFalse);
  });
}
