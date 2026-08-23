import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

const scoringMarkShotDialogTitle = '标记投篮位置？';
const scoringMarkShotDialogContent = '可在球场上点选或拖动圆点后确认。';
const scoringDoNotMarkText = '不标记';
const scoringMarkText = '标记';
const scoringResolvePendingText = '请先确认、跳过或撤销当前落点';
const scoringReplayText = '复盘';
const scoringResumeClockKey = Key('scoring-resume-clock');

class ScoringPage extends StatefulWidget {
  const ScoringPage({
    this.matchId,
    this.setup,
    this.controller,
    this.onOpenReplay,
    this.onRequestLeave,
    this.onResumeClock,
    this.clockNowUtc,
    this.clockTick = const Duration(seconds: 1),
    this.onActionCommitted,
    super.key,
  }) : assert(matchId != null || setup != null || controller != null);

  final String? matchId;
  final MatchSetup? setup;
  final ScoringController? controller;
  final VoidCallback? onOpenReplay;
  final Future<void> Function()? onRequestLeave;
  final VoidCallback? onResumeClock;
  final DateTime Function()? clockNowUtc;
  final Duration clockTick;
  final FutureOr<void> Function()? onActionCommitted;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  late ScoringController _controller;
  bool _ownsController = false;
  bool _leaveBusy = false;
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    _attachController();
    _startClockTicker();
  }

  @override
  void didUpdateWidget(covariant ScoringPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.matchId != widget.matchId ||
        oldWidget.setup != widget.setup) {
      _detachController();
      _attachController();
    }
    if (oldWidget.clockNowUtc != widget.clockNowUtc ||
        oldWidget.clockTick != widget.clockTick) {
      _startClockTicker();
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _clockTicker = null;
    _detachController();
    super.dispose();
  }

  void _attachController() {
    _controller =
        widget.controller ??
        ScoringController(matchId: widget.matchId, setup: widget.setup);
    _ownsController = widget.controller == null;
    _controller.addListener(_handleStateChanged);
  }

  void _detachController() {
    _controller.removeListener(_handleStateChanged);
    if (_ownsController) _controller.dispose();
  }

  void _startClockTicker() {
    _clockTicker?.cancel();
    if (widget.clockTick <= Duration.zero) return;
    _clockTicker = Timer.periodic(widget.clockTick, (_) {
      if (mounted && _controller.clock != null) setState(() {});
    });
  }

  DateTime _nowUtc() => (widget.clockNowUtc?.call() ?? DateTime.now()).toUtc();

  ClockProjection? _displayClock() {
    final persisted = _controller.clock;
    if (persisted == null) return null;
    return ClockEngine().project(
      state: persisted.normalizedState,
      now: _nowUtc(),
    );
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final clock = _displayClock();
    final page = Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _Scoreboard(
                  state: state,
                  clock: clock,
                  onLeave: widget.onRequestLeave == null ? null : _requestLeave,
                  onReplay: widget.onOpenReplay == null ? null : _openReplay,
                  onResumeClock: widget.onResumeClock,
                ),
                Expanded(child: _buildWorkspace(context, constraints, state)),
                if (state.ruleHints.isNotEmpty) _buildRuleHints(context, state),
                if (state.detailedShotDraft != null)
                  _buildDetailedDraftDock(context, state),
                _buildCommandDock(context, state, clock),
              ],
            );
          },
        ),
      ),
    );
    final onRequestLeave = widget.onRequestLeave;
    if (onRequestLeave == null) return page;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: page,
    );
  }

  Widget _buildWorkspace(
    BuildContext context,
    BoxConstraints constraints,
    MatchScoringState state,
  ) {
    final sideWidth = constraints.maxWidth < 640
        ? (constraints.maxWidth * 0.22).clamp(88.0, 132.0)
        : (constraints.maxWidth * 0.2).clamp(132.0, 188.0);
    return Row(
      children: [
        SizedBox(
          width: sideWidth,
          child: _buildSidePanel(context, state, TeamSide.blue),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                CourtView(
                  key: const Key('scoring-court'),
                  shotLocations: state.shotLocations,
                  pendingLocation: state.pendingLocation,
                  detailedShotDraft: state.detailedShotDraft,
                  onPendingLocationChanged: _controller.updatePendingLocation,
                  onCourtPointTap: _handleCourtPoint,
                ),
                if (state.pendingLocation != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: PendingLocationBar(
                        onConfirm: () => unawaited(_confirmPendingLocation()),
                        onSkip: _cancelPendingLocation,
                        onUndo: () => unawaited(_undoPendingEvent()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: sideWidth,
          child: _buildSidePanel(context, state, TeamSide.red),
        ),
      ],
    );
  }

  Widget _buildSidePanel(
    BuildContext context,
    MatchScoringState state,
    TeamSide side,
  ) {
    final isBlue = side == TeamSide.blue;
    return ScoreSidePanel(
      side: side,
      name: isBlue ? state.blueName : state.redName,
      score: isBlue ? state.score.blueScore : state.score.redScore,
      fouls: isBlue ? state.blueFouls : state.redFouls,
      scoreButtons: state.ruleTemplate.scoreButtons,
      scoreEnabled: state.recordingMode != RecordingMode.detailed,
      missEnabled:
          _allowsShotAttempts && state.recordingMode != RecordingMode.detailed,
      onScore: (points) => unawaited(_recordScore(side, points)),
      onMiss: () => unawaited(_recordMiss(side)),
      onFoul: () => unawaited(_recordFoul(side)),
    );
  }

  Widget _buildRuleHints(BuildContext context, MatchScoringState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              state.ruleHints.map((hint) => hint.message).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedDraftDock(
    BuildContext context,
    MatchScoringState state,
  ) {
    final draft = state.detailedShotDraft!;
    return _DockSurface(
      key: const Key('detailed-draft-dock'),
      color: HoopTraceColors.cream,
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(
              '草稿 ${draft.outcome == ShotOutcome.missed ? '未中' : '${draft.points} 分'}',
              semanticsLabel: '当前投篮草稿',
            ),
            _DockAction(
              key: const Key('draft-shooter-blue'),
              label: '蓝方出手',
              icon: Icons.person,
              selected: draft.side == TeamSide.blue,
              onPressed: () =>
                  _controller.updateDetailedShot(side: TeamSide.blue),
            ),
            _DockAction(
              key: const Key('draft-shooter-red'),
              label: '红方出手',
              icon: Icons.person,
              selected: draft.side == TeamSide.red,
              onPressed: () =>
                  _controller.updateDetailedShot(side: TeamSide.red),
            ),
            _DockAction(
              key: const Key('draft-outcome-made'),
              label: '命中',
              icon: Icons.check,
              selected: draft.outcome == ShotOutcome.made,
              onPressed: () =>
                  _controller.updateDetailedShot(outcome: ShotOutcome.made),
            ),
            _DockAction(
              key: const Key('draft-outcome-missed'),
              label: '未中',
              icon: Icons.close,
              selected: draft.outcome == ShotOutcome.missed,
              onPressed: () =>
                  _controller.updateDetailedShot(outcome: ShotOutcome.missed),
            ),
            for (final point in state.ruleTemplate.scoreButtons)
              _DockAction(
                key: Key('draft-points-$point'),
                label: '$point 分',
                onPressed: () => _controller.updateDetailedShot(points: point),
              ),
            _DockAction(
              key: const Key('draft-cancel'),
              label: '取消草稿',
              icon: Icons.undo,
              onPressed: _cancelDetailedShot,
            ),
            _DockAction(
              key: const Key('draft-commit'),
              label: '提交投篮',
              icon: Icons.check_circle,
              emphasized: true,
              onPressed: () => unawaited(_commitDetailedShot()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandDock(
    BuildContext context,
    MatchScoringState state,
    ClockProjection? clock,
  ) {
    final canLocate =
        state.recordingMode == RecordingMode.simple && _allowsLocations;
    return _DockSurface(
      key: const Key('scoring-command-dock'),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            _DockAction(
              key: const Key('command-undo'),
              label: '撤销',
              icon: Icons.undo,
              onPressed: () => unawaited(_undoLastEvent()),
            ),
            if (canLocate)
              _DockAction(
                key: const Key('command-locate'),
                label: '定位最近投篮',
                icon: Icons.location_on_outlined,
                onPressed: _beginLocate,
              ),
            _DockAction(
              key: const Key('command-pause'),
              label: '暂停',
              icon: Icons.pause,
              onPressed: () => unawaited(_pause()),
            ),
            _DockAction(
              key: const Key('command-resume'),
              label: '恢复',
              icon: Icons.play_arrow,
              onPressed: () => unawaited(_resume()),
            ),
            _DockAction(
              key: const Key('command-free-throw-blue-made'),
              label: '蓝罚中',
              onPressed: () => unawaited(_recordFreeThrow(TeamSide.blue, true)),
            ),
            _DockAction(
              key: const Key('command-free-throw-blue-miss'),
              label: '蓝罚失',
              onPressed: () =>
                  unawaited(_recordFreeThrow(TeamSide.blue, false)),
            ),
            _DockAction(
              key: const Key('command-free-throw-red-made'),
              label: '红罚中',
              onPressed: () => unawaited(_recordFreeThrow(TeamSide.red, true)),
            ),
            _DockAction(
              key: const Key('command-free-throw-red-miss'),
              label: '红罚失',
              onPressed: () => unawaited(_recordFreeThrow(TeamSide.red, false)),
            ),
            _DockAction(
              key: const Key('command-possession-blue'),
              label: '球权蓝',
              selected: state.currentPossession == TeamSide.blue,
              onPressed: () => unawaited(_recordPossession(TeamSide.blue)),
            ),
            _DockAction(
              key: const Key('command-possession-red'),
              label: '球权红',
              selected: state.currentPossession == TeamSide.red,
              onPressed: () => unawaited(_recordPossession(TeamSide.red)),
            ),
            _DockAction(
              key: const Key('command-note'),
              label: '备注',
              icon: Icons.notes,
              onPressed: () => unawaited(_enterNote()),
            ),
            _DockAction(
              key: const Key('command-custom'),
              label: '自定义',
              icon: Icons.add_circle_outline,
              onPressed: () => unawaited(_enterCustom()),
            ),
            if (clock != null)
              Text(
                clock.isRunning ? '计时进行中' : _clockStatus(clock),
                semanticsLabel: '计时状态 ${_clockStatus(clock)}',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLeave() async {
    final onRequestLeave = widget.onRequestLeave;
    if (onRequestLeave == null || _leaveBusy) return;
    _leaveBusy = true;
    try {
      await onRequestLeave();
    } finally {
      if (mounted) setState(() => _leaveBusy = false);
    }
  }

  void _handleCourtPoint(CourtPoint point) {
    final draft = _controller.detailedShotDraft;
    if (draft != null) {
      _controller.updateDetailedShot(point: point);
      return;
    }
    if (_controller.recordingMode == RecordingMode.detailed &&
        !_controller.beginDetailedShot(point)) {
      _showActionRejected('当前无法创建投篮草稿');
    }
  }

  Future<void> _recordScore(TeamSide side, int points) async {
    try {
      final accepted = await _controller.recordScoreCommitted(
        side: side,
        points: points,
      );
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(scoringResolvePendingText);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordMiss(TeamSide side) async {
    try {
      final accepted = await _controller.recordMissCommitted(side: side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('当前跟踪设置不记录未中投篮');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordFoul(TeamSide side) async {
    try {
      final accepted = await _controller.recordFoulCommitted(side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('当前操作被拒绝，请先完成落点或草稿');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordFreeThrow(TeamSide side, bool made) async {
    try {
      final accepted = await _controller.recordFreeThrowCommitted(
        side: side,
        made: made,
      );
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('当前跟踪设置不记录该罚球');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordPossession(TeamSide side) async {
    try {
      final accepted = await _controller.recordPossessionCommitted(side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('球权修改未提交');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  bool _beginLocate() {
    final accepted = _controller.beginLocateLastUnlocatedShot();
    if (!accepted) _showActionRejected('暂无可定位的未标记投篮');
    return accepted;
  }

  void _cancelPendingLocation() {
    if (!_controller.cancelLocateLastUnlocatedShot()) {
      _showActionRejected('当前落点无法取消');
    }
  }

  Future<void> _confirmPendingLocation() async {
    final hadPending = _controller.state.pendingLocation != null;
    try {
      await _controller.confirmPendingLocation();
      if (hadPending && _controller.state.pendingLocation == null) {
        _notifyCommitted();
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _undoPendingEvent() => _undoLastEvent();

  Future<void> _undoLastEvent() async {
    try {
      final accepted = await _controller.undoLastEventCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('撤销未提交');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _pause() async {
    try {
      final accepted = await _controller.pauseCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('当前无法暂停计时');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _resume() async {
    try {
      final accepted = await _controller.resumeCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('当前无法恢复计时');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _commitDetailedShot() async {
    try {
      final accepted = await _controller.commitDetailedShot();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected('投篮草稿尚未完成');
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  void _cancelDetailedShot() {
    if (!_controller.cancelDetailedShot()) {
      _showActionRejected('当前没有可取消的草稿');
    }
  }

  Future<void> _enterNote() async {
    final note = await _showTextEntry(
      title: '添加备注',
      hint: '例如：暂停、战术或现场情况',
      confirm: '记录备注',
    );
    if (note == null) return;
    try {
      final accepted = await _controller.recordNoteCommitted(note);
      if (accepted) _notifyCommitted();
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _enterCustom() async {
    final label = await _showTextEntry(
      title: '记录自定义事件',
      hint: '事件标签',
      confirm: '记录事件',
    );
    if (label == null) return;
    try {
      final accepted = await _controller.recordCustomCommitted(label: label);
      if (accepted) _notifyCommitted();
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<String?> _showTextEntry({
    required String title,
    required String hint,
    required String confirm,
  }) async {
    final editingController = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: editingController,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(editingController.text.trim()),
              child: Text(confirm),
            ),
          ],
        ),
      );
    } finally {
      editingController.dispose();
    }
  }

  void _notifyCommitted() {
    final callback = widget.onActionCommitted;
    if (callback != null) unawaited(Future<void>.sync(callback));
  }

  void _showActionRejected(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCommandFailure(MatchCommandFailure failure) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failure.message),
        action: failure.canRetry
            ? SnackBarAction(
                label: '重试',
                onPressed: () => unawaited(_retryCommand(failure)),
              )
            : null,
      ),
    );
  }

  Future<void> _retryCommand(MatchCommandFailure failure) async {
    try {
      await _controller.retryCommand(failure);
      _notifyCommitted();
    } on MatchCommandFailure catch (nextFailure) {
      _showCommandFailure(nextFailure);
    }
  }

  void _openReplay() {
    if (_controller.state.pendingLocation != null ||
        _controller.state.detailedShotDraft != null) {
      _showActionRejected(scoringResolvePendingText);
      return;
    }
    widget.onOpenReplay?.call();
  }

  bool get _allowsShotAttempts =>
      _controller.trackingCoverage.index >= TrackingCoverage.shotAttempts.index;

  bool get _allowsLocations =>
      _controller.trackingCoverage.index >= TrackingCoverage.locations.index;

  String _clockStatus(ClockProjection clock) {
    if (clock.isRegulationExpired) return '常规时间结束';
    if (clock.phase == ClockPhase.overtime) return '加时赛';
    return clock.isRunning ? '计时进行中' : '计时已暂停';
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.state,
    required this.clock,
    required this.onLeave,
    required this.onReplay,
    required this.onResumeClock,
  });

  final MatchScoringState state;
  final ClockProjection? clock;
  final VoidCallback? onLeave;
  final VoidCallback? onReplay;
  final VoidCallback? onResumeClock;

  @override
  Widget build(BuildContext context) {
    final clockLabel = clock == null
        ? '无计时'
        : '${clock!.phase == ClockPhase.overtime ? 'OT ' : ''}${_formatSeconds(clock!.displaySeconds)}';
    final clockStatus = clock == null
        ? '计时未配置'
        : clock!.phase == ClockPhase.overtime
        ? '加时赛'
        : clock!.isRegulationExpired
        ? '常规时间结束'
        : clock!.isRunning
        ? '计时进行中'
        : '计时已暂停';
    return Material(
      color: HoopTraceColors.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            if (onLeave != null)
              IconButton(
                key: const Key('scoring-leave'),
                tooltip: '返回计分列表',
                color: Colors.white,
                onPressed: onLeave,
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: _ScoreLabel(
                name: state.blueName,
                score: state.score.blueScore,
                color: HoopTraceColors.blue,
                alignment: Alignment.centerLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clockLabel,
                    semanticsLabel: '比赛时间 $clockLabel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    clockStatus,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ScoreLabel(
                name: state.redName,
                score: state.score.redScore,
                color: HoopTraceColors.red,
                alignment: Alignment.centerRight,
              ),
            ),
            if (onReplay != null)
              Tooltip(
                message: scoringReplayText,
                child: TextButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.query_stats, color: Colors.white),
                  label: const Text(scoringReplayText),
                ),
              ),
            if (onResumeClock != null)
              TextButton(
                key: scoringResumeClockKey,
                onPressed: onResumeClock,
                child: const Text('恢复计时'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({
    required this.name,
    required this.score,
    required this.color,
    required this.alignment,
  });

  final String name;
  final int score;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        alignment == Alignment.centerLeft ? '$name $score' : '$score $name',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DockSurface extends StatelessWidget {
  const _DockSurface({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      elevation: 3,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 154),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: child,
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final button = emphasized || selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: selected
                  ? HoopTraceColors.orange
                  : HoopTraceColors.ink,
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon == null ? const SizedBox.shrink() : Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          );
    return Tooltip(message: label, child: button);
  }
}

String _formatSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remaining = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
}
