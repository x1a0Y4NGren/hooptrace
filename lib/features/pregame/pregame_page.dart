import 'package:flutter/material.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

class PregamePage extends StatefulWidget {
  const PregamePage({
    this.onStartMatch,
    super.key,
  });

  final ValueChanged<MatchSetup>? onStartMatch;

  @override
  State<PregamePage> createState() => _PregamePageState();
}

class _PregamePageState extends State<PregamePage> {
  late final PregameController _controller;
  late final TextEditingController _redNameController;
  late final TextEditingController _blueNameController;

  @override
  void initState() {
    super.initState();
    _controller = PregameController();
    _redNameController = TextEditingController(text: _controller.state.redName);
    _blueNameController =
        TextEditingController(text: _controller.state.blueName);
  }

  @override
  void dispose() {
    _redNameController.dispose();
    _blueNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('赛前设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              '球员',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('pregame-red-name'),
              controller: _redNameController,
              decoration: const InputDecoration(
                labelText: '红方',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: _controller.setRedName,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('pregame-blue-name'),
              controller: _blueNameController,
              decoration: const InputDecoration(
                labelText: '蓝方',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onChanged: _controller.setBlueName,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _controller.state.ruleTemplateId,
              decoration: const InputDecoration(
                labelText: '规则模板',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'free', child: Text('自由计分')),
                DropdownMenuItem(value: 'eleven', child: Text('11 分制')),
                DropdownMenuItem(value: 'twenty_one', child: Text('21 分制')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _controller.setRuleTemplateId(value));
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _controller.state.timerEnabled,
              title: const Text('计时'),
              onChanged: (value) {
                setState(() => _controller.setTimerEnabled(value));
              },
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('高级设置'),
              initiallyExpanded: _controller.state.advancedExpanded,
              onExpansionChanged: _controller.setAdvancedExpanded,
              children: [
                _NumberSetting(
                  label: '目标分',
                  value: _controller.state.targetScore,
                  onChanged: (value) {
                    setState(() => _controller.setTargetScore(value));
                  },
                ),
                _NumberSetting(
                  label: '时间限制',
                  suffix: '分钟',
                  value: _controller.state.timeLimitMinutes,
                  onChanged: (value) {
                    setState(() => _controller.setTimeLimitMinutes(value));
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () {
                  _controller
                    ..setRedName(_redNameController.text)
                    ..setBlueName(_blueNameController.text);
                  widget.onStartMatch?.call(_controller.createMatchSetup());
                },
                child: const Text('开始比赛'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix = '分',
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: SegmentedButton<int>(
        segments: [
          ButtonSegment(value: value - 1, label: const Icon(Icons.remove)),
          ButtonSegment(value: value, label: Text('$value$suffix')),
          ButtonSegment(value: value + 1, label: const Icon(Icons.add)),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
