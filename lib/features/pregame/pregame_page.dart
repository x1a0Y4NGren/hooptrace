import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
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
const pregamePointText = '分';
const pregameStartMatchText = '开始比赛';
const pregameRecordingModeText = '记录模式（必选）';
const pregameTrackingCoverageText = '失误追踪范围';
const pregameClockModeText = '计时方式';
const pregameTemporaryParticipantText = '临时姓名（未关联档案）';

const _temporaryProfileId = '__temporary_profile__';

class PregamePage extends StatefulWidget {
  const PregamePage({
    this.onStartMatch,
    this.players = const [],
    this.playersNotice,
    this.templates = RuleTemplateRepository.builtIns,
    this.onManageRules,
    super.key,
  });

  final ValueChanged<MatchSetup>? onStartMatch;
  final List<Player> players;
  final String? playersNotice;
  final List<RuleTemplate> templates;
  final VoidCallback? onManageRules;

  @override
  State<PregamePage> createState() => _PregamePageState();
}

class _PregamePageState extends State<PregamePage> {
  late final PregameController _controller;
  late final TextEditingController _redNameController;
  late final TextEditingController _blueNameController;
  late final TextEditingController _countdownMinutesController;
  List<PregameValidationError> _validationErrors = const [];

  @override
  void initState() {
    super.initState();
    _controller = PregameController(
      templates: widget.templates,
      players: widget.players,
    );
    _redNameController = TextEditingController(text: _controller.state.redName);
    _blueNameController = TextEditingController(
      text: _controller.state.blueName,
    );
    _countdownMinutesController = TextEditingController(
      text: _controller.state.countdownMinutesText,
    );
  }

