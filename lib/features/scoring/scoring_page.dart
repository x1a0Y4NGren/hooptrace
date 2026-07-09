import 'package:flutter/material.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

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
  late final ScoringController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ScoringController(matchId: widget.matchId, setup: widget.setup);
    _ownsController = widget.controller == null;
    _controller.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
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
              child: Row(
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
            ),
            if (state.pendingLocation != null)
              PendingLocationBar(
                onConfirm: _controller.confirmPendingLocation,
                onSkip: _controller.skipPendingLocation,
                onUndo: _controller.undoLastEvent,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scoreAndAskLocation(TeamSide side, int points) async {
    if (_controller.state.pendingLocation != null) {
      return;
    }

    _controller.addScore(side: side, points: points);
    final markLocation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('标记投篮位置？'),
          content: const Text('可在球场上点选或拖动圆点后确认。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('不标记'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('标记'),
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
