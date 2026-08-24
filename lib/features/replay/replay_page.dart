import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/audit/audit_log_entry.dart';
import 'package:hooptrace/core/domain/entities/possession_segment.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/core/export/replay_image_exporter.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/widgets/replay_analytics_summary.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

class ReplayPage extends StatefulWidget {
  const ReplayPage({
    required this.controller,
    this.onFinishMatch,
    this.onShareSummary,
    this.captureBoundary,
    super.key,
  });

  final ReplayController controller;
  final FutureOr<void> Function(int redScore, int blueScore)? onFinishMatch;
  final Future<void> Function(Uint8List bytes, String matchId)? onShareSummary;
  final Future<Uint8List> Function(GlobalKey boundaryKey)? captureBoundary;

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

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
      builder: (context) => _AuditHistorySheet(logs: logs),
    );
  }

  Future<void> _showEventEditor(ReplayEventData event) async {
    final controller = widget.controller;
    if (!controller.isEditing) return;
    controller.selectEvent(event.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EventEditorSheet(controller: controller, event: event),
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('比赛复盘'),
        actions: [
          if (widget.onShareSummary != null)
            IconButton(
              key: const Key('replay-export-image'),
              tooltip: '导出复盘图',
              onPressed: _showExportPreview,
              icon: const Icon(Icons.ios_share_outlined),
            ),
          if (controller.loadAuditLogs != null)
            IconButton(
              key: const Key('replay-audit-history'),
              tooltip: '审计历史',
              onPressed: _showAuditHistory,
              icon: const Icon(Icons.history),
            ),
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
              label: Text(controller.isEditing ? '编辑模式' : '只读模式'),
            ),
          ),
          if (widget.onFinishMatch != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('replay-finish-match'),
                  onPressed: _finishBusy ? null : _confirmFinishMatch,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(_localizations(context).finishMatch),
                ),
              ),
            ),
        ],
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
                          child: _TimelinePanel(
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
                        _TimelinePanel(
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
                      '复盘分享图',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('落点与分析会生成一张本地图片'),
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
                    child: const Text('取消'),
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
                    label: Text(_busy ? '生成中' : '生成并分享'),
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
          _error = '图片生成或分享失败，请重试';
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
    final analytics = data.analytics;
    final attempts = analytics == null
        ? controller.scoreEventCount
        : analytics.madeShotCount + analytics.missedShotCount;
    final shootingPercentage = analytics == null || attempts == 0
        ? '暂无'
        : '${(analytics.shootingPercentage * 100).round()}%';
    final largestLead = analytics?.largestLeadSide == null
        ? '暂无'
        : '${analytics!.largestLeadSide == TeamSide.red ? data.redName : data.blueName} '
              '+${analytics.largestLeadPoints}';

    return Container(
      key: const Key('replay-export-summary'),
      width: 900,
      height: 520,
      padding: const EdgeInsets.all(26),
      color: HoopTraceColors.offWhite,
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
                  color: HoopTraceColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                data.isFinished ? '比赛复盘 · 终场' : '比赛复盘 · 进行中',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HoopTraceColors.ink.withValues(alpha: 0.68),
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
                  color: HoopTraceColors.blue,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              Text(
                ':',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: HoopTraceColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: _ExportTeamScore(
                  name: data.redName,
                  score: data.redScore,
                  color: HoopTraceColors.red,
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
                        '本场分析',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: HoopTraceColors.ink,
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
                              label: '比赛时长',
                              value: _formatDuration(data.duration),
                            ),
                            _ExportMetric(
                              label: '落点记录',
                              value: '${controller.locatedShotCount}',
                            ),
                            _ExportMetric(
                              label: '投篮命中率',
                              value: shootingPercentage,
                            ),
                            _ExportMetric(
                              label: '领先变化',
                              value: '${analytics?.leadChanges ?? 0} 次',
                            ),
                            _ExportMetric(label: '最大领先', value: largestLead),
                            _ExportMetric(
                              label: '关键节点',
                              value:
                                  '${analytics?.keyPossessions.length ?? 0} 次',
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
        color: HoopTraceColors.cream,
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

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({required this.controller, required this.event});

  final ReplayController controller;
  final ReplayEventData event;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _note;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.event.note ?? '');
    _reason = TextEditingController();
  }

  @override
  void dispose() {
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('编辑事件', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: '备注',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              labelText: '修改原因（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _deleteEvent,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('软删除'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存备注'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条事件？'),
        content: const Text('事件将被标记为已删除，并保留完整审计记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.deleteSelectedEvent(reason: _reason.text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveNote() async {
    await widget.controller.updateSelectedNote(
      _note.text,
      reason: _reason.text,
    );
    if (mounted) Navigator.pop(context);
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.data});

  final ReplayMatchData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _TeamScore(
              name: data.blueName,
              score: data.blueScore,
              color: HoopTraceColors.blue,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              data.isFinished ? '终场' : '进行中',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: HoopTraceColors.ink.withValues(alpha: 0.65),
              ),
            ),
          ),
          Expanded(
            child: _TeamScore(
              name: data.redName,
              score: data.redScore,
              color: HoopTraceColors.red,
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
    final scoreCount = controller.scoreEventCount;
    final completeness = scoreCount == 0
        ? 0
        : (controller.locatedShotCount / scoreCount * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: '落点图', icon: Icons.sports_basketball),
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
                width: height * 15 / 14,
                height: height,
                child: CourtView(
                  shotLocations: controller.shotLocations,
                  pendingLocation: controller.pendingShotLocation,
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
              label: const Text('保存落点位置'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const _SectionTitle(title: '总览', icon: Icons.assessment_outlined),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Metric(
              label: '时长',
              value: _formatDuration(controller.data.duration),
            ),
            _Metric(label: '得分事件', value: '$scoreCount'),
            _Metric(label: '犯规', value: '${controller.foulEventCount}'),
            _Metric(label: '落点完整度', value: '$completeness%'),
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
    return AlertDialog(
      title: const Text('保存落点修改'),
      content: TextField(
        controller: _reason,
        decoration: const InputDecoration(
          labelText: '修改原因（可选）',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: const Text('保存'),
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
        color: HoopTraceColors.cream,
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
    return Container(
      key: const Key('replay-possession-segments'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HoopTraceColors.cream,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: '球权分段',
                  icon: Icons.swap_horiz_outlined,
                ),
              ),
              Text(
                data.isFinished ? '终场边界' : '进行中边界',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (data.possessionSegments.isEmpty)
            const Text('暂无已记录的球权分段')
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
    final sideColor = data.side == TeamSide.red
        ? HoopTraceColors.red
        : HoopTraceColors.blue;
    final sideName = data.side == TeamSide.red ? redName : blueName;
    final sourceLabel = data.source == PossessionSource.manual ? '人工' : '建议';
    final reason = data.source == PossessionSource.suggested
        ? '命中后按规则建议'
        : (data.reason == null || data.reason!.isEmpty
              ? '未填写原因'
              : data.reason!);
    final boundary = data.isOpen
        ? '当前进行中'
        : data.endedAt == null
        ? '已结束'
        : '结束 ${_formatDuration(data.endedAt!)}';

    return Container(
      key: Key('replay-possession-${data.id}'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HoopTraceColors.ink.withValues(alpha: 0.12),
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
                  '${_formatDuration(data.startedAt)} 开始 · $boundary',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '原因：$reason',
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

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.controller,
    required this.onEventTap,
    this.embedded = false,
  });

  final ReplayController controller;
  final bool embedded;
  final ValueChanged<ReplayEventData> onEventTap;

  @override
  Widget build(BuildContext context) {
    Widget buildContent({required bool inlineEvents}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: inlineEvents ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const _SectionTitle(title: '事件时间线', icon: Icons.timeline),
          const SizedBox(height: 10),
          _ReplayFilters(controller: controller),
          const SizedBox(height: 12),
          if (controller.visibleEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('没有符合筛选条件的事件')),
            )
          else if (inlineEvents)
            ...controller.visibleEvents.map(
              (event) => _TimelineEvent(
                event: event,
                data: controller.data,
                onTap: controller.isEditing ? () => onEventTap(event) : null,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: controller.visibleEvents.length,
                itemBuilder: (context, index) => _TimelineEvent(
                  event: controller.visibleEvents[index],
                  data: controller.data,
                  onTap: controller.isEditing
                      ? () => onEventTap(controller.visibleEvents[index])
                      : null,
                ),
              ),
            ),
        ],
      );
    }

    if (embedded) return buildContent(inlineEvents: true);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 280;
          final content = buildContent(inlineEvents: compactHeight);
          return compactHeight
              ? SingleChildScrollView(child: content)
              : content;
        },
      ),
    );
  }
}

class _ReplayFilters extends StatelessWidget {
  const _ReplayFilters({required this.controller});

  final ReplayController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(
              key: const Key('replay-kind-all'),
              label: '全部',
              selected: controller.kindFilter == ReplayKindFilter.all,
              onSelected: () => controller.setKindFilter(ReplayKindFilter.all),
            ),
            _FilterChip(
              key: const Key('replay-kind-scores'),
              label: '得分',
              selected: controller.kindFilter == ReplayKindFilter.scores,
              onSelected: () =>
                  controller.setKindFilter(ReplayKindFilter.scores),
            ),
            _FilterChip(
              key: const Key('replay-kind-fouls'),
              label: '犯规',
              selected: controller.kindFilter == ReplayKindFilter.fouls,
              onSelected: () =>
                  controller.setKindFilter(ReplayKindFilter.fouls),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            _FilterChip(
              label: '双方',
              selected: controller.sideFilter == ReplaySideFilter.all,
              onSelected: () => controller.setSideFilter(ReplaySideFilter.all),
            ),
            _FilterChip(
              label: '红方',
              selected: controller.sideFilter == ReplaySideFilter.red,
              selectedColor: HoopTraceColors.red.withValues(alpha: 0.18),
              onSelected: () => controller.setSideFilter(ReplaySideFilter.red),
            ),
            _FilterChip(
              label: '蓝方',
              selected: controller.sideFilter == ReplaySideFilter.blue,
              selectedColor: HoopTraceColors.blue.withValues(alpha: 0.18),
              onSelected: () => controller.setSideFilter(ReplaySideFilter.blue),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: selectedColor,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.event, required this.data, this.onTap});

  final ReplayEventData event;
  final ReplayMatchData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sideColor = event.side == TeamSide.red
        ? HoopTraceColors.red
        : event.side == TeamSide.blue
        ? HoopTraceColors.blue
        : HoopTraceColors.ink;
    final sideName = event.side == TeamSide.red
        ? data.redName
        : event.side == TeamSide.blue
        ? data.blueName
        : '比赛';
    final action = switch (event.kind) {
      ReplayEventKind.score => '+${event.points} 分',
      ReplayEventKind.foul => '犯规',
      ReplayEventKind.miss => '投篮未中',
      ReplayEventKind.other => '记录',
    };
    return InkWell(
      key: Key('replay-event-${event.id}'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: HoopTraceColors.ink.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                _formatDuration(event.elapsed),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Container(width: 4, height: 32, color: sideColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sideName · $action',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.note != null && event.note!.isNotEmpty)
                    Text(
                      event.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.edit_outlined, size: 20),
              )
            else if (event.shotPoint != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.location_on_outlined, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditHistorySheet extends StatelessWidget {
  const _AuditHistorySheet({required this.logs});

  final List<AuditLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: math.min(MediaQuery.sizeOf(context).height * 0.75, 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '审计历史',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('暂无编辑记录'))
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          minTileHeight: 64,
                          leading: Icon(
                            log.action == AuditAction.delete
                                ? Icons.delete_outline
                                : Icons.edit_outlined,
                          ),
                          title: Text('${log.action.name} · ${log.targetId}'),
                          subtitle: Text(
                            log.reason == null ? '未填写原因' : '原因：${log.reason}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
