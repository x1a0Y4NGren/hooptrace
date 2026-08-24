import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';
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
    if (widget.clockTick <= Duration.zero || !_controller.timerEnabled) return;
    _clockTicker = Timer.periodic(widget.clockTick, (_) {
      if (mounted && _controller.timerEnabled && _controller.clock != null) {
        setState(() {});
      }
    });
  }

  DateTime _nowUtc() => (widget.clockNowUtc?.call() ?? DateTime.now()).toUtc();

  ClockProjection? _displayClock() {
    if (!_controller.timerEnabled) return null;
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
                Expanded(
                  child: IgnorePointer(
                    ignoring: state.decision != null,
                    child: _buildWorkspace(context, constraints, state),
                  ),
                ),
                if (state.ruleHints.isNotEmpty || state.ruleWarnings.isNotEmpty)
                  _buildRuleHints(context, state),
                if (state.pendingLocation != null)
                  _buildPendingLocationDock()
                else if (state.detailedShotDraft != null)
                  _buildDetailedDraftDock(
                    context,
                    state,
                    constraints.maxWidth < 640,
                  )
                else if (state.decision != null)
                  _buildDecisionDock(context, state)
                else
                  _buildCommandDock(
                    context,
                    state,
                    clock,
                    constraints.maxWidth < 640,
                  ),
              ],
            );
          },
        ),
      ),
    );
    final onRequestLeave = widget.onRequestLeave;
    if (onRequestLeave == null) return page;
    // PopScope(canPop: false) is intentional: the synchronous guard keeps an
    // unfinished shot from leaving before stay/cancel/commit is chosen.
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
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final sideWidth = constraints.maxWidth < 640
        ? (constraints.maxWidth * (largeText ? 0.24 : 0.22)).clamp(
            largeText ? 96.0 : 88.0,
            largeText ? 148.0 : 132.0,
          )
        : (constraints.maxWidth * 0.2).clamp(
            largeText ? 144.0 : 132.0,
            largeText ? 204.0 : 188.0,
          );
    return Row(
      children: [
        SizedBox(
          width: sideWidth,
          child: _buildSidePanel(context, state, TeamSide.blue),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CourtView(
              key: const Key('scoring-court'),
              shotLocations: state.shotLocations,
              pendingLocation: state.pendingLocation,
              detailedShotDraft: state.detailedShotDraft,
              onPendingLocationChanged: _controller.updatePendingLocation,
              onCourtPointTap: _handleCourtPoint,
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
          Flexible(
            child: Text(
              messages.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionDock(BuildContext context, MatchScoringState state) {
    final decision = state.decision!;
    final l10n = _localizations(context);
    final summary = Row(
      children: [
        const Icon(Icons.sports_score),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localizedDecision(l10n, decision),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.finalScoreLine(
                  state.blueName,
                  decision.blueScore,
                  state.redName,
                  decision.redScore,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ],
    );
    final actions = <Widget>[
      if (decision.canContinue && widget.onContinueDecision != null)
        OutlinedButton(
          key: const Key('scoring-decision-continue'),
          onPressed: _decisionBusy ? null : _continueDecision,
          child: Text(l10n.continueMatch),
        ),
      if (decision.canFinish && widget.onFinishDecision != null) ...[
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('scoring-decision-finish'),
          onPressed: _decisionBusy ? null : _confirmFinishDecision,
          child: Text(l10n.finishMatch),
        ),
      ],
    ];
    return Container(
      key: const Key('scoring-decision-dock'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                summary,
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 12),
              ...actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingLocationDock() {
    return PendingLocationBar(
      key: const Key('pending-location-dock'),
      onConfirm: () => unawaited(_confirmPendingLocation()),
      onSkip: _cancelPendingLocation,
      onUndo: () => unawaited(_undoPendingEvent()),
    );
  }

  Widget _buildDetailedDraftDock(
    BuildContext context,
    MatchScoringState state,
    bool compact,
  ) {
    final l10n = _localizations(context);
    final draft = state.detailedShotDraft!;
    final selectors = <Widget>[
      Text(
        draft.outcome == ShotOutcome.missed
            ? l10n.scoringMissed
            : l10n.scoringPoints(draft.points),
        semanticsLabel: l10n.scoringSubmitShot,
      ),
      _DockAction(
        key: const Key('draft-shooter-blue'),
        label: l10n.scoringSimpleBlueShot,
        icon: Icons.person,
        selected: draft.side == TeamSide.blue,
        onPressed: () => _controller.updateDetailedShot(side: TeamSide.blue),
      ),
      _DockAction(
        key: const Key('draft-shooter-red'),
        label: l10n.scoringSimpleRedShot,
        icon: Icons.person,
        selected: draft.side == TeamSide.red,
        onPressed: () => _controller.updateDetailedShot(side: TeamSide.red),
      ),
      _DockAction(
        key: const Key('draft-outcome-made'),
        label: l10n.scoringMade,
        icon: Icons.check,
        selected: draft.outcome == ShotOutcome.made,
        onPressed: () =>
            _controller.updateDetailedShot(outcome: ShotOutcome.made),
      ),
      _DockAction(
        key: const Key('draft-outcome-missed'),
        label: l10n.scoringMissed,
        icon: Icons.close,
        selected: draft.outcome == ShotOutcome.missed,
        onPressed: () =>
            _controller.updateDetailedShot(outcome: ShotOutcome.missed),
      ),
      for (final point in state.ruleTemplate.scoreButtons)
        _DockAction(
          key: Key('draft-points-$point'),
          label: l10n.scoringPoints(point),
          onPressed: () => _controller.updateDetailedShot(points: point),
        ),
    ];
    final actions = <Widget>[
      _DockAction(
        key: const Key('draft-cancel'),
        label: l10n.scoringCancelDraft,
        icon: Icons.undo,
        onPressed: _cancelDetailedShot,
      ),
      _DockAction(
        key: const Key('draft-commit'),
        label: l10n.scoringSubmitShot,
        icon: Icons.check_circle,
        emphasized: true,
        onPressed: () => unawaited(_commitDetailedShot()),
      ),
    ];
    return _DockSurface(
      key: const Key('detailed-draft-dock'),
      color: Theme.of(context).colorScheme.surfaceContainer,
      maxHeight: compact ? 64 : 154,
      child: compact
          ? Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final selector in selectors) ...[
                          selector,
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: 6),
                  action,
                ],
              ],
            )
          : SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [...selectors, ...actions],
              ),
            ),
    );
  }

  Widget _buildCommandDock(
    BuildContext context,
    MatchScoringState state,
    ClockProjection? clock,
    bool compact,
  ) {
    final l10n = _localizations(context);
    final canLocate =
        state.recordingMode == RecordingMode.simple && _allowsLocations;
    final activeClock = clock;
    final showClockActions = state.timerEnabled && activeClock != null;
    final showPause = state.timerEnabled && activeClock?.isRunning == true;
    final showResume =
        state.timerEnabled &&
        activeClock != null &&
        !activeClock.isRunning &&
        !activeClock.isRegulationExpired;
    final actions = <Widget>[
      _DockAction(
        key: const Key('command-undo'),
        label: l10n.scoringUndo,
        icon: Icons.undo,
        onPressed: () => unawaited(_undoLastEvent()),
      ),
      if (canLocate)
        _DockAction(
          key: const Key('command-locate'),
          label: l10n.scoringLocateLastShot,
          icon: Icons.location_on_outlined,
          onPressed: _beginLocate,
        ),
      if (showPause)
        _DockAction(
          key: const Key('command-pause'),
          label: l10n.scoringPause,
          icon: Icons.pause,
          onPressed: () => unawaited(_pause()),
        ),
      if (showResume)
        _DockAction(
          key: const Key('command-resume'),
          label: l10n.scoringResume,
          icon: Icons.play_arrow,
          onPressed: () => unawaited(_resume()),
        ),
      _DockAction(
        key: const Key('command-free-throw-blue-made'),
        label: l10n.scoringBlueFreeThrowMade,
        onPressed: () => unawaited(_recordFreeThrow(TeamSide.blue, true)),
      ),
      if (_allowsShotAttempts)
        _DockAction(
          key: const Key('command-free-throw-blue-miss'),
          label: l10n.scoringBlueFreeThrowMissed,
          onPressed: () => unawaited(_recordFreeThrow(TeamSide.blue, false)),
        ),
      _DockAction(
        key: const Key('command-free-throw-red-made'),
        label: l10n.scoringRedFreeThrowMade,
        onPressed: () => unawaited(_recordFreeThrow(TeamSide.red, true)),
      ),
      if (_allowsShotAttempts)
        _DockAction(
          key: const Key('command-free-throw-red-miss'),
          label: l10n.scoringRedFreeThrowMissed,
          onPressed: () => unawaited(_recordFreeThrow(TeamSide.red, false)),
        ),
      _DockAction(
        key: const Key('command-possession-blue'),
        label: l10n.scoringPossessionBlue,
        selected: state.currentPossession == TeamSide.blue,
        onPressed: () => unawaited(_recordPossession(TeamSide.blue)),
      ),
      _DockAction(
        key: const Key('command-possession-red'),
        label: l10n.scoringPossessionRed,
        selected: state.currentPossession == TeamSide.red,
        onPressed: () => unawaited(_recordPossession(TeamSide.red)),
      ),
      _DockAction(
        key: const Key('command-note'),
        label: l10n.scoringNote,
        icon: Icons.notes,
        onPressed: () => unawaited(_enterNote()),
      ),
      _DockAction(
        key: const Key('command-custom'),
        label: l10n.scoringCustom,
        icon: Icons.add_circle_outline,
        onPressed: () => unawaited(_enterCustom()),
      ),
      if (showClockActions)
        Text(
          activeClock.isRunning
              ? l10n.scoringClockRunning
              : _clockStatus(activeClock, l10n),
          semanticsLabel: l10n.scoringClockStatus(
            _clockStatus(activeClock, l10n),
          ),
        ),
    ];
    return _DockSurface(
      key: const Key('scoring-command-dock'),
      maxHeight: compact ? 64 : 154,
      child: compact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final action in actions) ...[
                    action,
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: actions,
              ),
            ),
    );
  }

  Future<void> _requestLeave() async {
    final l10n = _localizations(context);
    final onRequestLeave = widget.onRequestLeave;
    if (onRequestLeave == null || _leaveBusy) return;

    final state = _controller.state;
    if (state.pendingLocation != null || state.detailedShotDraft != null) {
      final hasPending = state.pendingLocation != null;
      final decision = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            hasPending
                ? l10n.scoringPendingLocationTitle
                : l10n.scoringPendingDraftTitle,
          ),
          content: Text(
            hasPending
                ? l10n.scoringPendingLocationBody
                : l10n.scoringPendingDraftBody,
          ),
          actions: [
            TextButton(
              key: const Key('leave-stay'),
              onPressed: () => Navigator.of(context).pop('stay'),
              child: Text(l10n.scoringStay),
            ),
            if (hasPending)
              TextButton(
                key: const Key('leave-cancel-pending'),
                onPressed: () {
                  if (_controller.cancelLocateLastUnlocatedShot()) {
                    Navigator.of(context).pop('leave');
                  }
                },
                child: Text(l10n.scoringCancelLocationLeave),
              )
            else ...[
              TextButton(
                key: const Key('leave-cancel-draft'),
                onPressed: () {
                  if (_controller.cancelDetailedShot()) {
                    Navigator.of(context).pop('leave');
                  }
                },
                child: Text(l10n.scoringCancelDraftLeave),
              ),
              FilledButton(
                key: const Key('leave-commit-draft'),
                onPressed: () async {
                  final accepted = await _controller.commitDetailedShot();
                  if (context.mounted) {
                    Navigator.of(context).pop(accepted ? 'leave' : 'stay');
                  }
                },
                child: Text(l10n.scoringSubmitLeave),
              ),
            ],
          ],
        ),
      );
      if (decision != 'leave' || !mounted) return;
    }
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
      _showActionRejected(_localizations(context).scoringDraftCreateFailed);
    }
  }

  Future<void> _recordScore(TeamSide side, int points) async {
    final l10n = _localizations(context);
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

  Future<void> _recordMiss(TeamSide side) async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.recordMissCommitted(side: side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringMissTrackingDisabled);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordFoul(TeamSide side) async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.recordFoulCommitted(side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringActionRejected);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordFreeThrow(TeamSide side, bool made) async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.recordFreeThrowCommitted(
        side: side,
        made: made,
      );
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringFreeThrowTrackingDisabled);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _recordPossession(TeamSide side) async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.recordPossessionCommitted(side);
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringPossessionNotCommitted);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  bool _beginLocate() {
    final accepted = _controller.beginLocateLastUnlocatedShot();
    if (!accepted) {
      _showActionRejected(_localizations(context).scoringNoUnlocatedShot);
    }
    return accepted;
  }

  void _cancelPendingLocation() {
    if (!_controller.cancelLocateLastUnlocatedShot()) {
      _showActionRejected(_localizations(context).scoringLocationCancelFailed);
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
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.undoLastEventCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringUndoFailed);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _pause() async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.pauseCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringPauseFailed);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _resume() async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.resumeCommitted();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringResumeFailed);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  Future<void> _commitDetailedShot() async {
    final l10n = _localizations(context);
    try {
      final accepted = await _controller.commitDetailedShot();
      if (accepted) {
        _notifyCommitted();
      } else {
        _showActionRejected(l10n.scoringDraftIncomplete);
      }
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    }
  }

  void _cancelDetailedShot() {
    if (!_controller.cancelDetailedShot()) {
      _showActionRejected(_localizations(context).scoringNoDraft);
    }
  }

  Future<void> _enterNote() async {
    final note = await _showTextEntry(
      title: _localizations(context).scoringAddNote,
      hint: _localizations(context).scoringNoteHint,
      confirm: _localizations(context).scoringRecordNote,
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
      title: _localizations(context).scoringRecordCustom,
      hint: _localizations(context).scoringEventLabel,
      confirm: _localizations(context).scoringRecordEvent,
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
              child: Text(_localizations(context).cancelAction),
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

  Future<void> _continueDecision() {
    return _runDecision(widget.onContinueDecision);
  }

  Future<void> _confirmFinishDecision() async {
    final finish = widget.onFinishDecision;
    if (_decisionBusy || finish == null) return;
    final state = _controller.state;
    final decision = state.decision;
    if (decision == null || !decision.canFinish) return;
    final confirmedRedScore = decision.redScore;
    final confirmedBlueScore = decision.blueScore;
    final l10n = _localizations(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmFinalScoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finalScoreLine(
                state.blueName,
                decision.blueScore,
                state.redName,
                decision.redScore,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.confirmFinalScoreBody),
          ],
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
    if (confirmed == true && mounted) {
      await _runDecision(() => finish(confirmedRedScore, confirmedBlueScore));
    }
  }

  Future<void> _runDecision(Future<void> Function()? action) async {
    if (_decisionBusy || action == null) return;
    final failureMessage = _localizations(context).actionFailedRetry;
    setState(() => _decisionBusy = true);
    try {
      await action();
      _notifyCommitted();
    } on MatchCommandFailure catch (failure) {
      _showCommandFailure(failure);
    } on Object {
      _showActionRejected(failureMessage);
    } finally {
      if (mounted) setState(() => _decisionBusy = false);
    }
  }

  AppLocalizations _localizations(BuildContext context) {
    return AppLocalizations.of(context) ?? AppLocalizationsZh();
  }

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

  String _localizedDecision(AppLocalizations l10n, MatchDecision decision) {
    return switch (decision.reason) {
      MatchDecisionReason.targetReached => l10n.ruleTargetReached,
      MatchDecisionReason.winByTwoRequired => l10n.ruleWinByTwoRequired,
      MatchDecisionReason.regulationExpired => l10n.finishOrContinueOvertime,
    };
  }

  String _localizedSide(AppLocalizations l10n, TeamSide side) {
    final isChinese = l10n.localeName.toLowerCase().startsWith('zh');
    return switch (side) {
      TeamSide.red => isChinese ? '红方' : 'Red ',
      TeamSide.blue => isChinese ? '蓝方' : 'Blue ',
    };
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_localizations(context).actionFailedRetry),
        action: failure.canRetry
            ? SnackBarAction(
                label: _localizations(context).retryAction,
                onPressed: () => unawaited(_retryCommand(failure)),
              )
            : null,
      ),
    );
  }

  Future<void> _retryCommand(MatchCommandFailure failure) async {
    try {
      final accepted = await _controller.retryCommand(failure);
      if (accepted) _notifyCommitted();
    } on MatchCommandFailure catch (nextFailure) {
      _showCommandFailure(nextFailure);
    }
  }

  void _openReplay() {
    if (_controller.state.pendingLocation != null ||
        _controller.state.detailedShotDraft != null) {
      _showActionRejected(_localizations(context).scoringResolvePending);
      return;
    }
    widget.onOpenReplay?.call();
  }

  bool get _allowsShotAttempts =>
      _controller.trackingCoverage.index >= TrackingCoverage.shotAttempts.index;

  bool get _allowsLocations =>
      _controller.trackingCoverage.index >= TrackingCoverage.locations.index;

  String _clockStatus(ClockProjection clock, AppLocalizations l10n) {
    if (clock.isRegulationExpired) return l10n.scoringRegulationExpired;
    if (clock.phase == ClockPhase.overtime) return l10n.scoringOvertime;
    return clock.isRunning ? l10n.scoringClockRunning : l10n.scoringClockPaused;
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final clockLabel = clock == null
        ? l10n.scoringNoTimer
        : '${clock!.phase == ClockPhase.overtime ? 'OT ' : ''}${_formatSeconds(clock!.displaySeconds)}';
    final clockStatus = clock == null
        ? l10n.scoringTimerNotConfigured
        : clock!.phase == ClockPhase.overtime
        ? l10n.scoringOvertime
        : clock!.isRegulationExpired
        ? l10n.scoringRegulationExpired
        : clock!.isRunning
        ? l10n.scoringClockRunning
        : l10n.scoringClockPaused;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 600 ||
            (MediaQuery.textScalerOf(context).scale(1) >= 1.5 &&
                constraints.maxWidth < 720);
        final colorScheme = Theme.of(context).colorScheme;
        final blueColor = teamColorForScheme(
          TeamSide.blue,
          colorScheme,
          background: HoopTraceColors.ink,
        );
        final redColor = teamColorForScheme(
          TeamSide.red,
          colorScheme,
          background: HoopTraceColors.ink,
        );

        Widget iconAction({
          required Key key,
          required String tooltip,
          required IconData icon,
          required VoidCallback? onPressed,
        }) {
          return IconButton(
            key: key,
            tooltip: tooltip,
            color: Colors.white,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onPressed,
            icon: Icon(icon),
          );
        }

        final clock = SizedBox(
          width: compact ? 62 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  clockLabel,
                  maxLines: 1,
                  semanticsLabel: l10n.scoringMatchTime(clockLabel),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!compact)
                Text(
                  clockStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
            ],
          ),
        );

        return Material(
          key: const Key('scoring-scoreboard'),
          color: HoopTraceColors.ink,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: compact
                ? Row(
                    children: [
                      if (onLeave != null)
                        iconAction(
                          key: const Key('scoring-leave'),
                          tooltip: l10n.scoringBackToScoringList,
                          icon: Icons.arrow_back,
                          onPressed: onLeave,
                        ),
                      Expanded(
                        child: _ScoreLabel(
                          name: state.blueName,
                          score: state.score.blueScore,
                          color: blueColor,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: clock,
                      ),
                      Expanded(
                        child: _ScoreLabel(
                          name: state.redName,
                          score: state.score.redScore,
                          color: redColor,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                      if (onReplay != null)
                        iconAction(
                          key: const Key('scoring-replay'),
                          tooltip: l10n.scoringReplay,
                          icon: Icons.query_stats,
                          onPressed: onReplay,
                        ),
                      if (onResumeClock != null)
                        iconAction(
                          key: scoringResumeClockKey,
                          tooltip: l10n.scoringResumeClock,
                          icon: Icons.play_arrow,
                          onPressed: onResumeClock,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      if (onLeave != null)
                        iconAction(
                          key: const Key('scoring-leave'),
                          tooltip: l10n.scoringBackToScoringList,
                          icon: Icons.arrow_back,
                          onPressed: onLeave,
                        ),
                      Expanded(
                        child: _ScoreLabel(
                          name: state.blueName,
                          score: state.score.blueScore,
                          color: blueColor,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: clock,
                      ),
                      Expanded(
                        child: _ScoreLabel(
                          name: state.redName,
                          score: state.score.redScore,
                          color: redColor,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                      if (onReplay != null)
                        Tooltip(
                          message: l10n.scoringReplay,
                          child: TextButton.icon(
                            key: const Key('scoring-replay'),
                            onPressed: onReplay,
                            icon: const Icon(
                              Icons.query_stats,
                              color: Colors.white,
                            ),
                            label: Text(l10n.scoringReplay),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (onResumeClock != null)
                        TextButton(
                          key: scoringResumeClockKey,
                          onPressed: onResumeClock,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.scoringResumeClock),
                        ),
                    ],
                  ),
          ),
        );
      },
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
  const _DockSurface({
    required this.child,
    this.color,
    this.maxHeight = 154,
    super.key,
  });

  final Widget child;
  final Color? color;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      elevation: 3,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
