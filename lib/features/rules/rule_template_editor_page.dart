import 'package:flutter/material.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';

class RuleTemplateEditorPage extends StatefulWidget {
  const RuleTemplateEditorPage({
    required this.repository,
    this.template,
    super.key,
  });

  final RuleTemplateRepository repository;
  final RuleTemplate? template;

  @override
  State<RuleTemplateEditorPage> createState() => _RuleTemplateEditorPageState();
}

class _RuleTemplateEditorPageState extends State<RuleTemplateEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _timeLimit;
  late final TextEditingController _foulLimit;
  late final TextEditingController _scoreButtons;
  late final TextEditingController _eventTypes;
  late bool _winByTwo;
  late bool _possessionHint;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _name = TextEditingController(text: template?.name ?? '');
    _target = TextEditingController(
      text: template?.targetScore?.toString() ?? '',
    );
    _timeLimit = TextEditingController(
      text: template?.timeLimitSeconds == null
          ? ''
          : '${template!.timeLimitSeconds! ~/ 60}',
    );
    _foulLimit = TextEditingController(
      text: template?.foulLimit?.toString() ?? '',
    );
    _scoreButtons = TextEditingController(
      text: template?.scoreButtons.join(',') ?? '1,2,3',
    );
    _eventTypes = TextEditingController(
      text: template?.customEventTypes.join(',') ?? '',
    );
    _winByTwo = template?.winByTwo ?? false;
    _possessionHint = template?.possessionHintEnabled ?? false;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _target,
      _timeLimit,
      _foulLimit,
      _scoreButtons,
      _eventTypes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template == null ? '新建规则' : '编辑规则')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _field(
                key: const Key('rule-name'),
                controller: _name,
                label: '模板名称',
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请输入名称' : null,
              ),
              _field(
                key: const Key('rule-target-score'),
                controller: _target,
                label: '目标分（可选）',
                numeric: true,
              ),
              _field(
                key: const Key('rule-time-limit'),
                controller: _timeLimit,
                label: '时限分钟（可选）',
                numeric: true,
              ),
              _field(
                key: const Key('rule-foul-limit'),
                controller: _foulLimit,
                label: '犯规上限（可选）',
                numeric: true,
              ),
              _field(
                key: const Key('rule-score-buttons'),
                controller: _scoreButtons,
                label: '计分按钮（逗号分隔）',
                validator: _validateScoreButtons,
              ),
              _field(
                key: const Key('rule-event-types'),
                controller: _eventTypes,
                label: '自定义事件类型（逗号分隔）',
              ),
              SwitchListTile(
                key: const Key('rule-win-by-two'),
                contentPadding: EdgeInsets.zero,
                value: _winByTwo,
                title: const Text('领先 2 分获胜'),
                onChanged: (value) => setState(() => _winByTwo = value),
              ),
              SwitchListTile(
                key: const Key('rule-possession-hint'),
                contentPadding: EdgeInsets.zero,
                value: _possessionHint,
                title: const Text('得分后提示球权'),
                subtitle: const Text('仅提示，不阻断手动计分'),
                onChanged: (value) => setState(() => _possessionHint = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('rule-save'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存规则'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    bool numeric = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (numeric
                ? (value) => _validateOptionalPositive(value, label)
                : null),
      ),
    );
  }

  String? _validateOptionalPositive(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    return parsed == null || parsed <= 0 ? '$label 必须为正整数' : null;
  }

  String? _validateScoreButtons(String? value) {
    final values = _parseNumbers(value ?? '');
    return values.isEmpty || values.any((item) => item <= 0)
        ? '至少填写一个正整数'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = widget.template;
    await widget.repository.save(
      RuleTemplate(
        id: current?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        scoreButtons: _parseNumbers(_scoreButtons.text).toSet().toList()
          ..sort(),
        targetScore: _optionalInt(_target.text),
        timeLimitSeconds: _optionalInt(_timeLimit.text) == null
            ? null
            : _optionalInt(_timeLimit.text)! * 60,
        winByTwo: _winByTwo,
        foulLimit: _optionalInt(_foulLimit.text),
        possessionHintEnabled: _possessionHint,
        customEventTypes: _parseTextList(_eventTypes.text),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  static int? _optionalInt(String value) {
    final text = value.trim();
    return text.isEmpty ? null : int.parse(text);
  }

  static List<int> _parseNumbers(String value) => value
      .split(RegExp(r'[,，\s]+'))
      .where((item) => item.isNotEmpty)
      .map(int.tryParse)
      .whereType<int>()
      .toList();

  static List<String> _parseTextList(String value) => value
      .split(RegExp(r'[,，\n]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}
