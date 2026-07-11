import 'package:flutter/material.dart';
import 'package:hooptrace/features/project/external_link_launcher.dart';

const hoopTraceRepositoryUrl = 'https://github.com/x1a0Y4NGren/hooptrace';
const hoopTraceLicenseUrl = '$hoopTraceRepositoryUrl/blob/main/LICENSE';
const hoopTraceContributingUrl =
    '$hoopTraceRepositoryUrl/blob/main/CONTRIBUTING.md';
const hoopTraceIssuesUrl = '$hoopTraceRepositoryUrl/issues';

class ProjectDetailsPage extends StatelessWidget {
  const ProjectDetailsPage({
    this.launcher = const ExternalLinkLauncher(),
    super.key,
  });

  final ExternalLinkLauncher launcher;

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launcher.open(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接，请稍后重试。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('项目详情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'HoopTrace',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('为一对一篮球而做的本地计分与复盘工具。'),
            const SizedBox(height: 24),
            const _PromiseTile(
              icon: Icons.all_inclusive,
              title: '永久免费',
              detail: '核心计分与复盘功能不会转为付费功能。',
            ),
            const _PromiseTile(
              icon: Icons.code,
              title: '永久开源',
              detail: '源代码持续公开，任何人都可以审阅与参与。',
            ),
            const _PromiseTile(
              icon: Icons.offline_bolt_outlined,
              title: '本地离线',
              detail: '无需账号或网络即可记录比赛。',
            ),
            const _PromiseTile(
              icon: Icons.shield_outlined,
              title: '不会上传个人数据',
              detail: '球员与比赛数据只保存在你的设备上。',
            ),
            const SizedBox(height: 24),
            Text(
              '开放项目',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _ProjectLink(
              icon: Icons.code,
              label: 'GitHub',
              onTap: () => _open(context, hoopTraceRepositoryUrl),
            ),
            _ProjectLink(
              icon: Icons.balance_outlined,
              label: 'License',
              onTap: () => _open(context, hoopTraceLicenseUrl),
            ),
            _ProjectLink(
              icon: Icons.handshake_outlined,
              label: '贡献指南',
              onTap: () => _open(context, hoopTraceContributingUrl),
            ),
            _ProjectLink(
              icon: Icons.bug_report_outlined,
              label: '问题反馈',
              onTap: () => _open(context, hoopTraceIssuesUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromiseTile extends StatelessWidget {
  const _PromiseTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectLink extends StatelessWidget {
  const _ProjectLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Tooltip(
        message: '在浏览器中打开',
        child: Icon(Icons.open_in_new),
      ),
      onTap: onTap,
    );
  }
}
