import 'package:flutter/material.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class ScoreSidePanel extends StatelessWidget {
  const ScoreSidePanel({
    required this.side,
    required this.name,
    this.teamLabel,
    required this.score,
    required this.fouls,
    required this.onScore,
    required this.onFoul,
    this.scoreButtons = const [1, 2, 3],
    this.onMiss,
    this.scoreEnabled = true,
    this.missEnabled = false,
    this.foulEnabled = true,
    this.locationPoints,
    this.locationRemainingSeconds,
    this.locationRevealDuration = Duration.zero,
    this.reduceMotion = false,
    this.scoreButtonKeys,
    this.foulStamp = false,
    this.foulStampVersion = 0,
    super.key,
  });

  final TeamSide side;
  final String name;
  final String? teamLabel;
  final int score;
  final int fouls;
  final ValueChanged<int> onScore;
  final VoidCallback onFoul;
  final List<int> scoreButtons;
  final VoidCallback? onMiss;
  final bool scoreEnabled;
  final bool missEnabled;
  final bool foulEnabled;
  final int? locationPoints;
  final int? locationRemainingSeconds;
  final Duration locationRevealDuration;
  final bool reduceMotion;

  /// Optional geometry handles for the live scoring overlay. Public semantic
  /// ValueKeys remain on the actual buttons and are never replaced.
  final Map<int, GlobalKey>? scoreButtonKeys;
  final bool foulStamp;
  final int foulStampVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final disabledColor = editorialThemeOf(context).mutedInk;
    final color = teamColorForScheme(
      side,
      Theme.of(context).colorScheme,
      background: HoopTraceColors.ink,
    );

    return Material(
      key: Key('${side.name}-action-rail'),
      color: HoopTraceColors.ink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          const buttonHeight = 48.0;
          final scoreHeight = compact ? 40.0 : 88.0;
          final gap = compact ? 4.0 : 8.0;

          if (compact) {
            final availableWidth = (constraints.maxWidth - 8).clamp(
              48.0,
              double.infinity,
            );
            final actionWidth = availableWidth;
            final actions = <Widget>[
              for (final points in scoreButtons)
                _ScoreAction(
                  side: side,
                  teamLabel: teamLabel ?? name,
                  points: points,
                  width: actionWidth,
                  height: buttonHeight,
                  color: color,
                  compact: true,
                  enabled: scoreEnabled,
                  locationActive: locationPoints == points,
                  locationRemainingSeconds: locationPoints == points
                      ? locationRemainingSeconds
                      : null,
                  locationRevealDuration: locationRevealDuration,
                  reduceMotion: reduceMotion,
                  geometryKey: scoreButtonKeys?[points],
                  onPressed: () => onScore(points),
                ),
              SizedBox(
                width: actionWidth,
                height: buttonHeight,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: foulEnabled ? 1 : 0.48,
                        child: OutlinedButton(
                          key: Key('${side.name}-foul'),
                          onPressed: foulEnabled ? onFoul : null,
                          style: _editorialRailButtonStyle(
                            color,
                            disabledColor: disabledColor,
                            height: buttonHeight,
                            padding: EdgeInsets.zero,
                          ),
                          child: _CompactActionLabel(l10n.scoringFoul),
                        ),
                      ),
                    ),
                    if (foulStamp)
                      _FoulStamp(
                        key: ValueKey('foul-stamp-$foulStampVersion'),
                        reduceMotion: reduceMotion,
                      ),
                  ],
                ),
              ),
              if (missEnabled && onMiss != null)
                SizedBox(
                  width: actionWidth,
                  height: buttonHeight,
                  child: OutlinedButton(
                    key: Key('${side.name}-miss'),
                    onPressed: onMiss,
                    style: _editorialRailButtonStyle(
                      color,
                      disabledColor: disabledColor,
                      height: buttonHeight,
                      padding: EdgeInsets.zero,
                    ),
                    child: _CompactActionLabel(l10n.scoringMissed),
                  ),
                ),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 68,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$score',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: HoopTraceColors.offWhite,
                                    fontFamily:
                                        HoopTraceTypography.displayFamily,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${l10n.scoringFoul} $fouls',
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: HoopTraceColors.offWhite,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, actionConstraints) {
                        final requiredHeight =
                            actions.length * buttonHeight +
                            (actions.length - 1) * 4;
                        if (actionConstraints.maxHeight >= requiredHeight) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: actions,
                          );
                        }
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < actions.length;
                                index++
                              ) ...[
                                actions[index],
                                if (index < actions.length - 1)
                                  const SizedBox(height: 4),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: compact ? 6 : 8,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 12 : 16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: scoreHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$score',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: HoopTraceColors.offWhite,
                                    fontFamily:
                                        HoopTraceTypography.displayFamily,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                        Text(
                          '${l10n.scoringFoul} $fouls',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: HoopTraceColors.offWhite),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final points in scoreButtons) ...[
                          _ScoreAction(
                            side: side,
                            teamLabel: teamLabel ?? name,
                            points: points,
                            width: double.infinity,
                            height: buttonHeight,
                            color: color,
                            compact: false,
                            enabled: scoreEnabled,
                            locationActive: locationPoints == points,
                            locationRemainingSeconds: locationPoints == points
                                ? locationRemainingSeconds
                                : null,
                            locationRevealDuration: locationRevealDuration,
                            reduceMotion: reduceMotion,
                            geometryKey: scoreButtonKeys?[points],
                            onPressed: () => onScore(points),
                          ),
                          SizedBox(height: gap),
                        ],
                        if (missEnabled && onMiss != null) ...[
                          SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton.icon(
                              key: Key('${side.name}-miss'),
                              onPressed: onMiss,
                              style: _editorialRailButtonStyle(
                                color,
                                disabledColor: disabledColor,
                                height: buttonHeight,
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(l10n.scoringMissed),
                            ),
                          ),
                          SizedBox(height: gap),
                        ],
                        SizedBox(
                          height: buttonHeight,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: foulEnabled ? 1 : 0.48,
                                  child: OutlinedButton.icon(
                                    key: Key('${side.name}-foul'),
                                    onPressed: foulEnabled ? onFoul : null,
                                    style: _editorialRailButtonStyle(
                                      color,
                                      disabledColor: disabledColor,
                                      height: buttonHeight,
                                    ),
                                    icon: const Icon(
                                      Icons.flag_outlined,
                                      size: 18,
                                    ),
                                    label: Text(l10n.scoringFoul),
                                  ),
                                ),
                              ),
                              if (foulStamp)
                                _FoulStamp(
                                  key: ValueKey('foul-stamp-$foulStampVersion'),
                                  reduceMotion: reduceMotion,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreAction extends StatefulWidget {
  const _ScoreAction({
    required this.side,
    required this.teamLabel,
    required this.points,
    required this.width,
    required this.height,
    required this.color,
    required this.compact,
    required this.enabled,
    required this.locationActive,
    required this.locationRemainingSeconds,
    required this.locationRevealDuration,
    required this.reduceMotion,
    this.geometryKey,
    required this.onPressed,
  });

  final TeamSide side;
  final String teamLabel;
  final int points;
  final double width;
  final double height;
  final Color color;
  final bool compact;
  final bool enabled;
  final bool locationActive;
  final int? locationRemainingSeconds;
  final Duration locationRevealDuration;
  final bool reduceMotion;
  final GlobalKey? geometryKey;
  final VoidCallback onPressed;

  @override
  State<_ScoreAction> createState() => _ScoreActionState();
}

class _ScoreActionState extends State<_ScoreAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final team = widget.teamLabel;
    final remaining = widget.locationRemainingSeconds;
    final disabledColor = editorialThemeOf(context).mutedInk;
    final semantic = widget.locationActive && remaining != null
        ? l10n.scoringLocationPendingSemantics(widget.points, remaining, team)
        : l10n.scoringScoreSemantics(widget.points, team);
    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('+${widget.points}'),
        if (widget.locationActive) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.location_on_outlined,
            key: Key('${widget.side.name}-score-${widget.points}-location'),
            size: 17,
          ),
          if (remaining != null) Text('$remaining'),
        ],
      ],
    );
    final button = SizedBox(
      key: widget.geometryKey,
      width: widget.width,
      height: widget.height,
      child: Semantics(
        label: semantic,
        button: true,
        enabled: widget.enabled,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.48,
          child: FilledButton(
            key: Key('${widget.side.name}-score-${widget.points}'),
            style: _editorialRailButtonStyle(
              widget.color,
              disabledColor: disabledColor,
              height: widget.height,
              padding: widget.compact ? EdgeInsets.zero : null,
              emphasizedBorder: widget.locationActive,
            ),
            onPressed: widget.enabled ? widget.onPressed : null,
            child: FittedBox(fit: BoxFit.scaleDown, child: label),
          ),
        ),
      ),
    );
    final feedback = Listener(
      onPointerDown: widget.enabled && !widget.reduceMotion
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: widget.enabled && !widget.reduceMotion
          ? (_) => setState(() => _pressed = false)
          : null,
      onPointerCancel: widget.enabled && !widget.reduceMotion
          ? (_) => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration:
            Theme.of(context).extension<HoopTraceMotionTheme>()?.press ??
            const Duration(milliseconds: 90),
        child: button,
      ),
    );
    if (!widget.locationActive) return feedback;
    return AnimatedContainer(
      key: Key(
        '${widget.side.name}-score-${widget.points}-location-affordance',
      ),
      duration: widget.locationRevealDuration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.locationActive
              ? widget.color.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: feedback,
    );
  }
}

