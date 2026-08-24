import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

const scoringResumeClockKey = Key('scoring-resume-clock');

class ScoringPage extends StatefulWidget {
  const ScoringPage({
    this.matchId,
    this.setup,
    this.controller,
    this.onOpenReplay,
    this.onRequestLeave,
    this.onResumeClock,
    this.onContinueDecision,
    this.onFinishDecision,
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
  final Future<void> Function()? onContinueDecision;
  final Future<void> Function(int redScore, int blueScore)? onFinishDecision;
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
  bool _decisionBusy = false;
  bool _pulseOn = false;
  Timer? _clockTicker;
  Timer? _supplementTicker;

  @override
  void initState() {
    super.initState();
    _attachController();
    _startTickers();
  }

  @override
  void didUpdateWidget(covariant ScoringPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged =
        oldWidget.controller != widget.controller ||
        oldWidget.matchId != widget.matchId ||
        oldWidget.setup != widget.setup;
    if (controllerChanged) {
      _detachController();
      _attachController();
    }
    if (controllerChanged ||
        oldWidget.clockNowUtc != widget.clockNowUtc ||
        oldWidget.clockTick != widget.clockTick) {
      _startTickers();
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _supplementTicker?.cancel();
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

  void _startTickers() {
    _clockTicker?.cancel();
    _supplementTicker?.cancel();
    if (widget.clockTick > Duration.zero && _controller.timerEnabled) {
      _clockTicker = Timer.periodic(widget.clockTick, (_) {
        if (mounted) setState(() {});
      });
    }
    // 450ms is a soft pulse (2.2Hz), also slow enough for touch users.
    _supplementTicker = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      final window = _controller.locationSupplementWindow;
      if (window == null) {
        if (_pulseOn) setState(() => _pulseOn = false);
        return;
      }
      final now = _nowUtc();
      _controller.expireSupplementWindow(atUtc: now);
      if (mounted) setState(() => _pulseOn = !_pulseOn);
    });
  }

  DateTime _nowUtc() => (widget.clockNowUtc?.call() ?? DateTime.now()).toUtc();

  ClockProjection? _displayClock() {
    final persisted = _controller.clock;
    if (!_controller.timerEnabled || persisted == null) return null;
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
    final labels = _labels(context);
    final page = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Scoreboard(
              state: state,
              clock: clock,
              onLeave: _requestLeave,
              onUndo: () => unawaited(_undoLastScoringAction()),
              onMore: _showMore,
              labels: labels,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildWorkspace(context, state),
                  if (state.decision != null)
                    _buildDecisionOverlay(context, state),
                ],
              ),
            ),
            if (state.ruleHints.isNotEmpty || state.ruleWarnings.isNotEmpty)
              _buildRuleHints(context, state),
          ],
        ),
      ),
    );
    if (widget.onRequestLeave == null) return page;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: page,
    );
  }

  Widget _buildWorkspace(BuildContext context, MatchScoringState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final portrait =
            constraints.maxWidth < 600 &&
            constraints.maxHeight > constraints.maxWidth * 1.05;
        if (portrait) {
          final sideHeight = (constraints.maxHeight * 0.31).clamp(220.0, 310.0);
          return Column(
            children: [
              Expanded(child: _buildCourt(context, state)),
              SizedBox(
                height: sideHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSidePanel(context, state, TeamSide.blue),
                    ),
                    Expanded(
                      child: _buildSidePanel(context, state, TeamSide.red),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        final sideWidth = (constraints.maxWidth * 0.2).clamp(132.0, 220.0);
        return Row(
          children: [
            SizedBox(
              width: sideWidth,
              child: _buildSidePanel(context, state, TeamSide.blue),
            ),
            Expanded(child: _buildCourt(context, state)),
            SizedBox(
              width: sideWidth,
              child: _buildSidePanel(context, state, TeamSide.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCourt(BuildContext context, MatchScoringState state) {
    final window = state.locationSupplementWindow;
    final remaining = _remainingSeconds(window);
    final prompt = state.courtFirstShotDraft != null
        ? _labels(context).chooseScoringSide
        : window == null
        ? null
        : _labels(context).supplementPrompt(
            _localizedSide(_localizations(context), window.side),
            window.points,
            remaining,
          );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CourtView(
        key: const Key('scoring-court'),
        shotLocations: state.shotLocations,
        pendingLocation: state.pendingLocation,
        detailedShotDraft: state.courtFirstShotDraft,
        locationPrompt: prompt,
        onPendingLocationChanged: _controller.updatePendingLocation,
        onCourtPointTap: _handleCourtPoint,
      ),
    );
  }

  int _remainingSeconds(LocationSupplementWindow? window) {
    if (window == null) return 0;
    final remaining = window.expiresAtUtc.difference(_nowUtc()).inMilliseconds;
    return (remaining / 1000).ceil().clamp(0, 10);
  }

  Widget _buildSidePanel(
    BuildContext context,
    MatchScoringState state,
    TeamSide side,
  ) {
    final isBlue = side == TeamSide.blue;
    final window = state.locationSupplementWindow;
    final remaining = _remainingSeconds(window);
    final activeLocation =
        window != null && window.side == side && window.points > 0;
    final reduceMotion =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
    final draft = state.courtFirstShotDraft;
    return ScoreSidePanel(
      key: Key('${side.name}-side-panel'),
      side: side,
      name: isBlue ? state.blueName : state.redName,
      teamLabel: _labels(context).sideName(side),
      score: isBlue ? state.score.blueScore : state.score.redScore,
      fouls: isBlue ? state.blueFouls : state.redFouls,
      scoreButtons: const [1, 2, 3],
      scoreEnabled: true,
      missEnabled: false,
      foulEnabled: draft == null && state.pendingLocation == null,
      locationPoints: activeLocation ? window.points : null,
      locationRemainingSeconds: activeLocation ? remaining : null,
      locationPulse: activeLocation && _pulseOn,
      reduceMotion: reduceMotion,
      onScore: (points) => unawaited(_recordScore(side, points)),
      onFoul: () => unawaited(_recordFoul(side)),
    );
  }

  Widget _buildRuleHints(BuildContext context, MatchScoringState state) {
    final l10n = _localizations(context);
    final messages = <String>[
      for (final hint in state.ruleHints) _localizedHint(l10n, hint),
      for (final warning in state.ruleWarnings)
        l10n.ruleFoulLimit(warning.limit, _localizedSide(l10n, warning.side)),
    ];
    return Container(
      key: const Key('scoring-rule-hints'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(messages.join(' · '), maxLines: 2)),
        ],
      ),
    );
  }

  Widget _buildDecisionOverlay(BuildContext context, MatchScoringState state) {
    final decision = state.decision!;
    final l10n = _localizations(context);
    final actions = <Widget>[
      if (decision.canContinue && widget.onContinueDecision != null)
        OutlinedButton(
          key: const Key('scoring-decision-continue'),
          onPressed: _decisionBusy ? null : _continueDecision,
          child: Text(l10n.continueMatch),
        ),
      if (decision.canFinish && widget.onFinishDecision != null)
        FilledButton(
          key: const Key('scoring-decision-finish'),
          onPressed: _decisionBusy ? null : _confirmFinishDecision,
          child: Text(l10n.finishMatch),
        ),
    ];
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: Center(
          child: Card(
            key: const Key('scoring-decision-dock'),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Text(
                    l10n.finalScoreLine(
                      state.blueName,
                      decision.blueScore,
                      state.redName,
                      decision.redScore,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCourtPoint(CourtPoint point) {
    final draft = _controller.courtFirstShotDraft;
    if (draft != null) {
      _controller.updateCourtFirstShot(point: point);
      return;
    }
    final window = _controller.locationSupplementWindow;
    if (window != null) {
      unawaited(_attachSupplement(point));
      return;
    }
    if (!_controller.beginOrMoveCourtFirstShot(point)) {
      _showActionRejected(_labels(context).actionRejected);
    }
  }

  Future<void> _attachSupplement(CourtPoint point) async {
    try {
      final accepted = await _controller.attachSupplementLocation(point);
      if (accepted) {
        _notifyCommitted();
      } else if (mounted) {
        _showActionRejected(_labels(context).supplementExpired);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordScore(TeamSide side, int points) async {
    final labels = _labels(context);
    final l10n = _localizations(context);
    final draft = _controller.courtFirstShotDraft;
    if (draft != null) {
      _controller.updateCourtFirstShot(
        side: side,
        outcome: ShotOutcome.made,
        points: points,
      );
      try {
        final accepted = await _controller.commitCourtFirstShot();
        if (accepted) {
          _notifyCommitted();
        } else {
          _showActionRejected(labels.actionRejected);
        }
      } on MatchCommandFailure catch (failure) {
        _showCommandFailure(failure);
      }
      return;
    }
    try {
      final accepted = await _controller.recordScoreCommitted(
        side: side,
        points: points,
      );
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringResolvePending);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<bool> _recordMiss(TeamSide side, {bool rethrowFailure = false}) async {
    final l10n = _localizations(context);
    final draft = _controller.courtFirstShotDraft;
    if (draft != null) {
      _controller.updateCourtFirstShot(
        side: side,
        outcome: ShotOutcome.missed,
        points: 0,
      );
      try {
        final accepted = await _controller.commitCourtFirstShot();
        if (accepted) _notifyCommitted();
        return accepted;
      } on MatchCommandFailure catch (failure) {
        if (rethrowFailure) throw _moreFailure(failure);
        _showCommandFailure(failure);
        return false;
      }
    }
    try {
      final accepted = await _controller.recordMissCommitted(side: side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringMissTrackingDisabled);
      }
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<bool> _recordFreeThrow(
    TeamSide side,
    bool made, {
    bool rethrowFailure = false,
  }) async {
    try {
      final accepted = await _controller.recordFreeThrowCommitted(
        side: side,
        made: made,
      );
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<bool> _recordPossession(
    TeamSide side, {
    bool rethrowFailure = false,
  }) async {
    try {
      final accepted = await _controller.recordPossessionCommitted(side);
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<void> _recordFoul(TeamSide side) async {
    final labels = _labels(context);
    if (_controller.courtFirstShotDraft != null ||
        _controller.state.pendingLocation != null) {
      _showActionRejected(labels.actionRejected);
      return;
    }
    try {
      final accepted = await _controller.recordFoulCommitted(side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(labels.actionRejected);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _undoLastScoringAction() async {
    final l10n = _localizations(context);
    // A court-first marker is still local state, so Undo first clears the
    // gray point without touching the durable scoring history. Legacy local
    // projections may expose the same marker as a pending supplement; clear
    // that draft before asking the controller for the durable undo.
    if (_controller.courtFirstShotDraft != null) {
      _controller.cancelCourtFirstShot();
      return;
    }
    if (_controller.state.pendingLocation != null &&
        _controller.locationSupplementWindow != null) {
      _controller.cancelLocateLastUnlocatedShot();
    }
    try {
      final accepted = await _controller.undoLastScoringActionCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringUndoFailed);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _requestLeave() async {
    final onRequestLeave = widget.onRequestLeave;
    if (onRequestLeave == null) {
      if (mounted) await Navigator.of(context).maybePop();
      return;
    }
    if (_leaveBusy) return;
    final state = _controller.state;
    if (state.pendingLocation != null || state.courtFirstShotDraft != null) {
      final labels = _labels(context);
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(labels.pendingTitle),
          content: Text(labels.pendingBody),
          actions: [
            TextButton(
              key: const Key('leave-stay'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(labels.stay),
            ),
            FilledButton(
              key: const Key('leave-cancel-pending'),
              onPressed: () {
                final cancelled = state.pendingLocation != null
                    ? _controller.cancelLocateLastUnlocatedShot()
                    : _controller.cancelCourtFirstShot();
                if (cancelled) Navigator.of(dialogContext).pop(true);
              },
              child: Text(labels.cancelAndLeave),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    _leaveBusy = true;
    try {
      await onRequestLeave();
    } finally {
      if (mounted) setState(() => _leaveBusy = false);
    }
  }

  Future<void> _showMore() async {
    final labels = _labels(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        String? inlineFailure;
        Future<bool> Function()? inlineRetry;

        return StatefulBuilder(
          builder: (sheetBuilderContext, setSheetState) {
            Future<bool> runMore(Future<bool> Function() action) async {
              try {
                final accepted = await action();
                if (accepted && mounted) {
                  Navigator.of(context).pop();
                }
                return accepted;
              } on _MoreActionFailure catch (failure) {
                setSheetState(() {
                  inlineFailure = failure.message;
                  inlineRetry = failure.retry;
                });
                return false;
              }
            }

            return SafeArea(
              child: Material(
                key: const Key('scoring-more-sheet'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 620),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              labels.more,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              key: const Key('more-close'),
                              tooltip: labels.cancel,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        if (inlineFailure != null)
                          Container(
                            key: const Key('more-inline-error'),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                sheetBuilderContext,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(inlineFailure!)),
                                OutlinedButton(
                                  key: const Key('more-inline-retry'),
                                  onPressed: inlineRetry == null
                                      ? null
                                      : () => unawaited(runMore(inlineRetry!)),
                                  child: Text(labels.retry),
                                ),
                              ],
                            ),
                          ),
                        _moreHeading(labels.shots),
                        _moreAction(
                          key: const Key('more-blue-miss'),
                          icon: Icons.close,
                          label: labels.missed(TeamSide.blue),
                          enabled:
                              _controller.courtFirstShotDraft != null ||
                              _controller.state.pendingLocation == null,
                          onTap: () => runMore(
                            () => _recordMiss(
                              TeamSide.blue,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreAction(
                          key: const Key('more-red-miss'),
                          icon: Icons.close,
                          label: labels.missed(TeamSide.red),
                          enabled:
                              _controller.courtFirstShotDraft != null ||
                              _controller.state.pendingLocation == null,
                          onTap: () => runMore(
                            () =>
                                _recordMiss(TeamSide.red, rethrowFailure: true),
                          ),
                        ),
                        _moreHeading(labels.freeThrows),
                        _moreAction(
                          key: const Key('more-blue-free-throw-made'),
                          icon: Icons.check,
                          label: labels.freeThrow(TeamSide.blue, true),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordFreeThrow(
                              TeamSide.blue,
                              true,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreAction(
                          key: const Key('more-blue-free-throw-miss'),
                          icon: Icons.close,
                          label: labels.freeThrow(TeamSide.blue, false),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordFreeThrow(
                              TeamSide.blue,
                              false,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreAction(
                          key: const Key('more-red-free-throw-made'),
                          icon: Icons.check,
                          label: labels.freeThrow(TeamSide.red, true),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordFreeThrow(
                              TeamSide.red,
                              true,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreAction(
                          key: const Key('more-red-free-throw-miss'),
                          icon: Icons.close,
                          label: labels.freeThrow(TeamSide.red, false),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordFreeThrow(
                              TeamSide.red,
                              false,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreHeading(labels.matchStatus),
                        _moreAction(
                          key: const Key('more-possession-blue'),
                          icon: Icons.swap_horiz,
                          label: labels.possession(TeamSide.blue),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordPossession(
                              TeamSide.blue,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        _moreAction(
                          key: const Key('more-possession-red'),
                          icon: Icons.swap_horiz,
                          label: labels.possession(TeamSide.red),
                          enabled: _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _recordPossession(
                              TeamSide.red,
                              rethrowFailure: true,
                            ),
                          ),
                        ),
                        if (_controller.timerEnabled) ...[
                          _moreAction(
                            key: const Key('more-pause'),
                            icon: Icons.pause,
                            label: labels.pause,
                            enabled: _ordinaryActionsEnabled,
                            onTap: () =>
                                runMore(() => _pause(rethrowFailure: true)),
                          ),
                          _moreAction(
                            key: const Key('more-resume'),
                            icon: Icons.play_arrow,
                            label: labels.resume,
                            enabled: _ordinaryActionsEnabled,
                            onTap: () =>
                                runMore(() => _resume(rethrowFailure: true)),
                          ),
                        ],
                        _moreHeading(labels.records),
                        _moreAction(
                          key: const Key('more-note'),
                          icon: Icons.notes,
                          label: labels.note,
                          enabled: _ordinaryActionsEnabled,
                          onTap: () =>
                              runMore(() => _enterNote(rethrowFailure: true)),
                        ),
                        _moreAction(
                          key: const Key('more-custom'),
                          icon: Icons.add_circle_outline,
                          label: labels.custom,
                          enabled: _ordinaryActionsEnabled,
                          onTap: () =>
                              runMore(() => _enterCustom(rethrowFailure: true)),
                        ),
                        _moreHeading(labels.match),
                        _moreAction(
                          key: const Key('more-replay'),
                          icon: Icons.query_stats,
                          label: labels.replay,
                          enabled:
                              widget.onOpenReplay != null &&
                              _ordinaryActionsEnabled,
                          onTap: () => runMore(() async => _openReplay()),
                        ),
                        _moreAction(
                          key: const Key('more-finish'),
                          icon: Icons.flag,
                          label: labels.finish,
                          enabled:
                              widget.onFinishDecision != null &&
                              _controller.state.decision?.canFinish == true &&
                              _ordinaryActionsEnabled,
                          onTap: () => runMore(
                            () => _confirmFinishDecision(rethrowFailure: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool get _ordinaryActionsEnabled =>
      _controller.state.pendingLocation == null &&
      _controller.state.courtFirstShotDraft == null;

  Widget _moreHeading(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 2),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );

  Widget _moreAction({
    required Key key,
    required IconData icon,
    required String label,
    required bool enabled,
    required Future<bool> Function() onTap,
  }) {
    return ListTile(
      key: key,
      enabled: enabled,
      minTileHeight: 48,
      leading: Icon(icon),
      title: Text(label),
      onTap: enabled ? () => unawaited(onTap()) : null,
    );
  }

  Future<bool> _pause({bool rethrowFailure = false}) async {
    try {
      final accepted = await _controller.pauseCommitted();
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<bool> _resume({bool rethrowFailure = false}) async {
    try {
      final accepted = await _controller.resumeCommitted();
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<bool> _enterNote({bool rethrowFailure = false}) async {
    final labels = _labels(context);
    final note = await _showTextEntry(
      title: labels.note,
      hint: labels.noteHint,
      confirm: labels.recordNote,
    );
    if (note == null) return false;
    try {
      final accepted = await _controller.recordNoteCommitted(note);
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<bool> _enterCustom({bool rethrowFailure = false}) async {
    final labels = _labels(context);
    final label = await _showTextEntry(
      title: labels.custom,
      hint: labels.eventLabel,
      confirm: labels.recordEvent,
    );
    if (label == null) return false;
    try {
      final accepted = await _controller.recordCustomCommitted(label: label);
      if (accepted) _notifyCommitted();
      return accepted;
    } on MatchCommandFailure catch (failure) {
      if (rethrowFailure) throw _moreFailure(failure);
      _showCommandFailure(failure);
      return false;
    }
  }

  Future<String?> _showTextEntry({
    required String title,
    required String hint,
    required String confirm,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _TextEntryDialog(
        title: title,
        hint: hint,
        confirm: confirm,
        cancel: _labels(dialogContext).cancel,
      ),
    );
  }

  Future<void> _continueDecision() async {
    final action = widget.onContinueDecision;
    if (action == null || _decisionBusy) return;
    setState(() => _decisionBusy = true);
    try {
      await action();
      _notifyCommitted();
    } finally {
      if (mounted) setState(() => _decisionBusy = false);
    }
  }

  Future<bool> _confirmFinishDecision({bool rethrowFailure = false}) async {
    final finish = widget.onFinishDecision;
    final decision = _controller.state.decision;
    if (finish == null ||
        decision == null ||
        !decision.canFinish ||
        _decisionBusy) {
      return false;
    }
    final state = _controller.state;
    final l10n = _localizations(context);
    final failureMessage = _labels(context).failureRetry;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmFinalScoreTitle),
        content: Text(
          l10n.finalScoreLine(
            state.blueName,
            decision.blueScore,
            state.redName,
            decision.redScore,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('scoring-finish-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            key: const Key('scoring-finish-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.finishMatch),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    setState(() => _decisionBusy = true);
    try {
      await finish(decision.redScore, decision.blueScore);
      _notifyCommitted();
      return true;
    } on Object {
      if (rethrowFailure) {
        throw _MoreActionFailure(
          message: failureMessage,
          retry: () => _finishDecisionWithoutConfirmation(
            finish: finish,
            decision: decision,
            rethrowFailure: true,
          ),
        );
      }
      _showActionRejected(failureMessage);
      return false;
    } finally {
      if (mounted) setState(() => _decisionBusy = false);
    }
  }

  Future<bool> _finishDecisionWithoutConfirmation({
    required Future<void> Function(int redScore, int blueScore) finish,
    required MatchDecision decision,
    required bool rethrowFailure,
  }) async {
    final failureMessage = _labels(context).failureRetry;
    setState(() => _decisionBusy = true);
    try {
      await finish(decision.redScore, decision.blueScore);
      _notifyCommitted();
      return true;
    } on Object {
      if (rethrowFailure) {
        throw _MoreActionFailure(
          message: failureMessage,
          retry: () => _finishDecisionWithoutConfirmation(
            finish: finish,
            decision: decision,
            rethrowFailure: true,
          ),
        );
      }
      _showActionRejected(failureMessage);
      return false;
    } finally {
      if (mounted) setState(() => _decisionBusy = false);
    }
  }

  bool _openReplay() {
    if (_controller.state.pendingLocation != null ||
        _controller.state.courtFirstShotDraft != null ||
        _controller.state.locationSupplementWindow != null) {
      _showActionRejected(_localizations(context).scoringResolvePending);
      return false;
    }
    widget.onOpenReplay?.call();
    return widget.onOpenReplay != null;
  }

  void _notifyCommitted() {
    final callback = widget.onActionCommitted;
    if (callback != null) unawaited(Future<void>.sync(callback));
  }

  AppLocalizations _localizations(BuildContext context) =>
      AppLocalizations.of(context) ?? AppLocalizationsZh();

  String _localizedHint(AppLocalizations l10n, RuleHint hint) {
    return switch (hint.messageKey) {
      'targetReached' => l10n.ruleTargetReached,
      'winByTwoRequired' => l10n.ruleWinByTwoRequired,
      'matchPoint' => l10n.ruleMatchPoint,
      'possessionChange' when hint.suggestedSide != null =>
        '${_localizedSide(l10n, hint.suggestedSide!)}${l10n.rulePossessionSuggested}',
      'possessionChange' => l10n.rulePossessionSuggested,
      _ => hint.message,
    };
  }

  String _localizedSide(AppLocalizations l10n, TeamSide side) {
    return side == TeamSide.blue ? l10n.pregameBlue : l10n.pregameRed;
  }

  void _showActionRejected(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('scoring-action-rejected'),
        content: Text(message),
      ),
    );
  }

  void _showCommandFailure(MatchCommandFailure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_labels(context).failureRetry),
          action: failure.canRetry
              ? SnackBarAction(
                  label: _labels(context).retry,
                  onPressed: () => unawaited(_retryCommand(failure)),
                )
              : null,
        ),
      );
  }

  Future<void> _retryCommand(MatchCommandFailure failure) async {
    try {
      final accepted = await _controller.retryCommand(failure);
      if (accepted) {
        if (_controller.courtFirstShotDraft != null) {
          _controller.cancelCourtFirstShot();
        }
        _notifyCommitted();
      }
    } on MatchCommandFailure catch (nextFailure) {
      _showCommandFailure(nextFailure);
    }
  }

  _MoreActionFailure _moreFailure(MatchCommandFailure failure) =>
      _MoreActionFailure(
        message: _labels(context).failureRetry,
        retry: () => _retryMoreCommand(failure),
      );

  Future<bool> _retryMoreCommand(MatchCommandFailure failure) async {
    try {
      final accepted = await _controller.retryCommand(failure);
      if (accepted) {
        if (_controller.courtFirstShotDraft != null) {
          _controller.cancelCourtFirstShot();
        }
        _notifyCommitted();
      }
      return accepted;
    } on MatchCommandFailure catch (nextFailure) {
      throw _moreFailure(nextFailure);
    }
  }

  _ScoringLabels _labels(BuildContext context) =>
      _ScoringLabels(_localizations(context));
}

class _MoreActionFailure implements Exception {
  const _MoreActionFailure({required this.message, required this.retry});

  final String message;
  final Future<bool> Function() retry;
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.state,
    required this.clock,
    required this.onLeave,
    required this.onUndo,
    required this.onMore,
    required this.labels,
  });

  final MatchScoringState state;
  final ClockProjection? clock;
  final VoidCallback onLeave;
  final VoidCallback onUndo;
  final VoidCallback onMore;
  final _ScoringLabels labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blue = teamColorForScheme(
      TeamSide.blue,
      scheme,
      background: HoopTraceColors.ink,
    );
    final red = teamColorForScheme(
      TeamSide.red,
      scheme,
      background: HoopTraceColors.ink,
    );
    final compact = MediaQuery.sizeOf(context).width < 600;
    final clockLabel = clock == null
        ? labels.noTimer
        : '${clock!.phase == ClockPhase.overtime ? '${labels.l10n.scoringOvertime} ' : ''}${_formatSeconds(clock!.displaySeconds)}';
    final status = clock == null
        ? labels.timerNotConfigured
        : clock!.isRegulationExpired
        ? labels.regulationExpired
        : clock!.isRunning
        ? labels.clockRunning
        : labels.clockPaused;
    Widget action({
      required Key key,
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onPressed,
        color: Colors.white,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(icon),
      );
    }

    return Material(
      key: const Key('scoring-scoreboard'),
      color: HoopTraceColors.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            action(
              key: const Key('scoring-leave'),
              tooltip: labels.back,
              icon: Icons.arrow_back,
              onPressed: onLeave,
            ),
            Expanded(
              child: _ScoreLabel(
                name: state.blueName,
                score: state.score.blueScore,
                color: blue,
                alignment: Alignment.centerLeft,
              ),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 88 : 180),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          clockLabel,
                          maxLines: 1,
                          semanticsLabel: labels.matchTime(clockLabel),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                      if (!compact)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            status,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _ScoreLabel(
                name: state.redName,
                score: state.score.redScore,
                color: red,
                alignment: Alignment.centerRight,
              ),
            ),
            action(
              key: const Key('scoring-undo'),
              tooltip: labels.undo,
              icon: Icons.undo,
              onPressed: onUndo,
            ),
            action(
              key: const Key('scoring-more'),
              tooltip: labels.more,
              icon: Icons.more_vert,
              onPressed: onMore,
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
    final label = alignment == Alignment.centerLeft
        ? '$name $score'
        : '$score $name';
    return Semantics(
      label: label,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({
    required this.title,
    required this.hint,
    required this.confirm,
    required this.cancel,
  });
  final String title;
  final String hint;
  final String confirm;
  final String cancel;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  late final TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('text-entry-field'),
        controller: _editingController,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          key: const Key('text-entry-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancel),
        ),
        FilledButton(
          key: const Key('text-entry-confirm'),
          onPressed: () =>
              Navigator.of(context).pop(_editingController.text.trim()),
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}

class _ScoringLabels {
  _ScoringLabels(this.l10n);

  final AppLocalizations l10n;
  String get back => l10n.scoringBackToScoringList;
  String get undo => l10n.scoringUndo;
  String get more => l10n.scoringMore;
  String get noTimer => l10n.scoringNoTimer;
  String get timerNotConfigured => l10n.scoringTimerNotConfigured;
  String get clockRunning => l10n.scoringClockRunning;
  String get clockPaused => l10n.scoringClockPaused;
  String get regulationExpired => l10n.scoringRegulationExpired;
  String get shots => l10n.scoringShotsGroup;
  String get freeThrows => l10n.scoringFreeThrowsGroup;
  String get matchStatus => l10n.scoringMatchStatusGroup;
  String get records => l10n.scoringRecordsGroup;
  String get match => l10n.scoringMatchGroup;
  String get note => l10n.scoringNote;
  String get custom => l10n.scoringCustom;
  String get pause => l10n.scoringPause;
  String get resume => l10n.scoringResume;
  String get replay => l10n.scoringReplay;
  String get finish => l10n.finishMatch;
  String get chooseScoringSide => l10n.scoringChooseScoringSide;
  String get supplementExpired => l10n.scoringSupplementExpired;
  String get actionRejected => l10n.scoringActionRejected;
  String get failureRetry => l10n.actionFailedRetry;
  String get retry => l10n.historyRetry;
  String get cancel => l10n.cancelAction;
  String get stay => l10n.scoringStay;
  String get cancelAndLeave => l10n.scoringCancelLocationLeave;
  String get pendingTitle => l10n.scoringPendingLocationTitle;
  String get pendingBody => l10n.scoringPendingLocationBody;
  String get noteHint => l10n.scoringNoteHint;
  String get recordNote => l10n.scoringRecordNote;
  String get eventLabel => l10n.scoringEventLabel;
  String get recordEvent => l10n.scoringRecordEvent;
  String sideName(TeamSide side) =>
      side == TeamSide.blue ? l10n.pregameBlue : l10n.pregameRed;
  String missed(TeamSide side) => '${sideName(side)} ${l10n.scoringMissed}';
  String freeThrow(TeamSide side, bool made) {
    return switch ((side, made)) {
      (TeamSide.blue, true) => l10n.scoringBlueFreeThrowMade,
      (TeamSide.blue, false) => l10n.scoringBlueFreeThrowMissed,
      (TeamSide.red, true) => l10n.scoringRedFreeThrowMade,
      (TeamSide.red, false) => l10n.scoringRedFreeThrowMissed,
    };
  }

  String possession(TeamSide side) => side == TeamSide.blue
      ? l10n.scoringPossessionBlue
      : l10n.scoringPossessionRed;
  String supplementPrompt(String side, int points, int seconds) =>
      l10n.scoringSupplementPrompt(points, seconds, side);
  String matchTime(String value) => l10n.scoringMatchTime(value);
}

String _formatSeconds(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  return '${(safe ~/ 60).toString().padLeft(2, '0')}:${(safe % 60).toString().padLeft(2, '0')}';
}
