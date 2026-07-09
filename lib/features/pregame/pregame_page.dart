import 'package:flutter/material.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

const pregameTitleText = '赛前设置';
const pregamePlayersText = '球员';
const pregameRuleTemplateText = '规则模板';
const pregameFreeScoringText = '自由计分';
const pregameElevenPointText = '11 分制';
const pregameTwentyOnePointText = '21 分制';
const pregameTimerText = '计时';
const pregameWinByTwoText = '领先 2 分获胜';
const pregameAdvancedText = '高级设置';
const pregameTargetScoreText = '目标分';
const pregameTimeLimitText = '时间限制';
const pregameMinuteText = '分钟';
const pregamePointText = '分';
const pregameStartMatchText = '开始比赛';

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
      appBar: AppBar(title: const Text(pregameTitleText)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              pregamePlayersText,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('pregame-red-name'),
              controller: _redNameController,
              decoration: const InputDecoration(
                labelText: defaultRedPlayerName,
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
                labelText: defaultBluePlayerName,
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onChanged: _controller.setBlueName,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _controller.state.ruleTemplateId,
              decoration: const InputDecoration(
                labelText: pregameRuleTemplateText,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'free',
                  child: Text(pregameFreeScoringText),
                ),
                DropdownMenuItem(
                  value: 'eleven',
                  child: Text(pregameElevenPointText),
                ),
                DropdownMenuItem(
                  value: 'twenty_one',
                  child: Text(pregameTwentyOnePointText),
                ),
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
              title: const Text(pregameTimerText),
              onChanged: (value) {
                setState(() => _controller.setTimerEnabled(value));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _controller.state.winByTwo,
              title: const Text(pregameWinByTwoText),
              onChanged: (value) {
                setState(() => _controller.setWinByTwo(value));
              },
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(pregameAdvancedText),
              initiallyExpanded: _controller.state.advancedExpanded,
              onExpansionChanged: _controller.setAdvancedExpanded,
              children: [
                _NumberSetting(
                  label: pregameTargetScoreText,
                  value: _controller.state.targetScore,
                  onChanged: (value) {
                    setState(() => _controller.setTargetScore(value));
                  },
                ),
                _NumberSetting(
                  label: pregameTimeLimitText,
                  suffix: pregameMinuteText,
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
                child: const Text(pregameStartMatchText),
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
    this.suffix = pregamePointText,
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
