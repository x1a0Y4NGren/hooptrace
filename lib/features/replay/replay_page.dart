import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/entities/possession_segment.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/core/export/replay_image_exporter.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/widgets/replay_analytics_summary.dart';
import 'package:hooptrace/features/replay/widgets/replay_audit_sheet.dart';
import 'package:hooptrace/features/replay/widgets/replay_event_editor.dart';
import 'package:hooptrace/features/replay/widgets/replay_timeline.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

class ReplayPage extends StatefulWidget {
  const ReplayPage({
    required this.controller,
    this.onExit,
    this.exitTooltip,
    this.onFinishMatch,
    this.onShareSummary,
    this.captureBoundary,
    super.key,
  });

  final ReplayController controller;
  final VoidCallback? onExit;
  final String? exitTooltip;
  final FutureOr<void> Function(int redScore, int blueScore)? onFinishMatch;
  final Future<void> Function(Uint8List bytes, String matchId)? onShareSummary;
  final Future<Uint8List> Function(GlobalKey boundaryKey)? captureBoundary;

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

enum _ReplayAppBarAction { edit, finish }

class _ReplayPageState extends State<ReplayPage> {
  bool _finishBusy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant ReplayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _showAuditHistory() async {
    final logs = await widget.controller.loadAuditLogs?.call();
    if (!mounted || logs == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ReplayAuditSheet(logs: logs),
    );
  }

  Future<void> _showEventEditor(ReplayEventData event) async {
    final controller = widget.controller;
    controller.selectEvent(event.id);
    if (!controller.isEditing) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          ReplayEventEditorSheet(controller: controller, event: event),
    );
  }

  Future<void> _showExportPreview() async {
    final onShareSummary = widget.onShareSummary;
    if (onShareSummary == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ReplayExportDialog(
        controller: widget.controller,
        captureBoundary: widget.captureBoundary ?? ReplayImageExporter.capture,
        onShare: onShareSummary,
      ),
    );
  }

