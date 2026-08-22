import 'package:flutter/material.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_painter.dart';

enum CourtViewMode { readOnly, editable }

CourtPoint pointFromLocal(Offset local, Size size) {
  return HalfCourtGeometry.pointFromLocal(local, size);
}

class CourtView extends StatelessWidget {
  const CourtView({
    required this.shotLocations,
    this.pendingLocation,
    this.onPendingLocationChanged,
    this.onShotLocationTap,
    this.mode = CourtViewMode.editable,
    super.key,
  });

  final List<ScoringShotLocation> shotLocations;
  final PendingShotLocation? pendingLocation;
  final ValueChanged<CourtPoint>? onPendingLocationChanged;
  final ValueChanged<String>? onShotLocationTap;
  final CourtViewMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        void handlePosition(Offset local) {
          if (mode == CourtViewMode.readOnly || pendingLocation == null) {
            return;
          }
          onPendingLocationChanged?.call(pointFromLocal(local, size));
        }

        void handleTap(Offset local) {
          if (mode == CourtViewMode.readOnly) return;
          if (pendingLocation != null) {
            handlePosition(local);
            return;
          }
          ScoringShotLocation? closest;
          var closestDistance = 28.0;
          for (final location in shotLocations) {
            final center = HalfCourtGeometry.pointToOffset(
              location.point,
              size,
            );
            final distance = (center - local).distance;
            if (distance <= closestDistance) {
              closest = location;
              closestDistance = distance;
            }
          }
          if (closest != null) onShotLocationTap?.call(closest.id);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => handleTap(details.localPosition),
          onPanUpdate: (details) => handlePosition(details.localPosition),
          child: CustomPaint(
            painter: CourtPainter(
              shotLocations: shotLocations,
              pendingLocation: pendingLocation,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
