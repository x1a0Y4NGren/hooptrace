import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/l10n/rule_template_localizations.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/rules/rule_template_editor_page.dart';

class RuleTemplateListPage extends StatefulWidget {
  const RuleTemplateListPage({required this.repository, super.key});

  final RuleTemplateRepository repository;

  @override
  State<RuleTemplateListPage> createState() => _RuleTemplateListPageState();
}

class _RuleTemplateListPageState extends State<RuleTemplateListPage> {
  @override
  void initState() {
    super.initState();
    widget.repository.ensureBuiltIns();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rule-add-custom'),
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.rulesCreate),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RuleTemplate>>(
          stream: widget.repository.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l10n.rulesLoadError));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final templates = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final template = templates[index];
                final builtIn = RuleTemplateRepository.builtIns.any(
                  (item) => item.id == template.id,
                );
                return ListTile(
                  minTileHeight: 64,
                  leading: Icon(builtIn ? Icons.verified_outlined : Icons.tune),
                  title: Text(localizedRuleTemplateName(template, l10n)),
                  subtitle: Text(_summary(template, l10n)),
                  trailing: builtIn
                      ? Text(l10n.rulesBuiltIn)
                      : const Icon(Icons.edit_outlined),
                  onTap: builtIn ? null : () => _openEditor(context, template),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    RuleTemplate? template,
  ]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RuleTemplateEditorPage(
          repository: widget.repository,
          template: template,
        ),
      ),
    );
  }

  static String _summary(RuleTemplate template, AppLocalizations l10n) {
    final values = <String>[
      l10n.rulesScoringButtons(template.scoreButtons.join('/')),
    ];
    if (template.targetScore != null) {
      values.add(l10n.rulesTarget(template.targetScore!));
    }
    if (template.timeLimitSeconds != null) {
      values.add(l10n.rulesMinutes(template.timeLimitSeconds! ~/ 60));
    }
    if (template.winByTwo) values.add(l10n.rulesWinByTwo);
    return values.join(' · ');
  }
}