  Future<void> _confirmFinishMatch() async {
    final finish = widget.onFinishMatch;
    if (_finishBusy || finish == null) return;
    final data = widget.controller.data;
    final l10n = _localizations(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmFinalScoreTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finalScoreLine(
                data.blueName,
                data.blueScore,
                data.redName,
                data.redScore,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.confirmFinalScoreBody),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('replay-finish-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            key: const Key('replay-finish-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.finishMatch),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _finishBusy = true);
    try {
      await Future<void>.sync(() => finish(data.redScore, data.blueScore));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.actionFailedRetry)));
      }
    } finally {
      if (mounted) setState(() => _finishBusy = false);
    }
  }

  AppLocalizations _localizations(BuildContext context) {
    return AppLocalizations.of(context) ?? AppLocalizationsZh();
  }

  List<Widget> _appBarActions(
    BuildContext context,
    ReplayController controller,
  ) {
    final l10n = _localizations(context);
    final compact =
        MediaQuery.sizeOf(context).width < 600 ||
        MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final actions = <Widget>[
      if (widget.onShareSummary != null)
        IconButton(
          key: const Key('replay-export-image'),
          tooltip: l10n.replayExportTooltip,
          onPressed: _showExportPreview,
          icon: const Icon(Icons.ios_share_outlined),
        ),
      if (controller.loadAuditLogs != null)
        IconButton(
          key: const Key('replay-audit-history'),
          tooltip: l10n.replayAuditTooltip,
          onPressed: _showAuditHistory,
          icon: const Icon(Icons.history),
        ),
    ];
    if (compact) {
      actions.add(
        PopupMenuButton<_ReplayAppBarAction>(
          key: const Key('replay-actions-menu'),
          tooltip: l10n.replayMoreActions,
          onSelected: (action) {
            switch (action) {
              case _ReplayAppBarAction.edit:
                if (controller.canEdit) {
                  controller.setEditing(!controller.isEditing);
                }
              case _ReplayAppBarAction.finish:
                if (!_finishBusy && widget.onFinishMatch != null) {
                  _confirmFinishMatch();
                }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _ReplayAppBarAction.edit,
              enabled: controller.canEdit,
              child: Text(
                controller.isEditing
                    ? l10n.replayEditMode
                    : l10n.replayReadOnly,
              ),
            ),
            if (widget.onFinishMatch != null)
              PopupMenuItem(
                value: _ReplayAppBarAction.finish,
                enabled: !_finishBusy,
                child: Text(l10n.finishMatch),
              ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      );
      return actions;
    }
    actions.add(
      SizedBox(
        height: 48,
        child: TextButton.icon(
          key: const Key('replay-edit-toggle'),
          onPressed: controller.canEdit
              ? () => controller.setEditing(!controller.isEditing)
              : null,
          icon: Icon(
            controller.isEditing ? Icons.lock_open : Icons.lock_outline,
          ),
          label: Text(
            controller.isEditing ? l10n.replayEditMode : l10n.replayReadOnly,
          ),
        ),
      ),
    );
    if (widget.onFinishMatch != null) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const Key('replay-finish-match'),
              onPressed: _finishBusy ? null : _confirmFinishMatch,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.finishMatch),
            ),
          ),
        ),
      );
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = _localizations(context);
    final page = Scaffold(
      appBar: AppBar(
        leading: widget.onExit == null
            ? null
            : IconButton(
                key: const Key('replay-exit'),
                tooltip: widget.exitTooltip ?? l10n.historyHomeTooltip,
                onPressed: widget.onExit,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(l10n.replayTitle),
        actions: _appBarActions(context, controller),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ScoreHeader(data: controller.data),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  if (constraints.maxWidth >= 840 || landscape) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _ReplayOverview(
                              controller: controller,
                              courtMaxHeight: math.max(
                                120,
                                constraints.maxHeight - 76,
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          flex: 4,
                          child: ReplayTimelinePanel(
                            controller: controller,
                            onEventTap: _showEventEditor,
                          ),
                        ),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReplayOverview(controller: controller),
                        const SizedBox(height: 24),
                        ReplayTimelinePanel(
                          controller: controller,
                          embedded: true,
                          onEventTap: _showEventEditor,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    final onExit = widget.onExit;
    if (onExit == null) return page;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onExit();
      },
      child: page,
    );
  }
}

class _ReplayExportDialog extends StatefulWidget {
  const _ReplayExportDialog({
    required this.controller,
    required this.captureBoundary,
    required this.onShare,
  });

  final ReplayController controller;
  final Future<Uint8List> Function(GlobalKey boundaryKey) captureBoundary;
  final Future<void> Function(Uint8List bytes, String matchId) onShare;

  @override
  State<_ReplayExportDialog> createState() => _ReplayExportDialogState();
}

class _ReplayExportDialogState extends State<_ReplayExportDialog> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final l10n = _localizations(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: math.min(980, viewport.width - 40),
        height: math.min(720, viewport.height - 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    color: HoopTraceColors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.replayExportTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.replayClose,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(l10n.replayExportDescription),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: _ReplayExportSummary(
                        controller: widget.controller,
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancelAction),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const Key('replay-export-confirm'),
                    onPressed: _busy ? null : _export,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_outlined),
                    label: Text(
                      _busy ? l10n.replayGenerating : l10n.replayGenerateShare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    final l10n = _localizations(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await widget.captureBoundary(_boundaryKey);
      await widget.onShare(bytes, widget.controller.data.matchId);
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l10n.replayExportFailed;
        });
      }
    }
  }
}

class _ReplayExportSummary extends StatelessWidget {
  const _ReplayExportSummary({required this.controller});

  final ReplayController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final l10n = _localizations(context);
    final analytics = data.analytics;
    final attempts = analytics == null
        ? controller.scoreEventCount
        : analytics.attempts;
    final shootingPercentage = analytics == null || attempts == 0
        ? l10n.replayNoData
        : analytics.hasReliableShootingPercentage
        ? '${(analytics.reliableShootingPercentage! * 100).round()}%'
        : '${l10n.replayAnalyticsRecordedAttempts} · $attempts';
    final largestLead = analytics?.largestLeadSide == null
        ? l10n.replayNoData
        : '${analytics!.largestLeadSide == TeamSide.red ? data.redName : data.blueName} '
              '+${analytics.largestLeadPoints}';

