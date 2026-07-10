import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/features/history/history_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    required this.controller,
    required this.onMatchTap,
    this.onHome,
    super.key,
  });

  final HistoryController controller;
  final ValueChanged<String> onMatchTap;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最近比赛'),
        actions: [
          if (onHome != null)
            IconButton(
              onPressed: onHome,
              tooltip: '返回主页',
              icon: const Icon(Icons.home_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: controller.matches.isEmpty
            ? const _EmptyHistory()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 12,
                    ),
                    itemCount: controller.matches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final match = controller.matches[index];
                      return _HistoryMatchRow(
                        match: match,
                        wide: wide,
                        onTap: () => onMatchTap(match.matchId),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 48,
              color: HoopTraceColors.orange.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 14),
            Text('暂无比赛记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '完成一场比赛后，记录会显示在这里。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HoopTraceColors.ink.withValues(alpha: 0.65),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMatchRow extends StatelessWidget {
  const _HistoryMatchRow({
    required this.match,
    required this.wide,
    required this.onTap,
  });

  final HistoryMatchSummary match;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('history-match-${match.matchId}'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: wide ? 88 : 142),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: wide ? _wideContent(context) : _narrowContent(context),
        ),
      ),
    );
  }

  Widget _wideContent(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 128, child: _date(context)),
        Expanded(flex: 4, child: _teamsAndScore(context)),
        Expanded(flex: 2, child: _winner(context)),
        Expanded(flex: 2, child: _Meta(label: '规则', value: match.ruleName)),
        SizedBox(
          width: 78,
          child: _Meta(label: '时长', value: _formatDuration(match.duration)),
        ),
        SizedBox(width: 88, child: _completeness(context)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  Widget _narrowContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _date(context)),
            const Icon(Icons.chevron_right),
          ],
        ),
        const SizedBox(height: 8),
        _teamsAndScore(context),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _winner(context),
            _Meta(label: '规则', value: match.ruleName),
            _Meta(label: '时长', value: _formatDuration(match.duration)),
            _completeness(context),
          ],
        ),
      ],
    );
  }

  Widget _date(BuildContext context) {
    return Text(
      _formatDate(match.playedAt),
      maxLines: 1,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: HoopTraceColors.ink.withValues(alpha: 0.68),
          ),
    );
  }

  Widget _teamsAndScore(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            match.redName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HoopTraceColors.red,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${match.redScore} : ${match.blueScore}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Expanded(
          child: Text(
            match.blueName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HoopTraceColors.blue,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  Widget _winner(BuildContext context) {
    return _Meta(
      label: '结果',
      value: match.winnerName == null ? '平局' : '胜者：${match.winnerName}',
    );
  }

  Widget _completeness(BuildContext context) {
    return _Meta(
      label: '落点完整度',
      value: '${(match.locationCompleteness * 100).round()}%',
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: HoopTraceColors.ink.withValues(alpha: 0.58),
              ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day  $hour:$minute';
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
