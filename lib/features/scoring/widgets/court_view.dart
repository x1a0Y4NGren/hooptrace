import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
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
        final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
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
          onTap: mode == CourtViewMode.editable
              ? () => handleTap(size.center(Offset.zero))
              : null,
          onTapHint: mode == CourtViewMode.editable ? l10n.courtEditHint : null,
          label: mode == CourtViewMode.readOnly
              ? l10n.courtReplayLabel
              : l10n.courtEditLabel,
          hint: mode == CourtViewMode.readOnly
              ? l10n.courtReplayHint
              : l10n.courtEditHint,
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