ButtonStyle _editorialRailButtonStyle(
  Color color, {
  required Color disabledColor,
  required double height,
  EdgeInsetsGeometry? padding,
  bool emphasizedBorder = false,
}) {
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(48, height)),
    padding: WidgetStatePropertyAll(
      padding ?? const EdgeInsets.symmetric(horizontal: 8),
    ),
    elevation: const WidgetStatePropertyAll(0),
    backgroundColor: const WidgetStatePropertyAll(HoopTraceColors.ink),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? disabledColor : color,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.disabled) ? disabledColor : color,
        width: emphasizedBorder ? 3 : 1.5,
      ),
    ),
    shape: const WidgetStatePropertyAll(
      BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
    ),
  );
}

class _CompactActionLabel extends StatelessWidget {
  const _CompactActionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
  }
}

class _FoulStamp extends StatelessWidget {
  const _FoulStamp({required this.reduceMotion, super.key});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final editorial = editorialThemeOf(context);
    final stamp = DecoratedBox(
      key: const Key('scoring-foul-stamp'),
      decoration: BoxDecoration(
        color: editorial.arenaAccent,
        border: Border.all(color: editorial.ink, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          l10n.scoringFoul,
          style: TextStyle(
            color: const Color(0xFF101112),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
    if (reduceMotion) return IgnorePointer(child: stamp);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        duration:
            Theme.of(context).extension<HoopTraceMotionTheme>()?.foulStamp ??
            Duration.zero,
        tween: Tween(begin: 0.65, end: 1),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment: Alignment.topRight,
          child: child,
        ),
        child: stamp,
      ),
    );
  }
}
