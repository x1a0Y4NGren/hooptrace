import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_painter.dart';

export 'court_painter.dart' show TransientShotMarker;

enum CourtViewMode { readOnly, editable }

CourtPoint pointFromLocal(Offset local, Size size) {
  return HalfCourtGeometry.pointFromLocal(local, size);
}

class CourtView extends StatelessWidget {
  const CourtView({
    required this.shotLocations,
    this.pendingLocation,
    this.detailedShotDraft,
    this.locationPrompt,
    this.onPendingLocationChanged,
    this.onCourtPointTap,
    this.onShotLocationTap,
    this.geometryKey,
    this.hiddenShotLocationIds = const <String>{},
    this.transientMarkers = const <TransientShotMarker>[],
    this.mode = CourtViewMode.editable,
    super.key,
  });

  final List<ScoringShotLocation> shotLocations;
  final PendingShotLocation? pendingLocation;
  final DetailedShotDraft? detailedShotDraft;
  final String? locationPrompt;
  final ValueChanged<CourtPoint>? onPendingLocationChanged;
  final ValueChanged<CourtPoint>? onCourtPointTap;
  final ValueChanged<String>? onShotLocationTap;
  final GlobalKey? geometryKey;
  final Set<String> hiddenShotLocationIds;
  final List<TransientShotMarker> transientMarkers;
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
            // The unified score-first flow commits the supplement from the
            // tap itself. A drag still adjusts the draft marker through the
            // pan callback, while a discrete tap is an atomic attach.
            if (locationPrompt != null) {
              onCourtPointTap?.call(pointFromLocal(local, size));
            } else {
              handlePosition(local);
            }
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => handleTap(details.localPosition),
                onPanUpdate: (details) => handlePosition(details.localPosition),
                child: CustomPaint(
                  key: geometryKey,
                  painter: CourtPainter(
                    shotLocations: shotLocations,
                    pendingLocation: pendingLocation,
                    detailedShotDraft: detailedShotDraft,
                    hiddenShotLocationIds: hiddenShotLocationIds,
                    transientMarkers: transientMarkers,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              if (locationPrompt != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      liveRegion: true,
                      label: locationPrompt,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18),
                              const SizedBox(width: 6),
                              Flexible(child: Text(locationPrompt!)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
