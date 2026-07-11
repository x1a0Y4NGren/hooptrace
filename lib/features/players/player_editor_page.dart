import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:uuid/uuid.dart';

class PlayerEditorPage extends StatefulWidget {
  PlayerEditorPage({
    required this.repository,
    required this.onSaved,
    this.playerId,
    this.onDeleted,
    String Function()? idFactory,
    DateTime Function()? now,
    super.key,
  })  : idFactory = idFactory ?? const Uuid().v4,
        now = now ?? DateTime.now;

  final PlayerRepository repository;
  final String? playerId;
  final VoidCallback onSaved;
  final VoidCallback? onDeleted;
  final String Function() idFactory;
  final DateTime Function() now;

  @override
  State<PlayerEditorPage> createState() => _PlayerEditorPageState();
}

class _PlayerEditorPageState extends State<PlayerEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _noteController = TextEditingController();
  Player? _existing;
  TeamSide? _preferredSide;
  bool _loading = false;
  bool _saving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.playerId != null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant PlayerEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerId == widget.playerId &&
        oldWidget.repository == widget.repository) {
      return;
    }
    _existing = null;
    _preferredSide = null;
    _nicknameController.clear();
    _noteController.clear();
    _loadError = null;
    _loading = false;
    _saving = false;
    if (widget.playerId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final player = await widget.repository.getById(widget.playerId!);
      if (player == null) {
        throw StateError('Player not found');
      }
      if (!mounted) return;
      _existing = player;
      _nicknameController.text = player.nickname;
      _noteController.text = player.note ?? '';
      setState(() {
        _preferredSide = player.preferredSide;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final note = _noteController.text.trim();
    final player = Player(
      id: _existing?.id ?? widget.idFactory(),
      nickname: _nicknameController.text.trim(),
      createdAt: _existing?.createdAt ?? widget.now(),
      preferredSide: _preferredSide,
      note: note.isEmpty ? null : note,
    );
    try {
      await widget.repository.save(player);
      if (mounted) widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试。')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除球员？'),
        content: const Text('只会删除此球员档案，不会删除已有比赛记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || _existing == null) return;
    try {
      await widget.repository.delete(_existing!.id);
      if (mounted) widget.onDeleted?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除失败，请重试。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playerId == null ? '新建球员' : '编辑球员'),
        actions: [
          if (_existing != null && widget.onDeleted != null)
            IconButton(
              onPressed: _saving ? null : _delete,
              tooltip: '删除球员',
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            onPressed: _loading || _loadError != null || _saving ? null : _save,
            tooltip: '保存球员',
            icon: _saving
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('无法打开球员档案'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextFormField(
            key: const Key('player-nickname'),
            controller: _nicknameController,
            autofocus: widget.playerId == null,
            textInputAction: TextInputAction.next,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '请输入球员昵称' : null,
          ),
          const SizedBox(height: 16),
          Text('偏好方', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<TeamSide?>(
            segments: const [
              ButtonSegment(value: null, label: Text('不限')),
              ButtonSegment(
                value: TeamSide.red,
                label: Text('红方'),
                icon: Icon(Icons.circle, color: HoopTraceColors.red),
              ),
              ButtonSegment(
                value: TeamSide.blue,
                label: Text('蓝方'),
                icon: Icon(Icons.circle, color: HoopTraceColors.blue),
              ),
            ],
            selected: {_preferredSide},
            onSelectionChanged: (selection) {
              setState(() => _preferredSide = selection.single);
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('player-note'),
            controller: _noteController,
            minLines: 3,
            maxLines: 5,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '打法、习惯或需要记住的信息',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? '保存中' : '保存球员'),
          ),
        ],
      ),
    );
  }
}
