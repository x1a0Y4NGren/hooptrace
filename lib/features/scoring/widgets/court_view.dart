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
    this.detailedShotDraft,
    this.onPendingLocationChanged,
    this.onCourtPointTap,
    this.onShotLocationTap,
    this.mode = CourtViewMode.editable,
    super.key,
  });

  final List<ScoringShotLocation> shotLocations;
  final PendingShotLocation? pendingLocation;
  final DetailedShotDraft? detailedShotDraft;
  final ValueChanged<CourtPoint>? onPendingLocationChanged;
  final ValueChanged<CourtPoint>? onCourtPointTap;
  final ValueChanged<String>? onShotLocationTap;
  final CourtViewMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        void handlePosition(Offset local) {
          if (mode == CourtViewMode.readOnly) {
            return;
          }
          final point = pointFromLocal(local, size);
          if (pendingLocation != null) {
            onPendingLocationChanged?.call(point);
          } else if (detailedShotDraft != null) {
            onCourtPointTap?.call(point);
          }
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
          if (closest != null) {
            onShotLocationTap?.call(closest.id);
          } else {
            onCourtPointTap?.call(pointFromLocal(local, size));
          }
        }

        return Semantics(
          container: true,
          label: mode == CourtViewMode.readOnly ? '复盘球场' : '篮球场落点编辑区',
          hint: mode == CourtViewMode.readOnly ? '查看已记录的投篮' : '点击球场记录或调整投篮落点',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => handleTap(details.localPosition),
            onPanUpdate: (details) => handlePosition(details.localPosition),
            child: CustomPaint(
              painter: CourtPainter(
                shotLocations: shotLocations,
                pendingLocation: pendingLocation,
                detailedShotDraft: detailedShotDraft,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}
