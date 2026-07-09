import 'package:flutter/material.dart';
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

class ScoringPage extends StatefulWidget {
  const ScoringPage({
    this.matchId,
    this.setup,
    this.controller,
    super.key,
  }) : assert(matchId != null || setup != null || controller != null);

  final String? matchId;
  final MatchSetup? setup;
  final ScoringController? controller;

  @override
  State<ScoringPage> createState() => _ScoringPageState();
}

class _ScoringPageState extends State<ScoringPage> {
  late ScoringController _controller;
  bool _ownsController = false;

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
    _controller = widget.controller ??
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Text(
                    '${state.blueName} ${state.score.blueScore}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  const Text('00:00'),
                  const Spacer(),
                  Text(
                    '${state.score.redScore} ${state.redName}',
                    style: Theme.of(context).textTheme.titleLarge,
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
                          onFoul: () => _controller.addFoul(TeamSide.blue),
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
                          onFoul: () => _controller.addFoul(TeamSide.red),
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
                          onConfirm: _controller.confirmPendingLocation,
                          onSkip: _controller.skipPendingLocation,
                          onUndo: _controller.undoLastEvent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scoreAndAskLocation(TeamSide side, int points) async {
    final accepted = _controller.addScore(side: side, points: points);
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(scoringResolvePendingText)),
      );
      return;
    }

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
}
