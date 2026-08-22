import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
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
    super.key,
  }) : assert(matchId != null || setup != null || controller != null);

  final String? matchId;
  final MatchSetup? setup;
  final ScoringController? controller;
  final VoidCallback? onOpenReplay;
  final Future<void> Function()? onRequestLeave;
  final VoidCallback? onResumeClock;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  late ScoringController _controller;
  bool _ownsController = false;
  bool _leaveBusy = false;

  @override
  void initState() {
    super.initState();
    _attachController();
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
  }

  @override
  void dispose() {
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
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _handleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    final page = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (widget.onRequestLeave != null)
                    IconButton(
                      key: const Key('scoring-leave'),
                      tooltip: '返回',
                      onPressed: _requestLeave,
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.blueName} ${state.score.blueScore}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onOpenReplay == null ? null : _openReplay,
                    icon: const Icon(Icons.query_stats, size: 20),
                    label: const Text(scoringReplayText),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onResumeClock != null)
                    TextButton(
                      key: scoringResumeClockKey,
                      onPressed: widget.onResumeClock,
                      child: const Text('恢复计时'),
                    ),
                  const SizedBox(width: 8),
                  const Text('00:00'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${state.score.redScore} ${state.redName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 122,
                        child: ScoreSidePanel(
                          side: TeamSide.blue,
                          name: state.blueName,
                          score: state.score.blueScore,
                          fouls: state.blueFouls,
                          onScore: (points) =>
                              _scoreAndAskLocation(TeamSide.blue, points),
                          onFoul: () => _handleFoul(TeamSide.blue),
                          scoreButtons: state.ruleTemplate.scoreButtons,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: CourtView(
                            shotLocations: state.shotLocations,
                            pendingLocation: state.pendingLocation,
                            onPendingLocationChanged:
                                _controller.updatePendingLocation,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 122,
                        child: ScoreSidePanel(
                          side: TeamSide.red,
                          name: state.redName,
                          score: state.score.redScore,
                          fouls: state.redFouls,
                          onScore: (points) =>
                              _scoreAndAskLocation(TeamSide.red, points),
                          onFoul: () => _handleFoul(TeamSide.red),
                          scoreButtons: state.ruleTemplate.scoreButtons,
                        ),
                      ),
                    ],
                  ),
                  if (state.pendingLocation != null)
                    Positioned(
                      left: 138,
                      right: 138,
                      bottom: 8,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: PendingLocationBar(
                          onConfirm: () {
                            unawaited(_confirmPendingLocation());
                          },
                          onSkip: _skipPendingLocation,
                          onUndo: () {
                            unawaited(_undoPendingEvent());
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (state.ruleHints.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
              ),
          ],
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

  Future<void> _scoreAndAskLocation(TeamSide side, int points) async {
    final accepted = await _recordScore(side, points);
    if (!accepted) {
      if (_controller.isCommandBacked) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(scoringResolvePendingText)));
      return;
    }

    if (!mounted) return;
    final markLocation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(scoringMarkShotDialogTitle),
          content: const Text(scoringMarkShotDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(scoringDoNotMarkText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(scoringMarkText),
            ),
          ],
        );
      },
    );

    if (markLocation == false) {
      _controller.skipPendingLocation();
    }
  }

  Future<bool> _recordScore(TeamSide side, int points) async {
    try {
      if (_controller.isCommandBacked) {
        return await _controller.recordScoreCommitted(
          side: side,
          points: points,
        );
      }
      return _controller.addScore(side: side, points: points);
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
      return false;
    }
  }

  void _handleFoul(TeamSide side) {
    if (_controller.state.pendingLocation != null) {
      _showPendingLocationMessage();
      return;
    }
    if (!_controller.isCommandBacked) {
      _controller.addFoul(side);
      return;
    }
    unawaited(_commitFoul(side));
  }

  Future<void> _commitFoul(TeamSide side) async {
    try {
      final accepted = await _controller.recordFoulCommitted(side);
      if (!accepted && _controller.state.pendingLocation != null) {
        _showPendingLocationMessage();
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  void _skipPendingLocation() {
    if (!_controller.skipPendingLocation() &&
        _controller.state.pendingLocation != null) {
      _showPendingLocationMessage();
    }
  }

  void _showPendingLocationMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(scoringResolvePendingText)));
  }

  Future<void> _confirmPendingLocation() async {
    try {
      await _controller.confirmPendingLocation();
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _undoPendingEvent() async {
    try {
      await _controller.undoLastEventCommitted();
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
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
    } on MatchCommandFailure catch (nextFailure) {
      _showCommandFailure(nextFailure);
    }
  }

  void _openReplay() {
    if (_controller.state.pendingLocation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(scoringResolvePendingText)));
      return;
    }
    widget.onOpenReplay?.call();
  }
}
