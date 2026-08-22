import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('规则模板')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rule-add-custom'),
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新建规则'),
      ),
      body: StreamBuilder<List<RuleTemplate>>(
        stream: widget.repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('规则模板读取失败'));
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
              final builtIn = RuleTemplateRepository.builtIns
                  .any((item) => item.id == template.id);
              return ListTile(
                minTileHeight: 64,
                leading: Icon(builtIn ? Icons.verified_outlined : Icons.tune),
                title: Text(template.name),
                subtitle: Text(_summary(template)),
                trailing: builtIn
                    ? const Text('内置')
                    : const Icon(Icons.edit_outlined),
                onTap: builtIn ? null : () => _openEditor(context, template),
              );
            },
          );
        },
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

  static String _summary(RuleTemplate template) {
    final values = <String>['计分 ${template.scoreButtons.join('/')}'];
    if (template.targetScore != null) {
      values.add('目标 ${template.targetScore} 分');
    }
    if (template.timeLimitSeconds != null) {
      values.add('${template.timeLimitSeconds! ~/ 60} 分钟');
    }
    if (template.winByTwo) values.add('领先 2 分');
    return values.join(' · ');
  }
}
