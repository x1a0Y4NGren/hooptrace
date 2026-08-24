import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
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
        SnackBar(
          content: Text(
            (AppLocalizations.of(context) ?? AppLocalizationsZh())
                .routeProjectLinkError,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'HoopTrace',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(l10n.projectTagline),
            const SizedBox(height: 24),
            _PromiseTile(
              icon: Icons.all_inclusive,
              title: l10n.projectFreeForever,
              detail: l10n.projectFreeForeverDetail,
            ),
            _PromiseTile(
              icon: Icons.code,
              title: l10n.projectOpenSource,
              detail: l10n.projectOpenSourceDetail,
            ),
            _PromiseTile(
              icon: Icons.offline_bolt_outlined,
              title: l10n.projectOffline,
              detail: l10n.projectOfflineDetail,
            ),
            _PromiseTile(
              icon: Icons.shield_outlined,
              title: l10n.projectPrivacy,
              detail: l10n.projectPrivacyDetail,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.projectOpen,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _ProjectLink(
              icon: Icons.code,
              label: l10n.projectGitHub,
              onTap: () => _open(context, hoopTraceRepositoryUrl),
            ),
            _ProjectLink(
              icon: Icons.balance_outlined,
              label: l10n.projectLicense,
              onTap: () => _open(context, hoopTraceLicenseUrl),
            ),
            _ProjectLink(
              icon: Icons.handshake_outlined,
              label: l10n.projectContribute,
              onTap: () => _open(context, hoopTraceContributingUrl),
            ),
            _ProjectLink(
              icon: Icons.bug_report_outlined,
              label: l10n.projectIssue,
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
      trailing: Tooltip(
        message: (AppLocalizations.of(context) ?? AppLocalizationsZh())
            .projectOpenBrowser,
        child: Icon(Icons.open_in_new),
      ),
      onTap: onTap,
    );
  }
}
