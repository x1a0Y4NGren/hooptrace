enum TeamSide {
  red,
  blue;

  TeamSide get opponent => this == TeamSide.red ? TeamSide.blue : TeamSide.red;
}