  @override
  void didUpdateWidget(covariant PregamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templates != widget.templates) {
      _controller.setTemplates(widget.templates);
      _syncCountdownMinutesController();
    }
    if (oldWidget.players != widget.players) {
      // A repository stream can emit while this page is open. Updating the
      // available options must not recreate the controller or overwrite a
      // temporary name the user is currently typing.
      _controller.setPlayers(widget.players);
    }
  }

  @override
  void dispose() {
    _redNameController.dispose();
    _blueNameController.dispose();
    _countdownMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(title: const Text(pregameTitleText)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  pregamePlayersText,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ParticipantSetup(
                  sideLabel: '红方',
                  profileKey: const Key('pregame-red-profile'),
                  nameKey: const Key('pregame-red-name'),
                  nameController: _redNameController,
                  selectedProfileId: state.redPlayerProfileId,
                  players: widget.players,
                  onProfileChanged: (value) => _selectProfile(true, value),
                  onNameChanged: (value) {
                    setState(() {
                      _controller.setRedName(value);
                      _clearValidation();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ParticipantSetup(
                  sideLabel: '蓝方',
                  profileKey: const Key('pregame-blue-profile'),
                  nameKey: const Key('pregame-blue-name'),
                  nameController: _blueNameController,
                  selectedProfileId: state.bluePlayerProfileId,
                  players: widget.players,
                  onProfileChanged: (value) => _selectProfile(false, value),
                  onNameChanged: (value) {
                    setState(() {
                      _controller.setBlueName(value);
                      _clearValidation();
                    });
                  },
                ),
                if (widget.playersNotice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.playersNotice!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('pregame-rule-template'),
                  initialValue: state.ruleTemplateId,
                  decoration: const InputDecoration(
                    labelText: pregameRuleTemplateText,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final template in widget.templates)
                      DropdownMenuItem(
                        value: template.id,
                        child: Text(_templateLabel(template)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _controller.setRuleTemplateId(value);
                      _syncCountdownMinutesController();
                      _clearValidation();
                    });
                  },
                ),
                if (widget.onManageRules != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        onPressed: widget.onManageRules,
                        icon: const Icon(Icons.tune),
                        label: const Text('管理规则模板'),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SectionLabel(text: pregameRecordingModeText),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SelectionButton<RecordingMode>(
                      key: const Key('pregame-recording-simple'),
                      label: '简洁记录',
                      selected: state.recordingMode == RecordingMode.simple,
                      onPressed: () =>
                          _selectRecordingMode(RecordingMode.simple),
                    ),
                    _SelectionButton<RecordingMode>(
                      key: const Key('pregame-recording-detailed'),
                      label: '详细记录',
                      selected: state.recordingMode == RecordingMode.detailed,
                      onPressed: () =>
                          _selectRecordingMode(RecordingMode.detailed),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TrackingCoverage>(
                  key: const Key('pregame-tracking-coverage'),
                  initialValue: state.trackingCoverage,
                  decoration: const InputDecoration(
                    labelText: pregameTrackingCoverageText,
                    helperText: '选择需要记录到比赛回放中的出手与失误范围。',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final coverage in TrackingCoverage.values)
                      DropdownMenuItem(
                        value: coverage,
                        child: Text(_trackingCoverageLabel(coverage)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _controller.setTrackingCoverage(value);
                      _clearValidation();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('pregame-timer'),
                  contentPadding: EdgeInsets.zero,
                  value: state.timerEnabled,
                  title: const Text(pregameTimerText),
                  subtitle: Text(
                    state.timerEnabled ? '已开启：请选择计时方式' : '关闭时不记录比赛计时',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _controller.setTimerEnabled(value);
                      _clearValidation();
                    });
                  },
                ),
                if (state.timerEnabled) ...[
                  const SizedBox(height: 4),
                  _SectionLabel(text: pregameClockModeText),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SelectionButton<ClockMode>(
                        key: const Key('pregame-clock-count-up'),
                        label: '正计时',
                        selected: state.clockMode == ClockMode.countUp,
                        onPressed: () => _selectClockMode(ClockMode.countUp),
                      ),
                      _SelectionButton<ClockMode>(
                        key: const Key('pregame-clock-countdown'),
                        label: '倒计时',
                        selected: state.clockMode == ClockMode.countdown,
                        onPressed: () => _selectClockMode(ClockMode.countdown),
                      ),
                    ],
                  ),
                  if (state.clockMode == ClockMode.countdown) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('pregame-countdown-minutes'),
                      controller: _countdownMinutesController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: InputDecoration(
                        labelText: '倒计时分钟（1–180）',
                        helperText: '倒计时必须设置在 1 到 180 分钟之间。',
                        suffixText: '分钟',
                        border: OutlineInputBorder(),
                        errorText: _countdownErrorText(state),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _controller.setCountdownMinutesText(value);
                          _clearValidation();
                        });
                      },
                    ),
                  ],
                ],
                SwitchListTile(
                  key: const Key('pregame-win-by-two'),
                  contentPadding: EdgeInsets.zero,
                  value: state.winByTwo,
                  title: const Text(pregameWinByTwoText),
                  onChanged: (value) {
                    setState(() {
                      _controller.setWinByTwo(value);
                      _clearValidation();
                    });
                  },
                ),
                ExpansionTile(
                  key: const Key('pregame-advanced'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text(pregameAdvancedText),
                  initiallyExpanded: state.advancedExpanded,
                  onExpansionChanged: _controller.setAdvancedExpanded,
                  children: [
                    _NumberSetting(
                      label: pregameTargetScoreText,
                      value: state.targetScore,
                      onChanged: (value) {
                        setState(() {
                          _controller.setTargetScore(value);
                          _clearValidation();
                        });
                      },
                    ),
                  ],
                ),
                if (_validationErrors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ValidationMessage(
                    key: Key('pregame-validation'),
                    errors: _validationErrors,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    key: const Key('pregame-start-match'),
                    onPressed: _startMatch,
                    child: const Text(pregameStartMatchText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectProfile(bool red, String? value) {
    final accepted = red
        ? _controller.selectRedProfile(value)
        : _controller.selectBlueProfile(value);
    if (!accepted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('该球员档案已用于另一方，请选择其他档案。')));
      return;
    }
    if (value != null) {
      final name = red ? _controller.state.redName : _controller.state.blueName;
      final controller = red ? _redNameController : _blueNameController;
      controller.value = controller.value.copyWith(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
        composing: TextRange.empty,
      );
    }
    setState(_clearValidation);
  }

  void _selectRecordingMode(RecordingMode mode) {
    setState(() {
      _controller.setRecordingMode(mode);
      _clearValidation();
    });
  }

  void _selectClockMode(ClockMode mode) {
    setState(() {
      _controller.setClockMode(mode);
      _clearValidation();
    });
  }

  void _startMatch() {
    if (_redNameController.text != _controller.state.redName) {
      _controller.setRedName(_redNameController.text);
    }
    if (_blueNameController.text != _controller.state.blueName) {
      _controller.setBlueName(_blueNameController.text);
    }
    final validation = _controller.validate();
    if (!validation.isValid) {
      setState(() => _validationErrors = validation.errors);
      return;
    }
    setState(() => _validationErrors = const []);
    widget.onStartMatch?.call(_controller.createMatchSetup());
  }

  void _clearValidation() {
    if (_validationErrors.isNotEmpty) _validationErrors = const [];
  }

  void _syncCountdownMinutesController() {
    final text = _controller.state.countdownMinutesText;
    if (_countdownMinutesController.text == text) return;
    _countdownMinutesController.value = _countdownMinutesController.value
        .copyWith(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange.empty,
        );
  }

  static String? _countdownErrorText(PregameState state) {
    final parsed = int.tryParse(state.countdownMinutesText);
    if (state.countdownDurationInputInvalid ||
        parsed == null ||
        parsed != state.timeLimitMinutes ||
        state.timeLimitMinutes < 1 ||
        state.timeLimitMinutes > 180) {
      return '请输入 1 到 180 之间的整数分钟。';
    }
    return null;
  }

  static String _templateLabel(RuleTemplate template) {
    if (template.id == 'free') return pregameFreeScoringText;
    if (template.id == 'eleven_win_by_two') return pregameElevenPointText;
    if (template.id == 'twenty_one_win_by_two') {
      return pregameTwentyOnePointText;
    }
    return template.name;
  }

  static String _trackingCoverageLabel(TrackingCoverage coverage) {
    return switch (coverage) {
      TrackingCoverage.none => '不追踪出手与失误',
      TrackingCoverage.scoresOnly => '仅记录比分',
      TrackingCoverage.shotAttempts => '投篮出手',
      TrackingCoverage.locations => '投篮出手与位置',
      TrackingCoverage.full => '完整记录（含失误）',
    };
  }
}

class _ParticipantSetup extends StatelessWidget {
  const _ParticipantSetup({
    required this.sideLabel,
    required this.profileKey,
    required this.nameKey,
    required this.nameController,
    required this.selectedProfileId,
    required this.players,
    required this.onProfileChanged,
    required this.onNameChanged,
  });

  final String sideLabel;
  final Key profileKey;
  final Key nameKey;
  final TextEditingController nameController;
  final String? selectedProfileId;
  final List<Player> players;
  final ValueChanged<String?> onProfileChanged;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    final profileItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: _temporaryProfileId,
        child: Text(pregameTemporaryParticipantText),
      ),
      for (final player in players)
        DropdownMenuItem(value: player.id, child: Text(player.nickname)),
    ];
    if (selectedProfileId != null &&
        players.every((player) => player.id != selectedProfileId)) {
      profileItems.add(
        DropdownMenuItem(
          value: selectedProfileId,
          enabled: false,
          child: const Text('已删除的球员档案'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sideLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: '参赛方式',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: profileKey,
              value: selectedProfileId ?? _temporaryProfileId,
              isExpanded: true,
              items: profileItems,
              onChanged: (value) {
                if (value == null) return;
                onProfileChanged(value == _temporaryProfileId ? null : value);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: nameKey,
          controller: nameController,
          decoration: InputDecoration(
            labelText: selectedProfileId == null
                ? '$sideLabel临时姓名'
                : '$sideLabel姓名快照',
            helperText: selectedProfileId == null
                ? '可输入临时姓名；双方临时同名也可以。'
                : '比赛开始时保存当前显示的姓名快照。',
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onChanged: onNameChanged,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SelectionButton<T> extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({required this.errors, super.key});

  final List<PregameValidationError> errors;

  @override
  Widget build(BuildContext context) {
    final messages = errors.map(pregameValidationErrorText).toList();
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final message in messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(message),
                ),
            ],
          ),
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
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: SegmentedButton<int>(
        segments: [
          ButtonSegment(value: value - 1, label: const Icon(Icons.remove)),
          ButtonSegment(value: value, label: Text('$value$pregamePointText')),
          ButtonSegment(value: value + 1, label: const Icon(Icons.add)),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
