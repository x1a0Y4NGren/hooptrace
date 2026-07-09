class CourtPoint {
  CourtPoint({
    required this.x,
    required this.y,
  }) {
    if (x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError('CourtPoint coordinates must be normalized.');
    }
  }

  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  static CourtPoint fromJson(Map<String, Object?> json) {
    return CourtPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}
