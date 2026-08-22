import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/features/rules/rule_template_list_page.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('lists built-ins and persists a custom template from editor', (
    tester,
  ) async {
    final database = createTestDatabase();
    final repository = RuleTemplateRepository(database);
    await repository.ensureBuiltIns();

    await tester.pumpWidget(
      MaterialApp(home: RuleTemplateListPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('自由计分'), findsOneWidget);
    expect(find.text('11 分制（领先 2 分）'), findsOneWidget);
    expect(find.text('21 分制'), findsOneWidget);
    expect(find.text('10 分钟计时'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rule-add-custom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rule-name')), '训练规则');
    await tester.enterText(find.byKey(const Key('rule-target-score')), '15');
    await tester.enterText(find.byKey(const Key('rule-time-limit')), '7');
    await tester.enterText(find.byKey(const Key('rule-foul-limit')), '4');
    await tester.enterText(
      find.byKey(const Key('rule-score-buttons')),
      '1,3,5',
    );
    await tester.enterText(find.byKey(const Key('rule-event-types')), '抢断,盖帽');
    await tester.tap(find.byKey(const Key('rule-win-by-two')));
    await tester.tap(find.byKey(const Key('rule-possession-hint')));
    await tester.fling(
      find.byType(ListView),
      const Offset(0, -800),
      1000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rule-save')));
    await tester.pumpAndSettle();

    final custom = (await repository.listAll())
        .singleWhere((template) => template.name == '训练规则');
    expect(custom.targetScore, 15);
    expect(custom.timeLimitSeconds, 420);
    expect(custom.foulLimit, 4);
    expect(custom.scoreButtons, [1, 3, 5]);
    expect(custom.winByTwo, isTrue);
    expect(custom.possessionHintEnabled, isTrue);
    expect(custom.customEventTypes, ['抢断', '盖帽']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
