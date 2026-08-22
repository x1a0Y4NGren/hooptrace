import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({
    required this.repository,
    required this.onCreate,
    required this.onEdit,
    super.key,
  });

  final PlayerRepository repository;
  final VoidCallback onCreate;
  final ValueChanged<Player> onEdit;

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  var _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('球员')),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onCreate,
        tooltip: '新建球员',
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Player>>(
          key: ValueKey(_streamKey),
          stream: widget.repository.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _PlayerLoadError(
                onRetry: () => setState(() => _streamKey++),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final players = snapshot.data!;
            if (players.isEmpty) {
              return _PlayerEmptyState(onCreate: widget.onCreate);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: players.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = players[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    minTileHeight: 64,
                    leading: CircleAvatar(
                      backgroundColor: _sideColor(player.preferredSide),
                      foregroundColor: Colors.white,
                      child: Text(player.nickname.characters.first),
                    ),
                    title: Text(player.nickname),
                    subtitle: Text(_playerSummary(player)),
                    trailing: const Tooltip(
                      message: '编辑球员',
                      child: Icon(Icons.chevron_right),
                    ),
                    onTap: () => widget.onEdit(player),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PlayerEmptyState extends StatelessWidget {
  const _PlayerEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              '还没有保存的球员',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('临时球员仍可直接参加比赛；保存档案后，下次更容易找到。'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('新建球员'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerLoadError extends StatelessWidget {
  const _PlayerLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('无法读取球员', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('本地球员数据暂时无法打开。'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _sideColor(TeamSide? side) => switch (side) {
      TeamSide.red => HoopTraceColors.red,
      TeamSide.blue => HoopTraceColors.blue,
      null => HoopTraceColors.orange,
    };

String _playerSummary(Player player) {
  final side = switch (player.preferredSide) {
    TeamSide.red => '偏好红方',
    TeamSide.blue => '偏好蓝方',
    null => '未设置偏好方',
  };
  final note = player.note?.trim();
  return note == null || note.isEmpty ? side : '$side · $note';
}
