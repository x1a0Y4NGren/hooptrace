import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_en.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/l10n/rule_template_localizations.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';

void main() {
  test('task 6 semantic copy is exact and ARB keys remain in parity', () {
    final en = AppLocalizationsEn();
    final zh = AppLocalizationsZh();
    expect(en.scoringNotesCustomRecordsGroup, 'Notes/Custom Records');
    expect(zh.scoringNotesCustomRecordsGroup, '备注/自定义记录');
    expect(en.settingsAboutSection, 'About');
    expect(zh.settingsAboutSection, '关于');
    expect(en.settingsDataSection, 'Data');
    expect(zh.settingsDataSection, '数据');

    final enKeys = _arbKeys('lib/app/l10n/app_en.arb');
    final zhKeys = _arbKeys('lib/app/l10n/app_zh.arb');
    expect(enKeys, zhKeys);
  });

  test(
    'unsupported locales and unknown custom rules preserve their contracts',
    () {
      expect(
        () => lookupAppLocalizations(const Locale('fr')),
        throwsA(isA<FlutterError>()),
      );
      final l10n = AppLocalizationsEn();
      const custom = RuleTemplate(
        id: 'user-rule',
        name: 'First to seven',
        scoreButtons: [1, 2],
      );
      expect(localizedRuleTemplateName(custom, l10n), custom.name);
      expect(
        localizedStoredRuleTemplateName('Neighborhood rules', l10n),
        'Neighborhood rules',
      );
    },
  );
}

Set<String> _arbKeys(String path) {
  final values =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return values.keys.where((key) => !key.startsWith('@')).toSet();
}
