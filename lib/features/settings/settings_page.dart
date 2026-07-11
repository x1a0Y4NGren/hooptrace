import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({this.onOpenProject, super.key});

  final VoidCallback? onOpenProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
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
            const _SettingsSection(
              title: '备份与导出',
              children: [
                _SettingTile(
                  icon: Icons.ios_share_outlined,
                  title: '导出比赛数据',
                  subtitle: '后续提供',
                  enabled: false,
                ),
                _SettingTile(
                  icon: Icons.backup_outlined,
                  title: '本地备份',
                  subtitle: '后续提供',
                  enabled: false,
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
                  subtitle: '后续提供',
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
                  subtitle: '开源承诺、许可证与贡献方式',
                  onTap: onOpenProject,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
      subtitle: Text(subtitle),
      trailing: onTap == null
          ? null
          : const Tooltip(
              message: '打开项目详情',
              child: Icon(Icons.chevron_right),
            ),
      onTap: enabled ? onTap : null,
    );
  }
}
