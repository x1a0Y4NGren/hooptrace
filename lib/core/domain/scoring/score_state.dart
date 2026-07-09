class ScoreState {
  const ScoreState({
    required this.redScore,
    required this.blueScore,
  });

  const ScoreState.zero()
      : redScore = 0,
        blueScore = 0;

  final int redScore;
  final int blueScore;
}