    return Container(
      key: const Key('replay-export-summary'),
      width: 900,
      height: 520,
      padding: const EdgeInsets.all(26),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_basketball,
                color: HoopTraceColors.orange,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'HoopTrace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${l10n.replayTitle} · '
                '${data.isFinished ? l10n.replayFinished : l10n.replayInProgress}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ExportTeamScore(
                  name: data.blueName,
                  score: data.blueScore,
                  color: teamColorForScheme(
                    TeamSide.blue,
                    Theme.of(context).colorScheme,
                  ),
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              Text(
                ':',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: _ExportTeamScore(
                  name: data.redName,
                  score: data.redScore,
                  color: teamColorForScheme(
                    TeamSide.red,
                    Theme.of(context).colorScheme,
                  ),
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 15 / 14,
                      child: CourtView(
                        shotLocations: controller.shotLocations,
                        pendingLocation: null,
                        mode: CourtViewMode.readOnly,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.replayExportAnalysis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.25,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _ExportMetric(
                              label: l10n.replayDuration,
                              value: _formatDuration(data.duration),
                            ),
                            _ExportMetric(
                              label: l10n.replayExportShotLocations,
                              value: '${controller.locatedShotCount}',
                            ),
                            _ExportMetric(
                              label: l10n.replayExportShootingPercentage,
                              value: shootingPercentage,
                            ),
                            _ExportMetric(
                              label: l10n.replayExportLeadChanges,
                              value: l10n.replayExportLeadChangesValue(
                                analytics?.leadChanges ?? 0,
                              ),
                            ),
                            _ExportMetric(
                              label: l10n.replayExportLargestLead,
                              value: largestLead,
                            ),
                            _ExportMetric(
                              label: l10n.replayExportKeyMoments,
                              value: l10n.replayExportKeyMomentsValue(
                                analytics?.keyPossessions.length ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTeamScore extends StatelessWidget {
  const _ExportTeamScore({
    required this.name,
    required this.score,
    required this.color,
    required this.alignment,
  });

  final String name;
  final int score;
  final Color color;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExportMetric extends StatelessWidget {
  const _ExportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.data});

  final ReplayMatchData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _TeamScore(
              name: data.blueName,
              score: data.blueScore,
              color: teamColorForScheme(
                TeamSide.blue,
                Theme.of(context).colorScheme,
              ),
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              data.isFinished ? l10n.replayFinished : l10n.replayInProgress,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
          Expanded(
            child: _TeamScore(
              name: data.redName,
              score: data.redScore,
              color: teamColorForScheme(
                TeamSide.red,
                Theme.of(context).colorScheme,
              ),
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.name,
    required this.score,
    required this.color,
    required this.alignment,
  });

  final String name;
  final int score;
  final Color color;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReplayOverview extends StatelessWidget {
  const _ReplayOverview({required this.controller, this.courtMaxHeight});

  final ReplayController controller;
  final double? courtMaxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final scoreCount = controller.scoreEventCount;
    final completeness = scoreCount == 0
        ? 0
        : (controller.locatedShotCount / scoreCount * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: l10n.replayCourt, icon: Icons.sports_basketball),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final naturalHeight = constraints.maxWidth * 14 / 15;
            final height = courtMaxHeight == null
                ? naturalHeight
                : math.min(naturalHeight, courtMaxHeight!);
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                key: const Key('replay-court-pane'),
                width: height * 15 / 14,
                height: height,
                child: CourtView(
                  shotLocations: controller.shotLocations,
                  pendingLocation: controller.pendingShotLocation,
                  highlightedShotLocationId: _selectedLocationId(controller),
                  onPendingLocationChanged: controller.isEditing
                      ? controller.updatePendingShotPoint
                      : null,
                  onShotLocationTap: controller.isEditing
                      ? controller.selectLocation
                      : null,
                  mode: controller.isEditing
                      ? CourtViewMode.editable
                      : CourtViewMode.readOnly,
                ),
              ),
            );
          },
        ),
        if (controller.pendingShotLocation != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const Key('replay-save-location'),
              onPressed: () => _saveLocation(context),
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.replaySaveLocation),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SectionTitle(
          title: l10n.replayOverview,
          icon: Icons.assessment_outlined,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Metric(
              label: l10n.replayDuration,
              value: _formatDuration(controller.data.duration),
            ),
            _Metric(label: l10n.replayScoringEvents, value: '$scoreCount'),
            _Metric(
              label: l10n.replayFouls,
              value: '${controller.foulEventCount}',
            ),
            _Metric(
              label: l10n.replayLocationCompleteness,
              value: '$completeness%',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PossessionSegmentsCard(data: controller.data),
        if (controller.data.analytics case final analytics?) ...[
          const SizedBox(height: 24),
          ReplayAnalyticsSummary(
            analytics: analytics,
            redName: controller.data.redName,
            blueName: controller.data.blueName,
          ),
        ],
      ],
    );
  }

  String? _selectedLocationId(ReplayController controller) {
    final selected = controller.selectedEvent;
    if (selected == null || selected.shotPoint == null) return null;
    return selected.locationId ?? 'replay-shot-${selected.id}';
  }

  Future<void> _saveLocation(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ShotLocationReasonDialog(),
    );
    if (reason != null) {
      await controller.saveSelectedShot(reason: reason);
    }
  }
}

class _ShotLocationReasonDialog extends StatefulWidget {
  const _ShotLocationReasonDialog();

  @override
  State<_ShotLocationReasonDialog> createState() =>
      _ShotLocationReasonDialogState();
}

class _ShotLocationReasonDialogState extends State<_ShotLocationReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return AlertDialog(
      title: Text(l10n.replayLocationEditTitle),
      content: TextField(
        controller: _reason,
        decoration: InputDecoration(
          labelText: l10n.replayEditorReason,
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: Text(l10n.replayLocationSaveAction),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108, minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PossessionSegmentsCard extends StatelessWidget {
  const _PossessionSegmentsCard({required this.data});

  final ReplayMatchData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Container(
      key: const Key('replay-possession-segments'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final boundary = Text(
                data.isFinished
                    ? l10n.replayFinishedBoundary
                    : l10n.replayInProgressBoundary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              );
              final compact =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(
                      title: l10n.replayPossession,
                      icon: Icons.swap_horiz_outlined,
                    ),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerLeft, child: boundary),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _SectionTitle(
                      title: l10n.replayPossession,
                      icon: Icons.swap_horiz_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: boundary),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          if (data.possessionSegments.isEmpty)
            Text(l10n.replayNoPossession)
          else
            ...data.possessionSegments.map(
              (segment) => _PossessionSegmentRow(
                data: segment,
                redName: data.redName,
                blueName: data.blueName,
              ),
            ),
        ],
      ),
    );
  }
}

class _PossessionSegmentRow extends StatelessWidget {
  const _PossessionSegmentRow({
    required this.data,
    required this.redName,
    required this.blueName,
  });

  final ReplayPossessionSegmentData data;
  final String redName;
  final String blueName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final sideColor = teamColorForScheme(
      data.side,
      Theme.of(context).colorScheme,
    );
    final sideName = data.side == TeamSide.red ? redName : blueName;
    final sourceLabel = data.source == PossessionSource.manual
        ? l10n.replayPossessionManual
        : l10n.replayPossessionSuggested;
    final reason = data.source == PossessionSource.suggested
        ? l10n.replaySuggestedReason
        : (data.reason == null || data.reason!.isEmpty
              ? l10n.replayNoReason
              : data.reason!);
    final boundary = data.isOpen
        ? l10n.replayPossessionCurrent
        : data.endedAt == null
        ? l10n.replayPossessionEnded(l10n.replayNoData)
        : l10n.replayPossessionEnded(_formatDuration(data.endedAt!));

    return Container(
      key: Key('replay-possession-${data.id}'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 42, color: sideColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sideName · $sourceLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_formatDuration(data.startedAt)} · $boundary',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  l10n.replayPossessionReason(reason),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: HoopTraceColors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

AppLocalizations _localizations(BuildContext context) {
  return AppLocalizations.of(context) ?? AppLocalizationsZh();
}
