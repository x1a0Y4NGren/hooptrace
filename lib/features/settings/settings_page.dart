import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.controller,
    this.onOpenProject,
    this.onOpenRules,
    this.onDataRestored,
    super.key,
  });

  final SettingsController controller;
  final VoidCallback? onOpenProject;
  final VoidCallback? onOpenRules;
  final VoidCallback? onDataRestored;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      await widget.controller.load();
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final backup = controller.backupState;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: Column(
          children: [
            if (controller.busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const _SettingsSection(
                    title: '默认值',
                    children: [
                      _SettingTile(
                        icon: Icons.tune,
                        title: '默认计分规则',
                        subtitle: '当前沿用赛前设置',
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '比赛规则',
                    children: [
                      _SettingTile(
                        icon: Icons.tune,
                        title: '规则模板',
                        subtitle: '内置模板与自定义比赛规则',
                        onTap: widget.onOpenRules,
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    title: '外观',
                    children: [
                      _SettingTile(
                        icon: Icons.palette_outlined,
                        title: '主题',
                        subtitle: '跟随 HoopTrace 浅色主题',
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    title: '统计',
                    children: [
                      _SettingTile(
                        icon: Icons.query_stats,
                        title: '统计口径',
                        subtitle: '基于本地比赛事件计算',
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '备份与导出',
                    children: [
                      _SettingTile(
                        icon: Icons.archive_outlined,
                        title: '导出完整备份',
                        subtitle: '包含比赛、球员、规则、事件与设置的 JSON 文件',
                        enabled: !controller.busy,
                        onTap: () => _run(
                          controller.shareJsonBackup,
                          success: '已打开系统分享，可保存或发送备份文件',
                        ),
                      ),
                      _SettingTile(
                        icon: Icons.settings_backup_restore,
                        title: '从备份恢复',
                        subtitle: controller.canRestoreBackup
                            ? '校验通过后，原子替换这台设备上的全部本地数据'
                            : '请先结束正在进行的比赛',
                        enabled:
                            !controller.busy && controller.canRestoreBackup,
                        onTap: _confirmRestore,
                      ),
                      _SettingTile(
                        icon: Icons.table_view_outlined,
                        title: '导出 CSV',
                        subtitle: '比赛列表、事件列表与球员统计，共 3 个文件',
                        enabled: !controller.busy,
                        onTap: () => _run(
                          controller.shareCsvExports,
                          success: '已打开系统分享，可保存 3 个 CSV 文件',
                        ),
                      ),
                      SwitchListTile(
                        key: const Key('automatic-backup-switch'),
                        secondary: const Icon(Icons.backup_outlined),
                        title: const Text('自动备份'),
                        subtitle: Text(backup.enabled ? '已开启' : '已关闭'),
                        value: backup.enabled,
                        onChanged: controller.busy
                            ? null
                            : _setAutomaticBackupEnabled,
                      ),
                      _SettingTile(
                        icon: Icons.folder_outlined,
                        title: '备份位置',
                        subtitle:
                            backup.directoryLabel ??
                            backup.directory ??
                            '未选择，只会访问你明确选择的文件夹',
                        enabled: !controller.busy,
                        onTap: _configureDirectory,
                      ),
                      _SettingTile(
                        icon: Icons.backup,
                        title: '立即备份',
                        subtitle: _lastBackupLabel(backup),
                        enabled: !controller.busy && backup.isConfigured,
                        onTap: _runBackupNow,
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    title: '隐私',
                    children: [
                      _SettingTile(
                        icon: Icons.lock_outline,
                        title: '本地数据',
                        subtitle: '个人数据只保存在这台设备上，不会上传',
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    title: '实验功能',
                    children: [
                      _SettingTile(
                        icon: Icons.science_outlined,
                        title: '实验功能开关',
                        subtitle: '当前没有可用实验功能',
                        enabled: false,
                      ),
                    ],
                  ),
                  const _SettingsSection(
                    title: '开发诊断',
                    children: [
                      _SettingTile(
                        icon: Icons.monitor_heart_outlined,
                        title: '诊断信息',
                        subtitle: '当前没有诊断数据',
                        enabled: false,
                      ),
                    ],
                  ),
                  _SettingsSection(
                    title: '项目详情',
                    children: [
                      _SettingTile(
                        icon: Icons.info_outline,
                        title: '关于 HoopTrace',
                        subtitle: '永久开源免费、许可证与贡献方式',
                        onTap: widget.onOpenProject,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('恢复完整备份？'),
        content: const Text('导入文件通过版本、结构和校验和验证后，将一次性替换当前设备上的全部本地数据。此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('选择备份'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final restored = await widget.controller.restoreBackup();
      if (!mounted) return;
      if (!restored) {
        _showMessage('未选择备份文件');
        return;
      }
      _showMessage('备份恢复完成，自动备份位置已重置');
      widget.onDataRestored?.call();
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _configureDirectory() async {
    try {
      final selected = await widget.controller.configureBackupDirectory();
      if (!mounted) return;
      _showMessage(selected ? '自动备份位置已更新' : '未选择文件夹');
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _setAutomaticBackupEnabled(bool enabled) async {
    try {
      final changed = await widget.controller.setAutomaticBackupEnabled(
        enabled,
      );
      if (!mounted) return;
      if (!changed) {
        _showMessage('未选择文件夹，自动备份保持关闭');
      } else {
        _showMessage(enabled ? '自动备份已开启' : '自动备份已关闭');
      }
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _runBackupNow() async {
    try {
      await widget.controller.runBackupNow();
      if (mounted) _showMessage('本地备份已写入所选文件夹');
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      if (mounted) _showMessage(success);
    } on Object catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _lastBackupLabel(AutomaticBackupState state) {
    final value = state.lastBackupAt?.toLocal();
    if (value == null) return '尚未执行手动或自动备份';
    String two(int number) => number.toString().padLeft(2, '0');
    return '上次成功：${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  static String _friendlyError(Object error) {
    if (error is BackupChecksumException) {
      return '备份校验失败，文件可能已损坏或被修改';
    }
    if (error is UnsupportedBackupSchemaException) {
      return '该备份由更高版本创建，请升级 HoopTrace 后再试';
    }
    if (error is BackupFormatException ||
        error is BackupValidationException ||
        error is BackupRestoreException) {
      return '备份内容无效，现有数据未被修改';
    }
    if (error is BackupDirectoryNotConfiguredException) {
      return '请先选择自动备份文件夹';
    }
    if (error is BackupDirectoryUnavailableException) {
      return '所选文件夹当前不可写，请重新选择';
    }
    if (error is AutomaticBackupWriteException) {
      return '备份写入失败，请重新选择备份文件夹后再试';
    }
    if (error is BackupRestoreBlockedException) {
      return '请先结束正在进行的比赛';
    }
    return '操作失败，请稍后重试';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: enabled ? onTap : null,
    );
  }
}
